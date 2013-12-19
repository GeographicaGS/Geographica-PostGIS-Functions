begin;

/* 

  Pulls an element by index from a matrix and return the rest 

*/
create or replace function public.gs__pull_from_array(
  _a anyarray,
  _p integer
) returns anyarray as
$$
begin
  return _a[1:_p-1] || _a[_p+1:array_upper(_a, 1)];
end;
$$
language plpgsql;

/*

  Returns a unique matrix created by the = operator based on an
  ordered sequence of adyacent equal items.

*/
create or replace function public.gs__unique_ordered_array(
  _a anyarray
) returns anyarray as
$$
declare
  _i integer;
begin
  _i = 0;

  while _i<array_length(_a, 1) loop
    if _a[_i]=_a[_i+1] then
      _a = gs__pull_from_array(_a, _i+1);
		else
		  _i = _i+1;
    end if;
  end loop;

  return _a;
end;
$$
language plpgsql;

/*
  
  Returns the min value in a numeric array.

*/
create or replace function public.gs__array_min(
  _array numeric[]
) returns numeric as
$$
declare
  _i numeric;
  _n numeric;
begin
  _i = _array[1];

  foreach _n in array _array loop
    if _n<_i then
		  _i = _n;
    end if;
	end loop;

	return _i;
end;
$$
language plpgsql;

/*
  
  Returns the max value in a numeric array.

*/
create or replace function public.gs__array_max(
  _array numeric[]
) returns numeric as
$$
declare
  _i numeric;
  _n numeric;
begin
  _i = _array[1];

  foreach _n in array _array loop
    if _n>_i then
		  _i = _n;
    end if;
	end loop;

	return _i;
end;
$$
language plpgsql;

commit;
