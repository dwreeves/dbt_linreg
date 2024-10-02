{{ config(enabled=False) }}
with

expected as (

  select 'const' as variable_name, 78.32986168327125 as coefficient, 2.2478951158027343 as standard_error, 34.84587031334835 as t_statistic
  union all
  select 'x1' as variable_name, 9.690057328206695 as coefficient, 0.5903103592025547 as standard_error, 16.41519105525594 as t_statistic
  union all
  select 'x2' as variable_name, 6.5995521027081505 as coefficient, 1.1251104763856294 as standard_error, 5.865692517510758 as t_statistic
  union all
  select 'x3' as variable_name, 19.439295801040092 as coefficient, 0.5784265337086496 as standard_error, 33.60719930395096 as t_statistic
  union all
  select 'x4' as variable_name, 3.786031479906997 as coefficient, 0.16143609506528953 as standard_error, 23.452199326153263 as t_statistic

)

select base.variable_name
from {{ ref('collinear_matrix_weights_fwl') }} as base
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
