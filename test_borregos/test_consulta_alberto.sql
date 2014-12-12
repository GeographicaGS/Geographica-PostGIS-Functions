SELECT id_sigwx_polygon AS id,
st_curvetoline(gs__cloudy_geom(st_boundary(geom), 0.3, 0.3, 1)) AS geom
FROM test_data.test
WHERE id_work = 1 AND st_isvalid(geom)
LIMIT 10;
