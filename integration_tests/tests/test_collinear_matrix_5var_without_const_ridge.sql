/* Ridge regression coefficients do not match exactly.
   Instead, a threshold of no more than 0.01% deviation is enforced. */
{% set THRESHOLD = 0.0001 %}
with

expected as (

  select 'x1' as variable_name, 9.44760329057758 as coefficient
  union all
  select 'x2' as variable_name, 3.5049555562844787 as coefficient
  union all
  select 'x3' as variable_name, 20.753357497835637 as coefficient
  union all
  select 'x4' as variable_name, 3.522584853991104 as coefficient
  union all
  select 'x5' as variable_name, 16.31725550368597 as coefficient

)

select
  coalesce(base.variable_name, expected.variable_name) as variable_name,
  expected.coefficient as expected_coefficient,
  base.coefficient as actual_coefficient
from {{ ref('collinear_matrix_5var_without_const_ridge') }} as base
full outer join expected
on base.variable_name = expected.variable_name
where
  abs(log(abs(base.coefficient)) - log(abs(expected.coefficient))) > {{ THRESHOLD }}
  or sign(base.coefficient) != sign(expected.coefficient)
  or base.coefficient is null
