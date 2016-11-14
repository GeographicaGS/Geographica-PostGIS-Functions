#!/bin/bash

# Execute from Docker

PGCLIENTENCODING=UTF-8 ogr2ogr -f "PostgreSQL" PG:"host=postgis \
user=postgres dbname=test password=postgres port=5432" \
-a_srs "EPSG:4326" -lco SCHEMA=import -lco OVERWRITE=YES \
-nln poblacion -lco GEOMETRY_NAME=geom -nlt MULTIPOLYGON \
Data/Poblacion/poblacion.shp
