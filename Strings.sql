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
