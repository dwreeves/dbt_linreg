with

expected as (

  select 'x1' as variable_name, 11.392300499659957 as coefficient, 0.5240533254061608 as standard_error, 21.73881921430515 as t_statistic
  union all
  select 'x2' as variable_name, 2.333060182571783 as coefficient, 0.9201150492406911 as standard_error, 2.5356178931070636 as t_statistic
  union all
  select 'x3' as variable_name, 21.895814737788875 as coefficient, 0.44810399169425286 as standard_error, 48.8632441210849 as t_statistic
  union all
  select 'x4' as variable_name, 3.4480236159406785 as coefficient, 0.1504072830205524 as standard_error, 22.92457882820424 as t_statistic
  union all
  select 'x5' as variable_name, 15.766951731565559 as coefficient, 0.37297028350495787 as standard_error, 42.274015997727524 as t_statistic

)

select
  coalesce(base.variable_name, expected.variable_name) as variable_name,
  expected.coefficient as expected_coefficient,
  base.coefficient as actual_coefficient
from {{ ref('collinear_matrix_5var_without_const') }} as base
full outer join expected
on base.variable_name = expected.variable_name
where
  abs(base.coefficient - expected.coefficient) > {{ var("_test_precision_collinear_matrix") }}
  or abs(base.standard_error - expected.standard_error) > {{ var("_test_precision_collinear_matrix") }}
  or abs(base.t_statistic - expected.t_statistic) > {{ var("_test_precision_collinear_matrix") }}
  or base.coefficient is null
  or base.standard_error is null
  or base.t_statistic is null
  or expected.coefficient is null
