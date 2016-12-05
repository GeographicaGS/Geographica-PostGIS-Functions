/* 

  Pulls an element by index from a matrix and return the rest 

*/
create or replace function public.gs__pullfromarray(
  _a anyarray,
  _p integer
) returns anyarray as
$$
begin
  return _a[1:_p-1] || _a[_p+1:array_upper(_a, 1)];
end;
$$
language plpgsql;



-- This function segmentizes a LineString and returns its segments

create or replace function public.gs__segmentize(
  _geom geometry
) returns setof geometry as
$$
declare
  _sql text;
  _r record;
begin
  _sql = format(
    'select distinct (st_dump(st_intersection(''%s''::geometry, ''%s''::geometry))).geom as geom;',
    _geom, _geom);

  for _r in execute _sql loop
    return next _r.geom;
  end loop;
  
end;
$$
language plpgsql;



-- This function splits a segment by the projection of a point on it

create or replace function public.gs__splitbypoint(
  _line geometry,
  _point geometry
) returns setof geometry as
$$
declare
  _pos double precision; 
begin

  _pos = st_linelocatepoint(_line, _point);

  return next st_linesubstring(_line, 0, _pos);
  return next st_linesubstring(_line, _pos, 1);

end;
$$
language plpgsql;



-- Splits a linestring by a group of points

create or replace function public.gs__splitbypoints(
  _line geometry,
  _points geometry[]
) returns setof geometry as
$$
declare
  _lines geometry[];
  _p geometry;
  _i integer;
  _r record;
  _sql varchar;
begin

  _lines = array[_line]::geometry[];

  -- For each point...
  foreach _p in array _points loop
    _i = 1;
    
    -- Iterate until find the only line that will be split
    while _i<=array_length(_lines,1) loop

      -- Get splits
      _sql = format(
        'select 
           array_agg(gs__splitbypoint) as g,
	   array_agg(st_geometrytype(gs__splitbypoint)) as t
         from 
           gs__splitbypoint(''%s''::geometry, ''%s''::geometry);',
        _lines[_i], _p);

      -- If results of splits are both linestrings, erase parent line
      -- and add the two new ones
      for _r in execute _sql loop
	 if _r.t::varchar='{ST_LineString,ST_LineString}' then
	   _lines = gs__pullfromarray(_lines, _i);
	   _lines = _lines || _r.g;
	 end if;
      end loop;

      _i = _i+1;

    end loop;
  end loop;

  -- Final delivery
  foreach _p in array _lines loop
    return next _p;
  end loop;

end;
$$
language plpgsql;





create or replace function gs__cleannetwork(
  _tablename varchar,
  _geomcolumn varchar,
  _tolerance double precision,
  _srid integer
) returns setof geometry as
$$
declare
  _sql varchar;
  _i integer;
  _a integer;
  _g geometry[];
  _r record;
begin

  _sql = format('
    create temp table segments as
    select distinct gs__segmentize(st_transform(%I, %s)) as geom from %I;',
    _geomcolumn, _srid, _tablename);

  execute _sql;

  create temp table cutpoints as
  select distinct
    st_intersection(a.geom, b.geom) as geom
  from
    segments a inner join
    segments b on
    st_intersects(a.geom, b.geom) and
    not st_equals(a.geom, b.geom);

--  create temp table splits as
  create table test.splits as
  with a as (
  select
    gs__splitbypoints(a.geom, array_agg(b.geom)) as geom
  from
    segments a inner join
    cutpoints b on
    st_dwithin(a.geom, b.geom, _tolerance)
  group by a.geom)
  select
    geom,
    st_asewkt(geom)
  from a;

  create table test.nodes as
  with nodes as (
    select 
      st_intersection(a.geom, b.geom) as geom
    from
      test.splits a inner join
      test.splits b on
      st_intersects(a.geom, b.geom) and
      not st_equals(a.geom, b.geom))
  select
    geom,
    count(geom)
  from
    nodes
  group by geom;

  create table test.re as
  select
    b.geom as geom--,
    -- count(b.geom) as cardinality
  from
    test.splits a inner join
    test.nodes b on
    st_intersects(a.geom, b.geom);
--  group by b.geom;


  -- for _r in select * from splits loop
  --   return next _r.geom;
  -- end loop;

end;
$$
language plpgsql;
