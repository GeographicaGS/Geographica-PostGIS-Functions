/*

  Database introspection niceties.

*/

begin;

/*

  Type for column information.

*/
drop type if exists gs__column cascade;

create type gs__column as(
  name varchar(250),
  type varchar(50),
  varcharlength integer,
  numericprecision integer,
  numericprecisionradix integer,
  numericscale integer,
  geomsrid varchar(50),
  geomgeometrytype varchar(50),
  geombbox geometry
);

/*

  Type for schema.table.column syntax.

*/
drop type if exists gs__oname cascade;

create type gs__oname as(
  oschema varchar(250),
  otable varchar(250),
  ocolumn varchar(250)
);

/*

  Gets a gs__o_name from a schema.table.column string.

*/
drop function if exists public.gs__oname(varchar);

create or replace function public.gs__oname(
  _name varchar(2000)
) returns gs__oname as
$$
  select (split_part($1, '.', 1),
          split_part($1, '.', 2),
          split_part($1, '.', 3))::gs__oname;
$$
language sql;

/*

  Simply gets a gs__oname and returns it as a string.

*/
drop function if exists public.gs__onamestring(gs__oname);

create or replace function public.gs__onamestring(
  _gs__oname gs__oname
) returns varchar as
$$
declare
  _t varchar;
begin
  _t = '';

  if _gs__oname.oschema<>'' and
     (_gs__oname.otable='' or _gs__oname.otable is null) and
     (_gs__oname.ocolumn='' or _gs__oname.ocolumn is null)
  then
    _t = _gs__oname.oschema;
  end if;

  if (_gs__oname.oschema='' or _gs__oname.oschema is null) and
     _gs__oname.otable<>'' and
     (_gs__oname.ocolumn='' or _gs__oname.ocolumn is null)
  then
    _t = _gs__oname.otable;
  end if;

  if _gs__oname.oschema<>'' and
     _gs__oname.otable<>'' and
     (_gs__oname.ocolumn='' or _gs__oname.ocolumn is null)
  then
    _t = _gs__oname.oschema || '.' || _gs__oname.otable;
  end if;

  if (_gs__oname.oschema='' or _gs__oname.oschema is null) and
     (_gs__oname.otable='' or _gs__oname.otable is null) and
     _gs__oname.ocolumn<>''
  then
    _t = _gs__oname.ocolumn;
  end if;

  if _gs__oname.oschema<>'' and
     (_gs__oname.otable='' or _gs__oname.otable is null) and
     _gs__oname.ocolumn<>''
  then
    _t = null;
  end if;

  if (_gs__oname.oschema='' or _gs__oname.oschema is null) and
     _gs__oname.otable<>'' and
     _gs__oname.ocolumn<>''
  then
    _t = _gs__oname.otable || '.' || _gs__oname.ocolumn;
  end if;

  if _gs__oname.oschema<>'' and
     _gs__oname.otable<>'' and
     _gs__oname.ocolumn<>''
  then
    _t = _gs__oname.oschema || '.' || _gs__oname.otable || '.' || _gs__oname.ocolumn;
  end if;

  return _t;
end;
$$
language plpgsql;

/*

  Returns info about a column in PostGIS 2.

  _column: column in schema.table.column varchar form
  _bbox: boolean to compute or not geometry bbox 

*/
create or replace function public.gs__getcolumninfo(
  _column varchar(2000),
  _bbox boolean
) returns gs__column as
$$
declare
  _informationschema record;
  _sql text;
  _o gs__oname;
  _out gs__column;
  _srid varchar(40);
  _geometrytype varchar(100);
  _geombbox geometry;
  _nrow integer;
begin 
  _o = gs__oname(_column); 

  -- Get information in information_schema.columns.
  execute 'select 
             udt_name, 
             character_maximum_length,
	     numeric_precision,
	     numeric_precision_radix,
	     numeric_scale
           from information_schema.columns
           where table_schema=$1 and
                 table_name=$2 and
                 column_name=$3;'
  using _o.oschema, _o.otable, _o.ocolumn
  into _informationschema;

  -- No column in information_schema.columns
  if _informationschema.udt_name is null and 
     _informationschema.character_maximum_length is null
  then
    return null;
  end if;

  -- Get info in case of geometry
  if _informationschema.udt_name='geometry' then
    -- Check SRID uniformity
    _sql = 'select distinct st_srid(' || _o.ocolumn || ')::varchar as srid
            from ' || _o.oschema || '.' || _o.otable || ';';

    execute _sql into _srid;
    get diagnostics _nrow = ROW_COUNT;

    if _nrow>1 then
      _srid = 'ERR_Mixed';
    end if;

    -- Check geometrytype uniformity
    _sql = 'select distinct st_geometrytype(' || _o.ocolumn || ') as srid
            from ' || _o.oschema || '.' || _o.otable || ';';

    execute _sql into _geometrytype;
    get diagnostics _nrow = ROW_COUNT;

    if _nrow>1 then
      _geometrytype = 'ERR_Mixed';
    end if;

    -- Get bounding box
    if _srid<>'ERR_Mixed' and _bbox then
      _sql = 'with c as(
                select st_collect(' || _o.ocolumn || ') as geom
                from ' || _o.oschema || '.' || _o.otable || '
              )
              select
                st_setsrid(st_envelope(geom),' || _srid::integer || ') as geom
              from c;';
      
      execute _sql into _geombbox;
      else
        _geombbox = null;
    end if;
  end if;

  _out = (_o.ocolumn, 
          _informationschema.udt_name, 
          _informationschema.character_maximum_length,
	  _informationschema.numeric_precision,
	  _informationschema.numeric_precision_radix,
	  _informationschema.numeric_scale,
          _srid, _geometrytype, _geombbox)::gs__column;

  return _out;
end;
$$
language plpgsql;

/*

  Returns info about a column, overload with a gs__oname argument.

*/
create or replace function public.gs__getcolumninfo(
  _oname gs__oname,
  _bbox boolean
) returns gs__column as
$$
declare
  _s text;
  _out gs__column;
begin 
  _s = _oname.oschema || '.' || _oname.otable || '.' || _oname.ocolumn;
  _out = gs__getcolumninfo(_s, _bbox);
  
  return _out;
end;
$$
language plpgsql;

/*

  Returns info about a column, overload with a three varchars as arguments.

*/
create or replace function public.gs__getcolumninfo(
  _oschema varchar(250),
  _otable varchar(250),
  _ocolumn varchar(250),
  _bbox boolean
) returns gs__column as
$$
declare
  _s text;
  _out gs__column;
begin 
  _s = _oschema || '.' || _otable || '.' || _ocolumn;
  _out = gs__getcolumninfo(_s, _bbox);
  
  return _out;
end;
$$
language plpgsql;

/*

  Returns the set of columns in a table.

*/
create or replace function public.gs__gettablecolumns(
  _table varchar(250),
  _bbox boolean
) returns gs__column[] as
$$
declare
  _oname gs__oname;
  _sql text;
  _r record;
  _out gs__column[];
begin
  _out = array[]::gs__column[];
  _oname = gs__oname(_table);

  _sql = 'select column_name
          from information_schema.columns
          where
            table_schema=$1 and
            table_name=$2
          order by ordinal_position';

  for _r in execute _sql using _oname.oschema, _oname.otable loop
    _out = _out ||
           gs__getcolumninfo((_oname.oschema, _oname.otable, _r.column_name)::gs__oname, _bbox);
  end loop;

  return _out;
end;
$$
language plpgsql;

/*

  Returns all tables in a schema.

  Takes the schema name as varchar and the table type to be returned
  also as a varchar. Types can be:

    - BASE: base tables
    - VIEW: views

  On any other value all tables will be returned.
*/
create or replace function public.gs__getschematables(
  _schema varchar(250),
  _type varchar(4)
) returns setof varchar as
$$
  select
    table_name::varchar
  from
    information_schema.tables
  where
    table_schema=_schema and 
    table_type like
    case
      when _type='BASE' then 'BASE TABLE'
      when _type='VIEW' then 'VIEW'
      else '%'
    end;
$$
language sql;

commit;
