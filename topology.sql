/*
  Topology build functions.
*/

/*

  Identifies dangles nodes.
  Returns the points.

  TODO: use the temp table library.

*/
create or replace function public.gs__dangle_nodes(
  _lines geometry[]
) returns setof geometry as
$$
declare
  _g geometry;
  _p geometry[];
begin
  create temp table point(p geometry) on commit drop;

  foreach _g in array _lines loop
    insert into point select st_startpoint(_g);
    insert into point select st_endpoint(_g);
  end loop;

  return query
    select * from point group by p having count(p)=1;
end;
$$
language plpgsql;

/*

  Identifies dangle nodes.
  Returns a table.

  TODO: use the temp table library.

*/
create or replace function public.gs__dangle_nodes_table(
  _lines geometry[]
) returns table (id bigint, point geometry) as
$$
declare
  _g geometry;
  _p geometry[];
begin
  create temp table point(p geometry) on commit drop;

  foreach _g in array _lines loop
    insert into point select st_startpoint(_g);
    insert into point select st_endpoint(_g);
  end loop;

  return query 
    select
      row_number() over (order by p) as id,
      p as geom
    from point
    group by p
    having count(p)=1
  ;
end;
$$
language plpgsql;


/*

  Takes a set of points and a closed LINESTRING and returns the splits.

  Trash this, replace with niw gs__splitlinestring

*/
create or replace function public.gs__splitclosedlinestring(
  _points geometry[],
  _line geometry,
  _tolerance float
) returns geometry[] as
$$
declare
  _p geometry;
  _lines geometry[]=array[]::geometry[];
  _c boolean=true;
  _i integer;
  _a geometry;
  _b geometry;
  _l1 geometry;
  _l2 geometry;
  _srid integer;
begin
  _srid = st_srid(_points[1]);

	-- Delete all points that doesn't fall within tolerance
	for _i in 1..array_length(_points, 1) loop
	  if st_distance(_points[_i], _line)>_tolerance then
		  _points = gs__pull_from_array(_points, _i);
		end if;
	end loop;

  -- Sort points by distance to the start node
  _i = 1;
  while _c loop
    _c = false;
    while _i<(array_length(_points, 1)) loop
      if st_line_locate_point(_line, _points[_i])>st_line_locate_point(_line, _points[_i+1]) then
        _a = _points[_i];
	_b = _points[_i+1];
	_points[_i] = _b;
	_points[_i+1] = _a;
	_c = true;
      end if;
      _i = _i+1;
    end loop;
    _i = 1;
  end loop;

  -- Cut the line with the string of points
  _i = 1;
  while _i<(array_length(_points, 1)) loop
    _lines = _lines || st_setsrid(st_line_substring(_line, st_line_locate_point(_line, _points[_i]),
                                         st_line_locate_point(_line,_points[_i+1])), _srid);
    _i = _i+1;
  end loop;

  -- Cut from start to first and from last to end, and join them  
  _l1 = st_setsrid(st_line_substring(_line, 0, st_line_locate_point(_line, _points[1])), _srid);
  _l2 = st_setsrid(st_line_substring(_line, st_line_locate_point(_line,
           _points[array_length(_points,1)]), 1), _srid);
  _lines = _lines || st_union(_l1, _l2);

  return _lines;
end;
$$
language plpgsql;


/*

  This is a function by Sandro Santilli. Check his blog because I
  think this is already gone mainstream in PostGIS 2.

*/

CREATE OR REPLACE FUNCTION SimplifyEdgeGeom(atopo varchar, anedge int, maxtolerance float8)
RETURNS float8 AS $$
DECLARE
  tol float8;
  sql varchar;
BEGIN
  tol := maxtolerance;
  LOOP
    sql := 'SELECT topology.ST_ChangeEdgeGeom(' || quote_literal(atopo) || ', ' || anedge
      || ', ST_Simplify(geom, ' || tol || ')) FROM '
      || quote_ident(atopo) || '.edge WHERE edge_id = ' || anedge;
    BEGIN
      RAISE DEBUG 'Running %', sql;
      EXECUTE sql;
      RETURN tol;
    EXCEPTION
     WHEN OTHERS THEN
      RAISE WARNING 'Simplification of edge % with tolerance % failed: %', anedge, tol, SQLERRM;
      tol := round( (tol/2.0) * 1e8 ) / 1e8; -- round to get to zero quicker
      IF tol = 0 THEN RAISE EXCEPTION '%', SQLERRM; END IF;
    END;
  END LOOP;
END
$$ LANGUAGE 'plpgsql' STABLE STRICT;
