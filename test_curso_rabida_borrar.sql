select 
  titulo as usuario, 
  b.title as opinion,
  count(*) as votos
from 
  draw a inner join 
  category b on a.id_category=b.id_category
group by
  titulo,
  b.title
order by
  titulo, title;

select 
  b.title as opinion,
  count(*) as votos
from 
  draw a inner join 
  category b on a.id_category=b.id_category
group by
  b.title
order by
  title;

