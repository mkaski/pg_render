create or replace function render_template(template text, json_data json)
returns text as $$
declare
  engine text := 'liquid';
  result_text text;
begin
  result_text := null;
  begin
    case engine
      when 'liquid' then
        result_text := pg_render_liquid(template, json_data);
      else
        result_text := format(template, array(select json_array_elements_text(json_data)));
    end case;
  exception
    when others then
      -- handle and log the error
      raise exception 'error in render_template function: %', sqlerrm;
  end;
  -- return the result_text, which might be null if an error occurred
  return result_text;
end;
$$ language plpgsql stable;

-- main render function
create or replace function render(template text, input anyelement)
returns text as $$
declare
  typeof text := pg_typeof(input)::text;
begin
  case
    -- single value
    when typeof in ('text', 'varchar', 'char', 'bpchar', 'name', 'citext', 'uuid', 'xml', 'int2', 'int4', 'int8', 'float4', 'float8', 'numeric', 'bigint') then
      return render_template(template, json_build_object('value', input));
    -- array of values
    when typeof = 'array' or typeof LIKE '%[]' then
      return render_template(template, json_build_object('values', input));
    -- json object
    when typeof in ('json', 'jsob') then
      -- if the json object is an array, wrap it in a 'rows' object
      if json_typeof(input::json) = 'array' then
        return render_template(template, json_build_object('rows', input));
      -- otherwise, just pass the object as is
      else
        return render_template(template, input);
      end if;
    -- the query result is something else
    else
      raise exception 'unsupported input parameter type: %', typeof;
  end case;
end;
$$ language plpgsql stable;
