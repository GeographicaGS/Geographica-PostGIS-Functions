/*

  String processing functions.

*/

begin;

/*

  Tidy up strings for use as object's name.

*/
create or replace function public.gs__tidynames(
  _name text
) returns text as
$$
begin
  _name = replace(lower(trim(_name)), ' ', '_');
  _name = replace(replace(replace(replace(_name, '.', ''), '(', ''), '=', ''), ')', '');
  _name = replace(replace(replace(replace(replace(_name, 'á', 'a'), 'é', 'e'), 'í', 'i'), 'ó', 'o'), 'ú', 'u');
  _name = replace(replace(_name, 'ñ', 'ny'), '/', '_');

  return _name;
end;
$$
language plpgsql;


/*

  This function takes a string and prepends a character up 
  to a target length.

*/
create or replace function public.gs__prependcharacter(
  _string varchar,
  _character char,
  _targetlength integer
) returns varchar as
$$
declare
  _out varchar;
begin
  _out = _string;

  while length(_out)<_targetlength loop
    _out = _character || _out;
  end loop;

  return _out;
end;
$$
language plpgsql;

commit;

/*

  This function process numbers in scientific notation.

*/
create or replace function public.gs__scientificnotation(
  _string varchar
) returns float as
$$
declare
  _out float;
  _i integer;
  _root varchar;
  _index varchar;
  _c char;
  _rootended boolean;
begin
  _root = '';
  _index = '';
  _rootended = false;

  for _i in 1..length(_string) loop
    _c = substr(_string, _i, 1);
    if _c in ('-','+','0','1','2','3','4','5','6','7','8','9','.') and not _rootended then
      _root = _root || _c;
    elseif _c in ('E','e') then
      _rootended = true;
    elseif _c in ('-','+','0','1','2','3','4','5','6','7','8','9','.') and _rootended then
      _index = _index || _c;
    end if;
  end loop;

  _out = (_root::float)*10^(_index::float);
  return _out;
end;
$$
language plpgsql;
