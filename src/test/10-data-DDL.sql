-- Data schema

begin;

create schema data;

-- Simplified version of road network for Sevilla province

create table data.network(
    gid bigint,
    arc_class varchar(30),
    arc_type varchar(10),
    arc_name varchar(70),
    geom geometry(MULTILINESTRING, 4258));

alter table data.network
add constraint network_pkey
primary key(gid);

create index network_geom_gist
on data.network
using gist(geom);

commit;

\copy data.network from data/network.csv with delimiter '|' csv header encoding 'UTF8' null '-'