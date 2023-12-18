# pg_render

A view render engine for PostgreSQL. Render view templates with SQL query data.

Supports [liquid](https://shopify.github.io/liquid/) templating language via [liquid-rust](https://github.com/cobalt-org/liquid-rust).

# Installation

Download from [Releases](https://github.com/mkaski/pg_render/releases).

```bash
# Ubuntu w/ PostgreSQL 15
wget https://github.com/mkaski/pg_render/releases/download/v0.5.0/pg_render-v0.5.0-pg15-amd64-linux-gnu.deb \
    && dpkg -i pg_render-v0.5.0-pg15-amd64-linux-gnu.deb \
    && apt-get install -f \
    && rm -rf pg_render-v0.5.0-pg15-amd64-linux-gnu.deb
```

# Getting Started

```sql
create extension pg_render;

-- example data
create table users (name text not null, age integer);
insert into users (name, age) values ('Example 1', 10), ('Example 2', 20), ('Exampl 2', 30);

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
create table templates (id text not null, template text not null);
insert into templates (id, template) values ('example', '
<html>
  <head>
    <title>Example</title>
  </head>
  <body>
    <h1>name: {{ name }}</h1>
    <h2>age: {{ age }}</h2>
  </body>
');

select render((select template from templates where id = 'example'), (select name, age from users where name = 'Example 1')::json));
```

## Example with PostgREST

See [pg_render_example](https://github.com/mkaski/pg_render_example) project for Dockerized pg_render & [PostgREST](https://postgrest.org) Hello World application.

LIVE DEMO at [_](_)

## SQL

Example of a full web page rendered with SQL ([source](https://github.com/mkaski/pg_render_example/blob/master/sql/002_products.sql)).

```sql
create or replace function api.products() returns "text/html" as $$
  select render(
    (select template from templates where id = 'layout'),
    (json_build_object(
      'title', 'Products',
      'styles', (select template from templates where id = 'styles'),
      'header', (select template from templates where id = 'header'),
      'children', (select render(
          (select template from templates where id = 'products'),
          (select json_agg(to_json(products.*)) from products)
      )),
      'footer', (select template from templates where id = 'footer')
    ))
  );
$$ language sql stable;
```

## Rendered HTML

```html

<html>
  <head>
    <title>Products</title>
    <style>{...}</style>
  </head>
  <body>
    <header>
      <h1>Layout Example</h1>
    </header>
    <ul>
      <li>
        <h2>Product Name</h2>
        <p>Product Description</p>
        <p>$100</p>
        <img src="..." />
      </li>
      {...}
  </ul>
    <footer>
      <p>Footer</p>
    </footer>
  </body>
</html>

```

# Development

See [pgrx documentation](https://github.com/pgcentralfoundation/pgrx) for more information.

```bash
cargo pgrx run
```
