-- check if the extension exists, always output 'DO' to not change the diff result of the test
do $$
begin
    drop extension if exists pg_render;
    create extension pg_render;
end $$;

-- only insert test data if the table does not exist
do $$
begin
    if not exists (select 1 from information_schema.tables where table_name = 'posts') then
        create table posts (id serial primary key, title text not null, text text not null, author text not null);
        insert into posts (title, text, author) values
        ('Title 1', 'Example content 1', 'Author 1'),
        ('Title 2', 'Example content 2', 'Author 2'),
        ('Title 3', 'Example content 3', 'Author 3'),
        ('Title 4', 'Example content 4', 'Author 4');
    end if;
end $$;

-- render a single value
select render('{{ value }}', (select count(*) from posts));

-- render a single column from a single row
select render('{{ value }}', (select title as value from posts where id = 1));

-- render multiple columns from a single row
select render('{{ title }} {{ text }}', (select to_json(props) from (select title, text from posts where id = 1) props));

-- render array of values by looping in template
select render('{% for value in values %} {{ value }} {% endfor %}', (select array(select title from posts)));

-- render multiple rows with multiple columns
select
render(
    '{% for row in rows %} {{ row.title }} {{ row.text }} {{ row.author }} {% endfor %}',
    json_agg(to_json(posts.*))
)
from posts;

-- render aggregate single column value
select render_agg('{{ value }}', title) from posts where id < 3;

-- render aggregate using derived table
select render_agg('{{ title }} {{ text }}', props) from (select title, text from posts) as props;

-- render aggregate using json_build_object
select render_agg('{{ title }} {{ text }}', json_build_object('title', title, 'text', text)) from posts;

-- render different types of values
select render('{{ value }}', 1::int);
select render('{{ value }}', 922337203685477580::bigint);
select render('{{ value }}', 1::smallint);
select render('{{ value }}', 1.59::float);
select render('{{ value }}', 1.59::decimal);
select render('{{ value }}', 1.59::double precision);
select render('{{ value }}', 1::numeric);
select render('{{ value }}', 1::real);
select render('{{ value }}', 'a'::text);
select render('{{ value }}', 'a'::varchar);
select render('{{ value }}', 'a'::char);
select render('{{ value }}', true::bool);

select render('{{ value }}', '2024-02-11'::date);
select render('{{ value }}', '14:30:00'::time);
select render('{{ value }}', '2024-02-11 14:30:00'::timestamp);
select render('{{ value }}', '2024-02-11 14:30:00+00'::timestamptz);
select render('{{ value }}', '1 day'::interval);

select render('{{ value }}', '550e8400-e29b-41d4-a716-446655440000'::uuid);
select render('{{ value }}', '192.0.2.0/24'::inet);

select render('{{ value }}', '{ "value": "a" }'::json);
select render('{{ value }}', '{ "value": "a" }'::jsonb);
