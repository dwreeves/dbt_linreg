/* Ridge regression coefficients do not match exactly.
   Instead, a threshold of no more than 0.01% deviation is enforced. */
{% set THRESHOLD = 0.0001 %}
with

expected as (

  select 'const' as variable_name, 20.7548151107157 as coefficient
  union all
  select 'x1' as variable_name, 9.784064449021356 as coefficient
  union all
  select 'x2' as variable_name, 6.315640539781496 as coefficient
  union all
  select 'x3' as variable_name, 19.578696589513562 as coefficient
  union all
  select 'x4' as variable_name, 3.736823845978248 as coefficient
  union all
  select 'x5' as variable_name, 13.323547772767592 as coefficient

)

select
  coalesce(base.variable_name, expected.variable_name) as variable_name,
  expected.coefficient as expected_coefficient,
  base.coefficient as actual_coefficient
from {{ ref('collinear_matrix_ridge_regression_chol_unoptimized') }} as base
full outer join expected
on base.variable_name = expected.variable_name
where
  abs(log(abs(base.coefficient)) - log(abs(expected.coefficient))) > {{ THRESHOLD }}
  or sign(base.coefficient) != sign(expected.coefficient)
  or base.coefficient is null
