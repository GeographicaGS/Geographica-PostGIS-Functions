/*

  Takes a set of points and a closed LINESTRING and returns the splits.

  LESS LOOPS, USE SQL.

*/
create or replace function public.gs__splitlinestring(
  _points geometry[],
  _line geometry,
  _tolerance float
) returns geometry[] as
$$
declare
  _p geometry;
  _lines geometry[]=array[]::geometry[];
  _c boolean=true;
  _i integer;
  _a geometry;
  _b geometry;
  _l1 geometry;
  _l2 geometry;
  _srid integer;
begin
  raise notice 'Loop: %', st_isclosed(_line);

  _srid = st_srid(_points[1]);

	-- Delete all points that doesn't fall within tolerance
	for _i in 1..array_length(_points, 1) loop
	  if st_distance(_points[_i], _line)>_tolerance then
		  _points = gs__pull_from_array(_points, _i);
		end if;
	end loop;

  -- Sort points by distance to the start node
  _i = 1;
  while _c loop
    _c = false;
    while _i<(array_length(_points, 1)) loop
      if st_line_locate_point(_line, _points[_i])>st_line_locate_point(_line, _points[_i+1]) then
        _a = _points[_i];
	      _b = _points[_i+1];
      	_points[_i] = _b;
      	_points[_i+1] = _a;
      	_c = true;
      end if;
      _i = _i+1;
    end loop;
    _i = 1;
  end loop;

  -- Cut the line with the string of points
  _i = 1;
  while _i<(array_length(_points, 1)) loop
    _lines = _lines || st_setsrid(st_line_substring(_line, st_line_locate_point(_line, _points[_i]),
                                         st_line_locate_point(_line,_points[_i+1])), _srid);
    _i = _i+1;
  end loop;

  if st_isclosed(_line) then
    -- Cut from start to first and from last to end, and join them  
    _l1 = st_setsrid(st_line_substring(_line, 0, st_line_locate_point(_line, _points[1])), _srid);
    _l2 = st_setsrid(st_line_substring(_line, st_line_locate_point(_line,
             _points[array_length(_points,1)]), 1), _srid);
    _lines = _lines || st_union(_l1, _l2);
  end if;

  return _lines;
end;
$$
language plpgsql;


select gs__splitlinestring(array[st_makepoint(0.5,0)], 
                           st_makeline(array[st_makepoint(0,0),st_makepoint(1,0),st_makepoint(1,1),
                                             st_makepoint(0,1),st_makepoint(0,0)]), 0.001)
