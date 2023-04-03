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

select base.variable_name
from {{ ref('collinear_matrix_5var_without_const') }} as base
full outer join expected
on base.variable_name = expected.variable_name
where
  round(base.coefficient, 7) != round(expected.coefficient, 7)
  or round(base.standard_error, 7) != round(expected.standard_error, 7)
  or round(base.t_statistic, 7) != round(expected.t_statistic, 7)
  or base.coefficient is null
  or base.standard_error is null
  or base.t_statistic is null
  or expected.coefficient is null
