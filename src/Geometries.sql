/*

  Geometry accessor and constructors.

*/

begin;

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
      _point_ll]));
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

  Combines two bbox as [minx, miny, maxx, maxy].

*/
create or replace function public.gs__combinebbox(
  _bbox1 float[],
  _bbox2 float[]
) returns float[] as
$$
declare
  _bbox float[4];
begin
  -- _bbox[1] = least(_bbox1[1], _bbox2[1]);
  -- _bbox[2] = least(_bbox1[2], _bbox2[2]);
  -- _bbox[3] = greatest(_bbox1[3], _bbox2[3]);
  -- _bbox[4] = greatest(_bbox1[4], _bbox2[4]);

  _bbox = array[least(_bbox1[1], _bbox2[1]), least(_bbox1[2], _bbox2[2]),
  	        greatest(_bbox1[3], _bbox2[3]), greatest(_bbox1[4], _bbox2[4])]::float[];

  return _bbox;
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

/*

   This function for iCOM constructs "clouds" ridges along polygon's
   boundaries or linestrings.

   It only accepts ST_LineString geometry types.

   Use examples:

    select
      row_number() over (order by gid) as gid,
      st_curvetoline(gs__cloudy_geom((st_dump(geom)).geom, 0.05, 0.025, 1)) as geom  
    from
      curves.line;

    with lines as(
    select
      (st_dump(st_boundary(geom))).geom as geom
    from
      curves.poly)
    select
      row_number() over (order by geom) as gid,
      st_curvetoline((gs__cloudy_geom(geom, 0.1, 0.1, -1))) as geom
    from
      lines;

*/
create or replace function public.gs__cloudy_geom(
  _geom geometry,
  _cloud_length float,
  _cloud_height float,
  _side integer            -- 1 left / -1 right
) returns geometry as
$$
declare
  _ewkt text;
  _p0 geometry;
  _p1 geometry;
  _p2 geometry;
  _line geometry;
  _curvature_point geometry;
  _length float;
  _narcs integer;             -- number of arcs in segment
  _interpolationpercent float;
  _i0 float;
  _i1 float;
  _i2 float;
  _defectlength float;
  _excesslength float;
  _finalcloudlength float;
  _finalcloudheight float;
begin
  _ewkt = 'SRID=4326;COMPOUNDCURVE(';

  if st_geometrytype(_geom) not in ('ST_LineString') then
    return null;
  end if;

  <<nextsegment>>
  for _i in 1..st_npoints(_geom)-1 loop
    _p0 = st_pointn(_geom, _i);
    _p1 = st_pointn(_geom, _i+1);
    _line = st_makeline(_p0, _p1);
    _length = st_length(_line);
    _narcs = floor((_length/_cloud_length));

    if _narcs=0 then
      _narcs = 1;
      _finalcloudlength=_length;
      _finalcloudheight=_cloud_height*_length/_cloud_length;
      _interpolationpercent = 1;
    else
      -- Final length of arcs
      _defectlength = _length-(_narcs*_cloud_length);
      _excesslength = ((_narcs+1)*_cloud_length)-_length;
  
      if _defectlength<_excesslength then
         _finalcloudlength = _cloud_length+(_defectlength/_narcs);
         _narcs = _narcs;
      else
  	_finalcloudlength = _cloud_length-(_excesslength/(_narcs+1));
  	_narcs = _narcs+1;
      end if;
  
      _interpolationpercent = _finalcloudlength/_length;
      _finalcloudheight = _cloud_height;
    end if;

    -- Segmentize
    for _t in 0.._narcs-1 loop
      _i0 = _interpolationpercent*_t;
      _i1 = (_interpolationpercent*_t)+(_interpolationpercent/2);
      _i2 = _interpolationpercent*(_t+1);

      if _i2>1 then _i2=1; end if;

      _p0 = st_lineinterpolatepoint(_line, _i0);
      _p1 = st_lineinterpolatepoint(_line, _i1);
      _p2 = st_lineinterpolatepoint(_line, _i2);

      if _side=1 then 
        _curvature_point = (gs__apply_vector_to_point(
        		     (gs__vector_2d_left_perp(gs__vector_from_segment(_line))#)*_cloud_height,
			     _p1,
	     		     4326)
			   );
      else
        _curvature_point = (gs__apply_vector_to_point(
        		     (gs__vector_2d_right_perp(gs__vector_from_segment(_line))#)*_cloud_height,
			     _p1,
	     		     4326)
			   );
      end if;
        
      _ewkt = _ewkt || 'CIRCULARSTRING(' || st_x(_p0) || ' ' || st_y(_p0) || ',' ||
      	      st_x(_curvature_point) || ' ' || st_y(_curvature_point) || ',' ||
	      st_x(_p2) || ' ' || st_y(_p2) || '),';
    end loop;
  end loop nextsegment;

  _ewkt = rtrim(_ewkt, ',') || ')';
  return st_geomfromewkt(_ewkt);
end;
$$
language plpgsql;



/*

  This function takes box ST_Linestring (that is, a closed linestring
  with 4 sides) and place equaly spaced points along each face,
  joining with lines opposite ones. It is intended to be used to
  subdivide a grid.

  The functions need as arguments the ST_Linestring and the number of
  subdivisions to apply.

  Returns a set of geometries: lines connecting opposing points and
  the ST_Linestring itself. Later a topology must be build to create
  polygons from those lines.

*/

create or replace function public.gs__gridlines(
  _geom geometry,
  _subdivisions integer
) returns setof geometry as
$$
declare
  _line geometry;
  _basestep float;
  _ret geometry;
  _opposite integer;
  _points geometry[];
begin
  _points = array[]::geometry[];		

  -- Address faces
  for _a in 1..4 loop
    _line = st_makeline(st_pointn(_geom, _a), st_pointn(_geom, _a+1));
    return next _line;
    _basestep = (st_length(_line)/(_subdivisions))/st_length(_line);

    for _b in 1.._subdivisions-1 loop
      _ret = st_lineinterpolatepoint(_line, _b*_basestep);
      _points = _points || _ret;
    end loop;
  end loop;

  for _a in 1..(_subdivisions-1) loop
    _opposite = (((_subdivisions-1)*3)+1)-_a;
    _ret = st_makeline(_points[_a], _points[_opposite]);
    return next _ret;
  end loop;

  for _a in _subdivisions..((_subdivisions-1)*2) loop
    _opposite = (_subdivisions+((_subdivisions-1)*4))-_a;
    _ret = st_makeline(_points[_a], _points[_opposite]);
    return next _ret;
  end loop;
end;
$$
language plpgsql;



/*

  Takes a [xmin, ymin, xmax, ymax] and creates an evenly distributed grid of rows,columns size
  as polygons.
  Optionally, grids can have an offset for overlapping other ones.

*/
create or replace function public.gs__polygongrid(
  _coordarray float[],
  _rows integer,
  _columns integer,
  _offset float
) returns setof geometry as
$$
declare
  _xstep float;
  _ystep float;
  _a integer;
  _b integer;
  _xmin float;
  _ymin float;
  _xmax float;
  _ymax float;
begin
  -- Filter absurd offset
  if _offset is null or _offset<0 then
    _offset=0;
  end if;

  _xstep = (_coordarray[3]-_coordarray[1])/_rows;
  _ystep = (_coordarray[4]-_coordarray[2])/_columns;

  for _a in 0.._rows-1 loop
    for _b in 0.._columns-1 loop
      _xmin = _coordarray[1]+(_a*_xstep)-_offset;
      _xmax = _coordarray[1]+((_a+1)*_xstep)+_offset;
      _ymin = _coordarray[2]+(_b*_ystep)-_offset;
      _ymax = _coordarray[2]+((_b+1)*_ystep)+_offset;

      return next gs__rectangle(array[_xmin,_ymin,_xmax,_ymax]::float[]);
    end loop;
  end loop;
end;
$$
language plpgsql;



/*

  Overload of the preceding function without offset.

*/
create or replace function public.gs__polygongrid(
  _coordarray float[],
  _rows integer,
  _columns integer
) returns setof geometry as
$$
  select gs__polygongrid(_coordarray, _rows, _columns, 0);
$$
language sql;



/*

  Affine transformation: scale around an arbitrary point:
    _geom : geometry to transform
    _sw : scale width
    _sh : scale height
    _x : x of scale point
    _y : y of scale point

*/
create or replace function public.gs__scalearoundpoint(
  _geom geometry,
  _sw float,
  _sh float,
  _x float,
  _y float
) returns geometry as
$$
  select st_affine(_geom, _sw, 0, 0, _sh, _x-(_sw*_x), _y-(_sh*_y));
$$
language sql;



/*

  Overloading of the former function. Affine transformation: scale
  around an arbitrary point:

    _geom : geometry to transform
    _sw : scale width
    _sh : scale height
    _point : pointg geometry to transform around

*/
create or replace function public.gs__scalearoundpoint(
  _geom geometry,
  _sw float,
  _sh float,
  _point geometry
) returns geometry as
$$
  select gs__scalearoundpoint(_geom, _sw, _sh, st_x(_point), st_y(_point));
$$
language sql;


/*

  Takes a multigeometry and outputs an array of geometries.

*/
create or replace function public.gs__geomarrayfrommulti(
  _geom geometry
) returns geometry[] as
$$
declare
  _out geometry[];
  _i record;
begin
  _out = array[]::geometry[];

  for _i in select * from st_dump(_geom) loop
    _out = _out || _i.geom;
  end loop;
  
  return _out;
end;
$$
language plpgsql;


/*

  Computes gravity center of an array of points.

*/
create or replace function public.gs__gravitycenter(
  _points geometry[]
) returns geometry as
$$
declare
  _point geometry;
  _g geometry;
  _x float;
  _y float;
begin
  _x = 0;
  _y = 0;

  foreach _g in array _points loop
    _x = _x+st_x(_g);
    _y = _y+st_y(_g);
  end loop;

  _x = _x/array_length(_points, 1);
  _y = _y/array_length(_points, 1);

  return st_point(_x, _y);
end;
$$
language plpgsql;



/*

  Clean small angles in linestrings, multilinestrings, polygons, and multipolygons. Angle is in degrees.

*/
create or replace function public.gs__cleanangles(
  _geom geometry,
  _angle double precision
) returns geometry as
$$
declare
  _type varchar(50);
  _parts geometry[];
  _r record;
  _g geometry;
  _i record;
  _rings geometry[];
  _holes geometry[];
  _out geometry;
begin
  _type =  st_geometrytype(_geom);
  _parts = array[]::geometry[];

  -- Dump all parts
  for _r in select st_dump(_geom) as part loop
    _g = (_r.part).geom;

    if st_geometrytype(_g) not in ('ST_LineString') then
      -- If not a LineString, check for rings
      _rings = array[]::geometry[];

      for _i in select st_dumprings(_g) as ring loop
        _rings = _rings || _gs__cleanangles(st_boundary((_i.ring).geom), _angle);
      end loop;

      -- If there are rings, construct polygon with holes
      if array_length(_rings,1)>1 then
      	_holes = gs__pullfromarray(_rings, 1);
        _parts = _parts || st_makepolygon(_rings[1], _holes);
      else
        -- If no rings, just use the first one as the outer shell
        _parts = _parts || st_makepolygon(_rings[1]);
      end if;
    else
      -- If a LineString, just clean the part
      _parts = _parts || _gs__cleanangles(_g, _angle);
    end if;
  end loop;

  -- Original type LineString: return the first "part" (and only)
  if _type='ST_LineString' then
    _out = _parts[1];
  end if;

  -- Original type MultiLineString: return a multi of all parts
  if _type='ST_MultiLineString' then
    _out = st_collect(_parts);
  end if;

  -- Original type Polygon: just return the first "part"
  if _type='ST_Polygon' then
    _out = _parts[1];
  end if;

  -- Original type MultiPolygon: return a multi of all parts
  if _type='ST_MultiPolygon' then
    _out = st_collect(_parts);
  end if;

  return _out;
end;
$$
language plpgsql;



/*

  Clean small angles in linestrings. Angle is in degrees.
  See gs__cleanangles for a polymorphic version.

*/
create or replace function public._gs__cleanangles(
  _line geometry,
  _angle double precision
) returns geometry as
$$
declare
  _i integer;
  _p geometry[];
  _ang double precision;
  _out geometry;
  _v1 gsv__vector;
  _v2 gsv__vector;
begin
  -- Check geometry type
  if st_geometrytype(_line)<>'ST_LineString' then
    return null;
  end if;

  -- Decompose linestring into matrix of points, but checking no same point in sequence
  _p = array[st_pointn(_line, 1)];

  for _i in 2..st_npoints(_line) loop
    if not st_equals(_p[array_length(_p, 1)], st_pointn(_line, _i)) then  
      _p = _p || st_pointn(_line, _i);
    end if;
  end loop;

  _i = 1;

  while _i<=array_length(_p,1)-1 loop
    -- Check if it is the initial vertex of a closed

    if _i=1 and _p[1]=_p[array_length(_p,1)] then
      _v1 = gsv__vectorfrompoints(_p[array_length(_p,1)-1], _p[1]);
      _v2 = gsv__vectorfrompoints(_p[1], _p[2]);

      -- Detect same point in sequence

      -- if _v1=(0,0,0)::gsv__vector or _v2=(0,0,0)::gsv__vector then
      --   _p = gs__pullfromarray(_p, 1);
      -- else
      _ang = gsv__vectorangle(_v1, _v2);

      if degrees(_ang)<_angle then
        _p = gs__pullfromarray(_p, 1);
        _p = gs__pullfromarray(_p, array_length(_p,1));
        _p = _p || _p[1];
      else
        _i = _i+1;
      end if;

    else
      if _i=1 then 
	_i = _i+1;
      else
        _v1 = gsv__vectorfrompoints(_p[_i-1], _p[_i]);
	_v2 = gsv__vectorfrompoints(_p[_i], _p[_i+1]);

        -- Detect same point in sequence
  
        if _v1=(0,0,0)::gsv__vector or _v2=(0,0,0)::gsv__vector then
          _p = gs__pullfromarray(_p, _i);
        else
          _ang = gsv__vectorangle(_v1, _v2);

          if degrees(_ang)<_angle then
            _p = gs__pullfromarray(_p, _i);
          else
	    _i = _i+1;
	  end if;
	end if;
      end if;
    end if;
  end loop;

  _out = st_makeline(_p);
  return _out;
end
$$
language 'plpgsql' volatile;



/*

  Creates a weighted geometric mean from points and weights.

*/
create or replace function public.gs__geometric_mean(
  _geoms geometry[],
  _weights double precision[]
) returns geometry as
$$
declare
  _i integer;
  _fw double precision[];
  _x double precision[];
  _y double precision[];
  _tx double precision;
  _ty double precision;
  _tw double precision;
  _out geometry;
  _ttw double precision[];
begin
  _fw = array[]::double precision[];
  _x = array[]::double precision[];
  _y = array[]::double precision[];
  _tx = 0;
  _ty = 0;
  _tw = 0;

  -- Check if _weights are all 0 or nulls
  _ttw = gs__uniquearray(_weights);

  if _ttw=array[0]::double precision[] or
     _ttw=array[0, null]::double precision[] or
     _ttw=array[null, 0]::double precision[] or
     _ttw=array[null]::double precision[] then
     return null;
  end if;

  -- No weights
  if _weights is null then
    for i in 1..array_length(_geoms, 1) loop
      _fw = _fw || 1::double precision;
    end loop;
  else
    _fw = _weights;
  end if;

  for i in 1..array_length(_geoms, 1) loop
    if st_geometrytype(_geoms[i]) in ('ST_Polygon', 'ST_MultiPolygon') then
      _geoms[i] = st_centroid(_geoms[i]);
    end if;
    
    _x = _x || (_fw[i]*st_x(_geoms[i]));
    _y = _y || (_fw[i]*st_y(_geoms[i]));

  end loop;

  -- Sum of weighted coordinates and weights
  for i in 1..array_length(_geoms, 1) loop
    _tx = _tx+_x[i];
    _ty = _ty+_y[i];
    _tw = _tw+_fw[i];
  end loop;

  _out = st_makepoint(_tx/_tw, _ty/_tw);

  return _out;
end;
$$
language plpgsql;



/*

  Creates a geometric mean with evenly weighted points.

*/

create or replace function public.gs__geometric_mean(
  _geoms geometry[]
) returns geometry as
$$
declare
  _out geometry;
begin
  _out = gs__geometric_mean(_geoms, null);

  return _out;
end;
$$
language plpgsql;



/*

  This aggregate dumps a multigeometry and re-st_collect them to avoid geometrycollections from 
  st_collect of multi geometries.

*/

create or replace function gs__recollect(geometry, geometry)
returns geometry as
$$
  select st_collect(a.geom)
  from (
    select (st_dump($1)).geom
    union
    select (st_dump($2)).geom) a;
$$
language sql strict;

drop aggregate if exists gs__recollect(geometry);

create aggregate gs__recollect(geometry)
(
  sfunc = gs__recollect,
  stype = geometry
);
    


/*

  Generates random points inside a polygon

*/

create or replace function public.gs__randompointsinpoly(
  _poly geometry,
  _npoints integer
) returns setof geometry as
$$
declare
  _xmin double precision;
  _ymin double precision;
  _xmax double precision;
  _ymax double precision;
  _srid integer;
  _point geometry;
begin

  -- Get dimensions
  _xmin = st_xmin(_poly);
  _ymin = st_ymin(_poly);
  _xmax = st_xmax(_poly);
  _ymax = st_ymax(_poly);
  _srid = st_srid(_poly);

  -- Generate points
  while _npoints>0 loop
    _point = st_setsrid(st_makepoint(
      (_xmin+(random()*(_xmax-_xmin))),
      (_ymin+(random()*(_ymax-_ymin)))), _srid);

    if st_contains(_poly, _point) then
      _npoints = _npoints-1;
      return next _point;
    end if;
  end loop;
      
end;
$$
language plpgsql;

comment on function public.gs__randompointsinpoly(geometry, integer) is
'Generates random points inside a polygon.';



/*
 
  Returns all LineStrings that makes up the 
  outer perimeter of a ST_Polygon (will not work with ST_MultiPolygon).

*/

create or replace function gs__getperimeterlines(
  _poly geometry
) returns setof geometry as
$$
declare
  _sql text;
  _ext geometry;
  _i integer;
begin

  _ext = st_exteriorring(_poly);

  for _i in 1..st_npoints(_ext)-1 loop
    return next st_makeline(st_pointn(_ext, _i), st_pointn(_ext, _i+1));
  end loop;

end;
$$
language plpgsql;



/*

  Returns the center point of a linestring.

*/

create or replace function gs__getmidpoint(
  _line geometry
) returns geometry as
$$

  select st_lineinterpolatepoint(_line, .5);

$$
language sql;


commit;
