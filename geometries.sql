/*

  Geometry accessor and constructors.

*/

/*

  Creates a polygonal rectangle from two points: lower left and upper
  right corners

*/
create or replace function public.gs__rectangle(
  _point_a geometry,
  _point_b geometry
) returns geometry as
$$
declare
  _point_ll geometry;
  _point_lr geometry;
  _point_ul geometry;
  _point_ur geometry;
  _minx double precision;
  _maxx double precision;
  _miny double precision;
  _maxy double precision;
begin
  _minx = gs__array_min(array[st_x(_point_a), st_x(_point_b)]::numeric[]);
  _maxx = gs__array_max(array[st_x(_point_a), st_x(_point_b)]::numeric[]);
  _miny = gs__array_min(array[st_y(_point_a), st_y(_point_b)]::numeric[]);
  _maxy = gs__array_max(array[st_y(_point_a), st_y(_point_b)]::numeric[]);

  _point_ll = st_makepoint(_minx, _miny);
  _point_lr = st_makepoint(_maxx, _miny);
  _point_ul = st_makepoint(_minx, _maxy);
  _point_ur = st_makepoint(_maxx, _maxy);

  return 
    st_makepolygon(
      st_makeline(array[
        _point_ll,
        _point_lr,
        _point_ur,
        _point_ul,
        _point_ll
    ]));
end;
$$
language plpgsql;

/*

  Same as above, but gets a [minx,miny,maxx,maxy] parameter.

*/
create or replace function public.gs__rectangle(
  _array float[]
) returns geometry as
$$
declare
  _point_ll geometry;
  _point_lr geometry;
  _point_ul geometry;
  _point_ur geometry;
begin
	_point_ll = st_makepoint(_array[1], _array[2]);
  _point_lr = st_makepoint(_array[3], _array[2]);
  _point_ul = st_makepoint(_array[1], _array[4]);
  _point_ur = st_makepoint(_array[3], _array[4]);

  return st_makepolygon(
    st_makeline(array[
      _point_ll,
			_point_lr,
			_point_ur,
			_point_ul,
			_point_ll
	]));
end;
$$
language plpgsql;

/*

  Returns a [minx,miny,maxx,maxy] for a set of geometries passed as a
  geometry array.

*/
create or replace function public.gs__geomboundaries(
  _geom geometry[]
) returns float[] as
$$
declare
  _g geometry;
  _minx float;
  _miny float;
  _maxx float;
  _maxy float;
begin
  _minx = st_xmin(_geom[1]);
  _miny = st_ymin(_geom[1]);
	_maxx = st_xmax(_geom[1]);
	_maxy = st_ymax(_geom[1]);

	foreach _g in array _geom loop
    if st_xmin(_g)<_minx then
		  _minx = st_xmin(_g);
		end if;

    if st_ymin(_g)<_miny then
		  _miny = st_ymin(_g);
		end if;

    if st_xmax(_g)>_maxx then
		  _maxx = st_xmax(_g);
		end if;

    if st_ymax(_g)>_maxy then
		  _maxy = st_ymax(_g);
		end if;
  end loop;

  return array[_minx,_miny,_maxx,_maxy]::float[];
end;
$$
language plpgsql;

/*

  Returns a [minx,miny,maxx,maxy] for a geometry.

*/
create or replace function public.gs__geomboundaries(
  _geom geometry
) returns float[] as
$$
declare
  _g geometry;
  _minx float;
  _miny float;
  _maxx float;
  _maxy float;
begin
  _minx = st_xmin(_geom);
  _miny = st_ymin(_geom);
	_maxx = st_xmax(_geom);
	_maxy = st_ymax(_geom);

  return array[_minx,_miny,_maxx,_maxy]::float[];
end;
$$
language plpgsql;


/*

  Returns a polygonal grid that covers a geometry at a regular step.

*/
create or replace function public.gs__grid(
  _geom geometry,
  _size float
) returns setof geometry as
$$
declare
  _bounds float[];
  _width float;
  _height float;
  _cols integer;
  _rows integer;
  _x float;
  _y float;
  _c integer;
  _r integer;
  _g geometry;
begin
  _bounds = gs__geom_boundaries(_geom);
  _cols = ((_bounds[3]-_bounds[1])/_size)::integer;
  _rows = ((_bounds[4]-_bounds[2])/_size)::integer;

  if (_bounds[3]-_bounds[1])::numeric%_size::numeric<>0 then
    _cols = _cols+1;
  end if;

  if (_bounds[4]-_bounds[2])::numeric%_size::numeric<>0 then
    _rows = _rows+1;
  end if;

  _width = _cols*_size;
  _height = _rows*_size;

  _x = _bounds[1]-((_width-(_bounds[3]-_bounds[1]))/2);
  _y = _bounds[2]-((_height-(_bounds[4]-_bounds[2]))/2);

  for _c in 0.._cols-1 loop
    for _r in 0.._rows-1 loop
      _g = gs__rectangle(array[_x+(_c*_size), _y+(_r*_size), 
                                 _x+(_c*_size)+_size, _y+(_r*_size)+_size]::float[]);
      return next _g;
    end loop;
  end loop;
end;
$$
language plpgsql;

/*

  This function returns human readable lat / lon output out of a geometry.
  First parameter is the coordinate, the second, a varchar of just 'x' or 'y'.

*/
create or replace function public.gs__degreeminsec(
  _coord float,
  _xy char(1)
) returns varchar as
$$
declare
  _suffix char(1);
  _grads integer;
  _min float;
  _secs float;
  _res varchar;
begin
  if _xy='x' then
    if _coord>=0 then
      _suffix = 'E';
    else
      _suffix = 'W';
    end if;
  end if;
  
  if _xy='y' then
    if _coord>=0 then
      _suffix = 'N';
    else
      _suffix = 'S';
    end if;
  end if;
  
  _grads = floor(abs(_coord));
  _min = (abs(_coord) - _grads)*60;
  _secs = (abs(_min) - floor(abs(_min)))*60;
  _res = _grads || '°' || floor(_min) || '''' || round(_secs::numeric, 2) || '''''' || _suffix || ' ';
  	
  return _res;
end;
$$
language plpgsql;
