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
      raise exception 'error in render_template function: %', sqlerrm;
  end;
  return result_text;
end;
$$ language plpgsql stable;

-- main render function
create or replace function render(template text, input anyelement)
returns text as $$
declare
  typeof regtype := pg_typeof(input)::regtype;
  json_types regtype[] := array['json'::regtype, 'jsonb'::regtype];
  -- single value types
  text_types regtype[] := array['text'::regtype, 'varchar'::regtype, 'char'::regtype];
  numeric_types regtype[] := array['integer'::regtype, 'double precision'::regtype, 'real'::regtype, 'numeric'::regtype, 'smallint'::regtype, 'bigint'::regtype];
  time_types regtype[] := array['time'::regtype, 'timestamp'::regtype, 'timestamptz'::regtype, 'interval'::regtype, 'date'::regtype];
  other_types regtype[] := array['bool'::regtype, 'uuid'::regtype, 'inet'::regtype];
begin
  case
    -- single value
    when typeof = any(text_types || numeric_types || time_types || other_types) then
      return render_template(template, json_build_object('value', input));
    -- array of values
    when typeof::text = 'array' or typeof::text LIKE '%[]' then
      return render_template(template, json_build_object('values', input));
    -- json object
    when typeof = any(json_types) then
      -- if the json object is an array, wrap it in a 'rows' object
      if json_typeof(input::json) = 'array' then
        return render_template(template, json_build_object('rows', input));
      -- otherwise, just pass the object as json
      else
        return render_template(template, input::json);
      end if;
    -- the input type is not supported
    else
      raise exception 'unsupported input parameter type: %', typeof;
  end case;
end;
$$ language plpgsql stable;

create or replace function render_agg_sfunc(state text, template text, input anyelement)
returns text language plpgsql as $$
declare
  typeof regtype := pg_typeof(input)::regtype;
  json_input json;
  json_types regtype[] := array['json'::regtype, 'jsonb'::regtype];
  -- single value types
  text_types regtype[] := array['text'::regtype, 'varchar'::regtype, 'char'::regtype];
  numeric_types regtype[] := array['integer'::regtype, 'double precision'::regtype, 'real'::regtype, 'numeric'::regtype, 'smallint'::regtype, 'bigint'::regtype];
  time_types regtype[] := array['time'::regtype, 'timestamp'::regtype, 'timestamptz'::regtype, 'interval'::regtype, 'date'::regtype];
  other_types regtype[] := array['bool'::regtype, 'uuid'::regtype, 'inet'::regtype];
begin
  if typeof = any(json_types) then
    json_input := input;
  elsif typeof = any(text_types || numeric_types || time_types || other_types) then
    json_input := json_build_object('value', input);
  elsif typeof::text = 'array' or typeof::text LIKE '%[]' then
    json_input := json_build_object('values', input);
  else
  -- convert record to json if it's not already json
    json_input := row_to_json(input);
  end if;
  -- render the template to state
  return coalesce(state, '') || render(template, json_input);
end $$;

create or replace function render_agg_final(state text)
returns text language plpgsql as $$
begin
  return coalesce(state, '');
end $$;

create aggregate render_agg(text, anyelement) (
  sfunc = render_agg_sfunc,
  stype = text,
  finalfunc = render_agg_final,
  initcond = ''
);
