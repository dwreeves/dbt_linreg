with

expected as (

  select 'a' as gb_var, 'const' as variable_name, -0.06563066041472207 as coefficient, 0.053945103940799474 as standard_error, -1.2166194078844779 as t_statistic
  union all
  select 'a' as gb_var, 'x1' as variable_name, 0.9905419281557593 as coefficient, 0.015209571618398615 as standard_error, 65.12622136954383 as t_statistic
  union all
  select 'a' as gb_var, 'x2' as variable_name, 4.948221700496285 as coefficient, 0.02906881854690807 as standard_error, 170.2243829590593 as t_statistic
  union all
  select 'a' as gb_var, 'x3' as variable_name, 0.031234030051974747 as coefficient, 0.014337008978330493 as standard_error, 2.178559705108859 as t_statistic
  union all
  select 'b' as gb_var, 'const' as variable_name, 2.0117130483709955 as coefficient, 0.035587045398501334 as standard_error, 56.529364150464545 as t_statistic
  union all
  select 'b' as gb_var, 'x1' as variable_name, 2.996331112245573 as coefficient, 0.006731681784764358 as standard_error, 445.1088462064698 as t_statistic
  union all
  select 'b' as gb_var, 'x2' as variable_name, 9.019683491736044 as coefficient, 0.008744674914389008 as standard_error, 1031.4486907791759 as t_statistic
  union all
  select 'b' as gb_var, 'x3' as variable_name, 0.016151316166848173 as coefficient, 0.0072206704541224525 as standard_error, 2.2368166875178472 as t_statistic

)

select
  coalesce(base.variable_name, expected.variable_name) as variable_name,
  expected.coefficient as expected_coefficient,
  base.coefficient as actual_coefficient,
  expected.standard_error as expected_standard_error,
  base.standard_error as actual_standard_error,
  expected.t_statistic as expected_t_statistic,
  base.t_statistic as actual_t_statistic
from {{ ref('groups_matrix_regression_chol_unoptimized') }} as base
full outer join expected
on
  base.gb_var = expected.gb_var
  and base.variable_name = expected.variable_name
where
  abs(base.coefficient - expected.coefficient) > {{ var("_test_precision_collinear_matrix") }}
  or abs(base.standard_error - expected.standard_error) > {{ var("_test_precision_collinear_matrix") }}
  or abs(base.t_statistic - expected.t_statistic) > {{ var("_test_precision_collinear_matrix") }}
  or base.coefficient is null
  or base.standard_error is null
  or base.t_statistic is null
  or expected.coefficient is null
