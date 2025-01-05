/* Ridge regression coefficients do not match exactly.
   Instead, a threshold of no more than 0.01% deviation is enforced. */
{% set THRESHOLD = 0.0001 %}
with

expected as (

  select 'a' as gb_var, 'const' as variable_name, -0.06563066041472207 as coefficient
  union all
  select 'a' as gb_var, 'x1' as variable_name, 0.9905419281557593 as coefficient
  union all
  select 'a' as gb_var, 'x2' as variable_name, 4.948221700496285 as coefficient
  union all
  select 'a' as gb_var, 'x3' as variable_name, 0.031234030051974747 as coefficient
  union all
  select 'b' as gb_var, 'const' as variable_name, 2.0117130483709955 as coefficient
  union all
  select 'b' as gb_var, 'x1' as variable_name, 2.996331112245573 as coefficient
  union all
  select 'b' as gb_var, 'x2' as variable_name, 9.019683491736044 as coefficient
  union all
  select 'b' as gb_var, 'x3' as variable_name, 0.016151316166848173 as coefficient

)

select
  coalesce(base.variable_name, expected.variable_name) as variable_name,
  expected.coefficient as expected_coefficient,
  base.coefficient as actual_coefficient
from {{ ref('groups_matrix_regression_fwl') }} as base
full outer join expected
on
  base.gb_var = expected.gb_var
  and base.variable_name = expected.variable_name
where
  {% if target.name == "clickhouse" %}
  {# This has poor precision for Clickhouse; not much I can do about it. #}
  abs(base.coefficient - expected.coefficient) > 0.1
  {% else %}
  abs(base.coefficient - expected.coefficient) > {{ THRESHOLD }}
  {% endif %}
  or base.coefficient is null
  or expected.coefficient is null
