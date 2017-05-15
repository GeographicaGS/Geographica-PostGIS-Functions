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
    else
      return null;
    end if;
  end loop;

  if _index<>'' then 
    _out = (_root::float)*10^(_index::float);
  else
    _out = _root::float;
  end if;
  
  return _out;
end;
$$
language plpgsql;



/*

  Returns a varchar after extracting the first ocurrence of a substring, inserting
  optionally between the two parts a varchar.

*/

create or replace function gs__strextract(
  _original varchar,
  _subs varchar,
  _subschar varchar
) returns varchar as
$$
declare
  _t integer;
  _s0 varchar;
  _s1 varchar;
begin
  _t = strpos(_original, _subs);

  if _t>0 then
    _s0 = substr(_original, 0, _t);
    _s1 = substr(_original, _t+length(_subs));

    return _s0 || _subschar || _s1;
  else
    return _original;
  end if;
end;
$$
language plpgsql;



/*

  This is the output type of the tokenizer:

  :param tokens: Array of recognized tokens.
  :type tokens: varchar[]
  :param residue: Part of the input string not recognized as tokens.
  :type residue: varchar
 
*/

drop type if exists gs__tokenizer cascade;

create type gs__tokenizer as(
  tokens varchar[],
  residue varchar
);


/*

  This is the tokenizer. Usually it is used wrapped inside another function that provides tokens and replace token.

  :param _str: String to be tokenized.
  :type _str: varchar
  :param _tokens: Array of tokens, in order of precedence.
  :type _tokens: varchar[]
  :param _rtoken: Token used as a replacement for identified tokens. Should be something that is not a target token nor something that has somehow sense in the residue string.
  :type _rtoken: varchar
  :return type: gs__tokenizer

*/

create or replace function gs__tokenize(
  _str varchar,
  _tokens varchar[],
  _rtoken varchar
) returns gs__tokenizer as
$$
declare
  _t varchar;
  _p integer;
  _out gs__tokenizer;
  _i bool;
begin

  _out.tokens = array[]::varchar[];

  foreach _t in array _tokens loop
    _i = true;

    while _i loop
      _i = false;
      _p = strpos(_str, _t);
      
      if _p>0 then
        _out.tokens = _out.tokens || _t;
        _str = gs__strextract(_str, _t, _rtoken);
	_i = true;
      end if;
      
    end loop;

  end loop;

  -- Clean residue
  while strpos(_str, _rtoken)>0 loop
    _str = gs__strextract(_str, _rtoken, '');
  end loop;
    
  _out.residue = _str;

  return _out;
  
end;
$$
language plpgsql;


commit;
