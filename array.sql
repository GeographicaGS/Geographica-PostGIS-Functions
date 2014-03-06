begin;

/* 

  Pulls an element by index from a matrix and return the rest 

*/
create or replace function public.gs__pullfromarray(
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
create or replace function public.gs__uniqueorderedarray(
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
create or replace function public.gs__arraymin(
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
create or replace function public.gs__arraymax(
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

/*

  Returns the indexes of the first common element shared between
  varchar arrays.


  TODO: revise this, try with loops.
*/
create or replace function public.gs__arrayfirstmatch(
  _a varchar[],
  _b varchar[]
) returns integer[] as
$$
declare
  _ta char(42);
  _tb char(42);
  _sql varchar;
  _r record;
begin
  if not _a && _b then
    return null;
  end if;

  _ta = gs__createtemptable(array['index_a', 'data_a']::varchar[], 
                            array['integer', 'varchar']::varchar[]);

  _tb = gs__createtemptable(array['index_b', 'data_b']::varchar[], 
                            array['integer', 'varchar']::varchar[]);

  for _i in 1..array_length(_a, 1) loop
    _sql = 'insert into ' || _ta || ' values(' || _i || ',''' || _a[_i] || ''');';
    execute _sql;
  end loop;

  for _i in 1..array_length(_b, 1) loop
    _sql = 'insert into ' || _tb || ' values(' || _i || ',''' || _b[_i] || ''');';
    execute _sql;
  end loop;

  _sql = '
    select *, a.index_a+b.index_b as t
    from 
      ' || _ta || ' a inner join 
      ' || _tb || ' b 
      on a.data_a=b.data_b 
    order by a.index_a+b.index_b
    limit 1;';

  execute _sql into _r;

  execute gs__droptemptable(_ta);
  execute gs__droptemptable(_tb);
  return array[_r.index_a, _r.index_b]::integer[];
end;
$$
language plpgsql;

/*

  Type to store subarrays results. (varchar variant).

*/
drop type if exists public.gs__subarray_varchar cascade;
create type public.gs__subarray_varchar as(
  istart integer,
  iend integer,
  subarray varchar[]
);

/*

  Returns all the subarrays within an array. (varchar variant).

*/  
create or replace function public.gs__subarrays(
  _array varchar[]
) returns setof gs__subarray_varchar as
$$
declare
  _o gs__subarray_varchar;
  _i integer;
  _n integer;
begin
  -- Try all possible lengths within the array
  for _i in reverse array_length(_array,1)..1 loop

    -- Extract all chunks of the given length
    for _n in 1..(array_length(_array,1)-_i)+1 loop
      _o = (_n, _n+_i-1, _array[_n:(_n+_i-1)])::gs__subarray_varchar;
      return next _o;
    end loop;
    
  end loop;
end;
$$
language plpgsql;

/*

  Type for split array, integer variant.

*/
drop type if exists gs__splittedarray_integer cascade;
create type gs__splittedarray_integer as(
  _first integer[],
  _second integer[],
  _third integer[]
);

/*

  Given an array and a start and end indices, returns three arrays
  split at those points. Integer variant.

*/
create or replace function gs__splitarray(
  _array integer[],
  _start integer,
  _end integer
) returns gs__splittedarray_integer as
$$
declare
  _first integer[];
  _second integer[];
  _third integer[];
  _o gs__splittedarray_integer;
begin
  _first = _array[1:_start-1];
  _second = _array[_start:_end];
  _third = _array[_end+1:array_length(_array,1)];

  _o = (_first, _second, _third)::gs__splittedarray_integer;

  return _o;
end;
$$
language plpgsql;

/*

  Inserts a subarray within an array in a given position. (integer
  variant).

*/
create or replace function gs__insertsubarray(
  _array integer[],
  _subarray integer[],
  _index integer
) returns integer[] as
$$
begin
  _array = _array[1:_index-1] || _subarray || _array[_index:array_length(_array,1)];
  return _array;
end;
$$
language plpgsql;

/*

  Returns all indices where an element is in a array. (integer
  variant).

*/
create or replace function gs__elementindices(
  _array integer[],
  _element integer
) returns integer[] as
$$
declare
  _i integer;
  _o integer[];
begin
  _o = array[]::integer[];

  for _i in 1..array_length(_array,1) loop
    if _array[_i]=_element then
      _o = _o || _i;
    end if;
  end loop;

  return _o;
end;
$$
language plpgsql;

/*

  Inserts a subarray within an array in multiple positions. (integer
  variant).

*/
create or replace function gs__insertsubarraymulti(
  _array integer[],
  _subarray integer[],
  _indices integer[]
) returns integer[] as
$$
declare
  _i integer;
  _offset integer;
begin
  if _indices<>array[]::integer[] then
    for _i in 1..array_length(_indices,1) loop
      _offset = (_i-1)*array_length(_subarray,1);
    
      _array = _array[1:_indices[_i]-1+_offset] || _subarray || 
               _array[_indices[_i]+_offset:array_length(_array,1)+_offset];
    end loop;
  end if;

  return _array;
end;
$$
language plpgsql;

/*

  Replaces an element of an array with a subarray in multiple
  positions. (integer variant).

*/
create or replace function gs__replacesubarraymulti(
  _array integer[],
  _subarray integer[],
  _indices integer[]
) returns integer[] as
$$
declare
  _i integer;
  _offset integer;
begin
  if _indices<>array[]::integer[] then
    for _i in 1..array_length(_indices,1) loop
      _offset = (_i-1)*(array_length(_subarray,1)-1);
    
      _array = _array[1:_indices[_i]-1+_offset] || _subarray || 
               _array[_indices[_i]+(_offset)+1:array_length(_array,1)];
    end loop;
  end if;

  return _array;
end;
$$
language plpgsql;

/*

  Returns an array with repeated elements deleted. varchar variant.

*/
create or replace function public.gs__uniquearray(
  _a varchar[]
) returns varchar[] as
$$
declare
  _out varchar[];
  _s varchar;
begin
  _out = array[]::varchar[];

  foreach _s in array _a loop
    if not array[_s]::varchar[] <@ _out then
      _out = _out || _s;
    end if;
  end loop;

  return _out;
end;
$$
language plpgsql;


commit;
