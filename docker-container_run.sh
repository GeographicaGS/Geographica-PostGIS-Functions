#!/bin/bash

# Runs a new container for testing

docker run -d -p 9400:5432 --name postgis_lib_test -v `pwd`/src/:/src/ geographica/postgis:eclectic_equidna
