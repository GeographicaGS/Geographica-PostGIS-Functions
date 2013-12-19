/*

  String processing functions.

*/

/*

  Tidy up strings for use as object's name.

*/
create or replace function public.gs__tidy_names(
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
