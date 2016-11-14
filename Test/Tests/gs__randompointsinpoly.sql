/*

  This example creates a fictional point for each inhabitant age class with a random age
  for each polygon in the import.poblacion table.

*/

create schema trash;

create table trash.pobladores(
  edad integer,
  geom geometry(POINT, 4326)
);



insert into trash.pobladores
select
  (0+random()*(15-0))::integer,
  gs__randompointsinpoly(geom, pob_0_15::integer)
from
  import.poblacion;

insert into trash.pobladores
select
  (16+random()*(30-16))::integer,
  gs__randompointsinpoly(geom, pob_16_30::integer)
from
  import.poblacion;

insert into trash.pobladores
select
  (31+random()*(50-31))::integer,
  gs__randompointsinpoly(geom, pob_31_50::integer)
from
  import.poblacion;

insert into trash.pobladores
select
  (51+random()*(80-51))::integer,
  gs__randompointsinpoly(geom, pob_51_80::integer)
from
  import.poblacion;

insert into trash.pobladores
select
  (80+random()*(99-80))::integer,
  gs__randompointsinpoly(geom, pob_mayor_::integer)
from
  import.poblacion;



create schema data;

create table data.pobladores as
select
  row_number() over () as gid,
  edad,
  geom
from
  trash.pobladores;


drop table trash.pobladores;
