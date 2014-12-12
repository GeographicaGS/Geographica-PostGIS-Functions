create schema test_data;

create table test_data.test(
  id_sigwx_polygon integer,
  id_work integer, 
  properties text,
  geom geometry
);

\copy test_data.test from sigwx.csv with delimiter '|' csv header quote '"'
