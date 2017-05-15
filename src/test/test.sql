-- If geometry is multi, check number of geometries with:

select distinct 
    st_numgeometries(geom)
from data.network;

-- Any results beside a simple 1 requires st_dump:

select distinct
    st_isvalid(geom)
from data.network;

-- select *
-- from data.network;
-- where st_issimple(geom);
