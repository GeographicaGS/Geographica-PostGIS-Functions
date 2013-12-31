begin;

/*

  This function creates a temporary table and returns its name. It
  needs a matching length pair of arrays, one with the names of the
  fields and another one with the data types.

*/
create or replace function public.gs__createtemptable(
  _field_name varchar(100)[],
  _field_type varchar(100)[]
) returns char(42) as
$$
declare
  _name char(42);
	_i integer;
	_sql text;
begin
	-- Create a table name
  _name='tt' || ltrim(digest(now()::text || _field_name::text || _field_type::text, 'sha1')::text, '\x');

	-- This table will hold temporary data
	_sql = 'create temporary table ' || _name || '(';

	for _i in 1..array_length(_field_name,1) loop
		_sql = _sql || _field_name[_i] || ' ' || _field_type[_i] || ',';
  end loop;

	_sql = rtrim(_sql, ',') || ');';
	execute _sql;

	return _name;
end;
$$
language plpgsql;


/*

  Clears the content of a temporary table (delete from).

*/
create or replace function public.gs__cleartemptable(
  _name char(42)
) returns void as
$$
declare
  _sql text;
begin
  _sql = 'delete from ' || _name || ';';
	execute _sql;
end;
$$
language plpgsql;

/*

  Drops a temporary table.

*/
create or replace function public.gs__droptemptable(
  _name char(42)
) returns void as
$$
declare
  _sql text;
begin
  _sql = 'drop table ' || _name || ';';
	execute _sql;
end;
$$
language plpgsql;

commit;
