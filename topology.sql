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
