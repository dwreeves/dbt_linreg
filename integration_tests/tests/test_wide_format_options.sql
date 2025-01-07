with base as (

  select
    fooconstant_term_bar,
    "fooxa_bar",
    fooxb_bar
  from
    {{ ref("wide_output_options") }}

)

/* If this SQL query doesn't throw an error, it's all set. */
select * from base where false
