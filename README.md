# pg_render

Render engine extension for PostgreSQL.

```sql
-- PostgreSQL extension
create extension pg_render;
-- Serve /index using postgREST
create function api.index() returns "text/html" as $$
-- Render HTML template with pg_render
select render(
  '<html>
    <head>
      <title>{{ title }}</title>
    </head>
    <body>
      <h1>{{ title }}</h1>
      <p>{{ text }}</p>
      <strong>{{ author }}</strong>
    </body>
  </html>',
  (select title, text, author from posts where id = 1)
)
$$;
```

->

```html
# HTTP GET /index
<html>
  <head>
    <title>Example</title>
  </head>
  <body>
    <h1>Example</h1>
    <p>Example text</p>
    <strong>Example author</strong>
  </body>
</html>
```

# Installation

Download from [Releases](https://github.com/mkaski/pg_render/releases).

```bash
# Ubuntu w/ PostgreSQL 15
wget https://github.com/mkaski/pg_render/releases/download/v0.5.0/pg_render-v0.5.0-pg15-amd64-linux-gnu.deb \
    && dpkg -i pg_render-v0.5.0-pg15-amd64-linux-gnu.deb \
    && apt-get install -f \
    && rm -rf pg_render-v0.5.0-pg15-amd64-linux-gnu.deb
```

# Examples

See more examples in [pg_render_example](https://github.com/mkaski/pg_render_example/blob/master/sql/002_products.sql) project, and how to use pg_render with [PostgREST](https://postgrest.org).

```sql
-- example data
create table users (name text not null, age integer);
insert into users (name, age) values ('Example 1', 10), ('Example 2', 20), ('Exampl 2', 30);
create table templates (id text not null, template text not null);
insert into templates (id, template) values ('example', '<header>{{ name }}</header><footer>{{ age }}</footer>');

-- render a single value
select render('The count is {{ value }}', (select count(*) from users));

-- render a single column from a single row
select render('Name: {{ value }}', (select name as value from users where name = 'Example 1'));

-- render multiple columns from a single row
select render('Name: {{ value }}, Age: {{ age }}', (select name, age from users where name = 'Example 1')::to_json);

-- render array of values by looping
select render('{% for value in values %} {{ value }} {% endfor %}', (select array(select name from users)));

-- render multiple rows with multiple columns
select
    render(
        '{% for row in rows %} name: {{ row.name }}, age: {{ row.age }} {% endfor %}',
        json_agg(to_json(users.*))
    )
from users;

-- render from saved template
select render(
  (select template from templates where id = 'example'),
  (select name, age from users where name = 'Example 1')::json
);

```

# Development

Made with

- [Liquid](https://shopify.github.io/liquid/) templating language via [liquid-rust](https://github.com/cobalt-org/liquid-rust)
- [pgrx](https://github.com/pgcentralfoundation/pgrx) Rust extension framework for PostgreSQL

## Build and run locally

```bash
# clone this repo
cargo install
cargo pgrx run
```
