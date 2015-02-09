/*

  Returns TRUE if the number is even.

*/
create or replace public.function gs__even(
  _number numeric
) returns boolean as
$$
  select $1%2=0;
$$
language sql;
