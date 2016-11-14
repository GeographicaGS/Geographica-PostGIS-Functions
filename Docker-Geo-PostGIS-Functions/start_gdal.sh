#!/bin/bash

docker run -ti --rm --volumes-from dockergeopostgisfunctions_postgis_1 -w="/src/" --link dockergeopostgisfunctions_postgis_1:postgis geographica/gdal2:2.1.1 /bin/bash
