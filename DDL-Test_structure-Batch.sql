/*

  Generates a test table schema for PostGIS tests.

*/
\set dschema test_postgis
\set epsg_code 4326
\set dimensions 2

begin;

create schema :dschema;

create table :dschema.test_point(
  id_test_point serial,
  alpha_integer integer,
  alpha_float float,
  alpha_varchar varchar(50)
);

select addgeometrycolumn(:'dschema', 'test_point', 'geom', :epsg_code, 'POINT', :dimensions);
create index test_point_geom_gist on :dschema.test_point
using gist(geom);

create table :dschema.test_multipoint(
  id_test_multipoint serial,
  alpha_integer integer,
  alpha_float float,
  alpha_varchar varchar(50)
);

select addgeometrycolumn(:'dschema', 'test_multipoint', 'geom', :epsg_code, 'MULTIPOINT', :dimensions);
create index test_multipoint_geom_gist on :dschema.test_multipoint
using gist(geom);

create table :dschema.test_linestring(
  id_test_linestring serial,
  alpha_integer integer,
  alpha_float float,
  alpha_varchar varchar(50)
);

select addgeometrycolumn(:'dschema', 'test_linestring', 'geom', :epsg_code, 'LINESTRING', :dimensions);
create index test_linestring_geom_gist on :dschema.test_linestring
using gist(geom);

create table :dschema.test_multilinestring(
  id_test_multilinestring serial,
  alpha_integer integer,
  alpha_float float,
  alpha_varchar varchar(50)
);

select addgeometrycolumn(:'dschema', 'test_multilinestring', 'geom', :epsg_code, 'MULTILINESTRING', :dimensions);
create index test_multilinestring_geom_gist on :dschema.test_multilinestring
using gist(geom);

create table :dschema.test_polygon(
  id_test_polygon serial,
  alpha_integer integer,
  alpha_float float,
  alpha_varchar varchar(50)
);

select addgeometrycolumn(:'dschema', 'test_polygon', 'geom', :epsg_code, 'POLYGON', :dimensions);
create index test_polygon_geom_gist on :dschema.test_polygon
using gist(geom);

create table :dschema.test_multipolygon(
  id_test_multipolygon serial,
  alpha_integer integer,
  alpha_float float,
  alpha_varchar varchar(50)
);

select addgeometrycolumn(:'dschema', 'test_multipolygon', 'geom', :epsg_code, 'MULTIPOLYGON', :dimensions);
create index test_multipolygon_geom_gist on :dschema.test_multipolygon
using gist(geom);

commit;
