use pgrx::prelude::*;
use liquid;

pgrx::pg_module_magic!();

// We return a static str because we know it's returned to Postgres-land and lifetime is not an issue in Rust anymore.
// The input is a ref to Postgres memory location. When we return a String, it gets converted to Postgres text type again in pgrx.

#[pg_extern]
fn pg_render_liquid(template_code: &str, data: pgrx::Json) -> String {
    // Panic causes Postgres ERROR, so we can just unwrap here.
    // Will cancel the query, not crash the postgres process.
    let template = liquid::ParserBuilder::with_stdlib()
        .build().unwrap()
        .parse(template_code).unwrap();
    let input = liquid::to_object(&data).unwrap();
    let output = template.render(&input).unwrap();
    return output;
}

use pgrx::extension_sql_file;
extension_sql_file!(
    "../sql/pg_render.sql",
);
