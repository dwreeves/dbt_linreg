{{ config(enabled=False) }}
/* Ridge regression coefficients do not match exactly.
   Instead, a threshold of no more than 0.01% deviation is enforced. */
{% set THRESHOLD = 0.0001 %}
with

expected as (

  select 'const' as variable_name, 93.43172535198633 as coefficient
  union all
  select 'x1' as variable_name, 5.301810664300932 as coefficient
  union all
  select 'x2' as variable_name, 8.3991554645256 as coefficient
  union all
  select 'x3' as variable_name, 17.327608839976932 as coefficient
  union all
  select 'x4' as variable_name, 4.577399536301482 as coefficient

)

select base.variable_name
from {{ ref('collinear_matrix_weights_ridge_fwl') }} as base
full outer join expected
on base.variable_name = expected.variable_name
where
  abs(log(abs(base.coefficient)) - log(abs(expected.coefficient))) > {{ THRESHOLD }}
  or sign(base.coefficient) != sign(expected.coefficient)
  or base.coefficient is null
