with

base as (

  select strip_quotes, vname, co
  from {{ ref("long_format_options") }}

),

find_unstripped_quotes as (

  select
    max(vname = '"xa"') as should_be_true,
    max(vname = 'xa') as should_be_false
  from base
  where not strip_quotes

),

dodge_unstripped_quotes as (

  select
    max(vname = 'xa') as should_be_true,
    max(vname = '"xa"') as should_be_false
  from base
  where strip_quotes

),

coef_col_name as (

  select
    max(vname = 'constant_term') as should_be_true,
    max(vname = 'const') as should_be_false
  from base

)

select 'find_unstripped_quotes' as test_case
from find_unstripped_quotes
where should_be_false or not should_be_true

union all

select 'dodge_unstripped_quotes' as test_case
from dodge_unstripped_quotes
where should_be_false or not should_be_true

union all

select 'coef_col_name' as test_case
from coef_col_name
where should_be_false or not should_be_true
