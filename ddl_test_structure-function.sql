/*

  Creates a geometry test data structure.

*/
create or replace function public.gs__create_test_data_structure(
  _schema varchar(50),
  _srid integer
) returns void as
$$
declare
  _sql text;
begin

  _sql = 'drop schema if exists "' || _schema || '" cascade;
       	  create schema "' || _schema || '";';

  execute _sql;

  _sql = 'create table "' || _schema || '".test_point(
            gid serial,
	    alpha01 integer,
	    alpha02 float,
	    alpha03 varchar(100));

	  select addgeometrycolumn(''' || _schema || ''', ''test_point'', ''geom'', ' || 
	  	 		   _srid || ', ''POINT'', 2);
 
          create index test_point_gist on "' || _schema || '".test_point using gist(geom);';

  execute _sql;

  _sql = 'create table "' || _schema || '".test_multipoint(
            gid serial,
	    alpha01 integer,
	    alpha02 float,
	    alpha03 varchar(100));

	  select addgeometrycolumn(''' || _schema || ''', ''test_multipoint'', ''geom'', ' || 
	  	 		   _srid || ', ''MULTIPOINT'', 2);
 
          create index test_multipoint_gist on "' || _schema || '".test_multipoint using gist(geom);';

  execute _sql;

  _sql = 'create table "' || _schema || '".test_linestring(
            gid serial,
	    alpha01 integer,
	    alpha02 float,
	    alpha03 varchar(100));

	  select addgeometrycolumn(''' || _schema || ''', ''test_linestring'', ''geom'', ' || 
	  	 		   _srid || ', ''LINESTRING'', 2);
 
          create index test_linestring_gist on "' || _schema || '".test_linestring using gist(geom);';

  execute _sql;

  _sql = 'create table "' || _schema || '".test_multilinestring(
            gid serial,
	    alpha01 integer,
	    alpha02 float,
	    alpha03 varchar(100));

	  select addgeometrycolumn(''' || _schema || ''', ''test_multilinestring'', ''geom'', ' || 
	  	 		   _srid || ', ''MULTILINESTRING'', 2);
 
          create index test_multilinestring_gist on "' || _schema || '".test_multilinestring using gist(geom);';

  execute _sql;

  _sql = 'create table "' || _schema || '".test_polygon(
            gid serial,
	    alpha01 integer,
	    alpha02 float,
	    alpha03 varchar(100));

	  select addgeometrycolumn(''' || _schema || ''', ''test_polygon'', ''geom'', ' || 
	  	 		   _srid || ', ''POLYGON'', 2);
 
          create index test_polygon_gist on "' || _schema || '".test_polygon using gist(geom);';

  execute _sql;

  _sql = 'create table "' || _schema || '".test_multipolygon(
            gid serial,
	    alpha01 integer,
	    alpha02 float,
	    alpha03 varchar(100));

	  select addgeometrycolumn(''' || _schema || ''', ''test_multipolygon'', ''geom'', ' || 
	  	 		   _srid || ', ''MULTIPOLYGON'', 2);
 
          create index test_multipolygon_gist on "' || _schema || '".test_multipolygon using gist(geom);';

  execute _sql;

end;
$$
language plpgsql;
