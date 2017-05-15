#!/bin/bash

# Creates a psql session in the container

docker run -ti --rm -v `pwd`/src/:/src/ --link postgis_lib_test:pg geographica/postgis:eclectic_equidna /bin/bash -c "PGPASSWORD='postgres' psql -h pg -p 5432 -U postgres postgres -f /src/test/data/network.sql >> /src/out-command"