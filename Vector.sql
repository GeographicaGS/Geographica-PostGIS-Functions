/* ----------------
   Vector functions
   ---------------- */

begin;

/*
  Vector 3D type
*/

create type public.gsv__vector as
(
  x numeric,
  y numeric,
  z numeric
);



/*
  Vector sum
*/

create or replace function public.gsv__sum
(
  _v1 gsv__vector,
  _v2 gsv__vector
)
returns gsv__vector as
$$
declare
  _v gsv__vector;
begin
  _v.x := _v1.x+_v2.x;
  _v.y := _v1.y+_v2.y;
  _v.z := _v1.z+_v2.z;

  return _v;
end;
$$
language plpgsql;



/*
  Vector sum
*/

create operator +
(
  leftarg = gsv__vector,
  rightarg = gsv__vector,
  procedure = gsv__sum,
  commutator = +
);



/*
  Vector module
*/

create or replace function public.gsv__module
(
  _v gsv__vector
)
returns numeric as
$$
begin
  return sqrt((_v.x^2)::numeric+(_v.y^2)::numeric+(_v.z^2)::numeric);
end;
$$
language plpgsql;



/*
  Vector module
*/

create operator &
(
  leftarg = gsv__vector,
  procedure = gsv__module
);




/*
  Vector by scalar product
*/

create or replace function public.gsv__scalarprod
(
  _v gsv__vector,
  _s double precision
)
returns gsv__vector as
$$
declare
  _o gsv__vector;
begin
  _o.x := _v.x*_s;
  _o.y := _v.y*_s;
  _o.z := _v.z*_s;

  return _o;
end;
$$
language plpgsql;



/*
  Vector by scalar multiplier
*/

create operator *
(
  leftarg = gsv__vector,
  rightarg = double precision,
  procedure = gsv__scalarprod,
  commutator = *
);



/*
  Vector dot product
*/

create or replace function public.gsv__dotprod
(
  _v1 gsv__vector,
  _v2 gsv__vector
)
returns double precision as
$$
declare
  _v gsv__vector;
begin
  return _v1.x*_v2.x+_v1.y*_v2.y+_v1.z*_v2.z;
end;
$$
language plpgsql;



/*
  Vector dot product
*/

create operator *
(
  leftarg = gsv__vector,
  rightarg = gsv__vector,
  procedure = gsv__dotprod,
  commutator = *
);



/*
  Returns an unitarian vector for a vector
*/

create or replace function public.gsv__unitvector
(
  _v gsv__vector
)
returns gsv__vector as
$$
declare
  _o gsv__vector;
begin
  _o.x := _v.x/(_v&);
  _o.y := _v.y/(_v&);
  _o.z := _v.z/(_v&);

  return _o;
end;
$$
language 'plpgsql';



/*
  Returns an unitarian vector for a vector
*/

create operator #
(
  leftarg = gsv__vector,
  procedure = gsv__unitvector
);



/*
  Returns a vector from two points
*/

create or replace function public.gsv__vectorfrompoints
(
  _p1 geometry,
  _p2 geometry
)
returns gsv__vector as
$$
declare
  _v gsv__vector;
begin
  _v.x := st_x(_p2)-st_x(_p1);
  _v.y := st_y(_p2)-st_y(_p1);

  if st_coorddim(_p1)=2 or st_coorddim(_p2)=2 then
    _v.z := 0;
  else
    _v.z := st_z(_p2)-st_z(_p1);
  end if;

  return _v;
end;
$$
language 'plpgsql';



/*
  Returns a point that is the result of the tip
  of a vector applied to a point
*/

create or replace function public.gsv__applyvectortopoint
(
  _v gsv__vector,
  _p geometry,
  _srid integer
)
returns geometry as
$$
begin
  if st_coorddim(_p)=2 then
    return st_setsrid(st_makepoint(st_x(_p)+_v.x, st_y(_p)+_v.y), _srid);
  else
    return st_setsrid(st_makepoint(st_x(_p)+_v.x, st_y(_p)+_v.y, st_z(_p)+_v.z), _srid);
  end if;
end;
$$
language 'plpgsql';



/*
  Draws a line from a vector applied to a point
*/

create or replace function public.gsv__vectortoline
(
  _v gsv__vector,
  _p geometry,
  _srid integer
)
returns geometry as
$$
begin
  return st_makeline(_p, gsv__applyvectortopoint(_v, _p, _srid));
end;
$$
language 'plpgsql';



/*
  Returns a perpendicular vector of the same module at left of a 2D vector
*/

create or replace function public.gsv__vectorperpleft(
  _v gsv__vector
) returns gsv__vector as
$$
declare
  _out gsv__vector;
begin
  _out = (-_v.y, _v.x, 0)::gsv__vector;
  return _out;
end;
$$
language 'plpgsql';



/*
  Returns a perpendicular vector of the same module at right of a 2D vector
*/

create or replace function public.gsv__vectorperpright(
  _v gsv__vector
) returns gsv__vector as
$$
declare
  _out gsv__vector;
begin
  _out = (_v.y, -_v.x, 0)::gsv__vector;
  return _out;
end;
$$
language 'plpgsql';



/*

  Returns a vector from a segment (LineString). First and last point
  are considered.

*/

create or replace function public.gsv__vectorfromsegment(
  _l geometry
) returns gsv__vector as
$$
declare
  _p0 geometry;
  _p1 geometry;
  _out gsv__vector;
begin
  _p0 = st_pointn(_l, 1);
  _p1 = st_pointn(_l, st_numpoints(_l));

  _out = gsv__vectorfrompoints(_p0, _p1);
  return _out;
end;
$$
language 'plpgsql';



/*

  Returns the angle of two vectors, in radians.

*/

create or replace function public.gsv__vectorangle(
  gsv__vector,
  gsv__vector
) returns float as
$$
  select acos(($1*$2)/(gsv__module($1)*gsv__module($2)));
$$
language sql;



commit;
