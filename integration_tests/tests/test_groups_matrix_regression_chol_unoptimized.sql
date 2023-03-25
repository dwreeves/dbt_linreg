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

select base.variable_name
from {{ ref('groups_matrix_regression_chol_unoptimized') }} as base
full outer join expected
on
  base.gb_var = expected.gb_var
  and base.variable_name = expected.variable_name
where
  round(base.coefficient, 7) - round(expected.coefficient, 7)
  or base.coefficient is null
