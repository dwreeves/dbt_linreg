{{
  config(
    materialized="table",
    tags=["perftest"]
  )
}}
{#{%- set exog_aliased = ['x1', 'x2', 'x3', 'x4'] %}#}
{%- set exog_aliased = ['x1', 'x2', 'x3', 'x4', 'x5', 'x6', 'x7', 'x8', 'x9'] %}
with base as (

  select
    y,
    1 as x0,
    xa as x1,
    xb as x2,
    xc as x3,
    xd as x4,
    xe as x5,
    xf as x6,
    xg as x7,
    xh as x8,
    xi as x9,
    xj as x10
  from {{ ref('simple_matrix') }}

),

xtx as (

  select
    {%- for i, j in modules.itertools.combinations_with_replacement(range(exog_aliased|length), 2) %}
    sum(x{{ i }} * x{{ j }}) as x{{ i }}x{{ j }}
    {%- if not loop.last -%}
    ,
    {%- endif %}
    {%- endfor %}
  from base

),

chol as (

  select
    {%- set d = {} %}
    {%- for i in range((exog_aliased | length)) %}
    {%- for j in range(i + 1) %}
    {%- if i == 0 and j == 0 %}
    {%- do d.update({(0, 0): 'sqrt(x0x0)'}) %}
    {%- else %}
    {%- set ns = namespace() %}
    {%- set ns.s = 'x'~j~'x'~i %}
    {%- for k in range(j) %}
    {%- set ns.s = ns.s~'-i'~i~'j'~k~'*i'~j~'j'~k %}
{#-    {%- set ns.s = ns.s~'-'~d[(i,k)]~'*'~d[(j,k)] %}#}
    {%- endfor %}
    {%- if i == j %}
    {%- do d.update({(i, j): 'sqrt('~ns.s~')'}) %}
    {%- else %}
    {%- do d.update({(i, j): '('~ns.s~')/i'~j~'j'~j}) %}
{#-    {%- do d.update({(i, j): '('~ns.s~')/'~d[(j, j)]}) %}#}
    {%- endif %}
    {%- endif %}
    {%- endfor %}
    {%- endfor %}
    {%- for k, v in d.items() %}
    {{ v }} as {{ 'i'~k[0]~'j'~k[1] }}
    {%- if not loop.last -%}
    ,
    {%- endif %}
    {%- endfor %}
  from xtx

),

inverse_chol as (

  select
    {%- set d = {} %}
    {%- for i, j in modules.itertools.combinations_with_replacement(range((exog_aliased | length)), 2) %}
    {%- set ns = namespace() %}
    {%- if i == j %}
    {%- set ns.numerator = '1' %}
    {%- else %}
    {%- set ns.numerator = '(' %}
    {%- for k in range(i, j) %}
{#-    {%- set ns.numerator = ns.numerator~'-i'~j~'j'~k~'*'~d[(i, k)] %}#}
    {%- set ns.numerator = ns.numerator~'-i'~j~'j'~k~'*inv_i'~i~'j'~k %}
    {%- endfor %}
    {%- set ns.numerator = ns.numerator~')' %}
    {%- endif %}
    {%- do d.update({(i, j): '('~ns.numerator~'/i'~j~'j'~j~')'}) %}
    {%- endfor %}
    {%- for k, v in d.items() %}
    {{ v }} as inv_{{ 'i'~k[0]~'j'~k[1] }}
    {%- if not loop.last -%}
    ,
    {%- endif %}
    {%- endfor %}
  from chol

),

inverse_xtx as (

  select
    {%- for i, j in modules.itertools.combinations_with_replacement(range((exog_aliased | length)), 2) %}
    {%- for k in range(j, (exog_aliased | length)) %}
    inv_i{{ i }}j{{ k }} * inv_i{{ j }}j{{ k }}
    {%- if not loop.last %} + {% endif -%}
    {%- endfor %}
    as inv_x{{ i }}x{{ j }}
    {%- if not loop.last -%}
    ,
    {%- endif %}
    {%- endfor %}
  from inverse_chol

),

linreg as (

  select
    {%- for x1 in range(exog_aliased|length) %}
    sum((
    {%- for x2 in range(exog_aliased|length) %}
      {%- if x2 > x1 %}
      x{{ x2 }} * inv_x{{ x1 }}x{{ x2 }}
      {%- else %}
      x{{ x2 }} * inv_x{{ x2 }}x{{ x1 }}
      {%- endif %}
      {%- if not loop.last %} + {% endif -%}
    {%- endfor %}
    ) * y) as x{{ x1 }}_coef
    {%- if not loop.last -%}
    ,
    {%- endif %}
    {%- endfor %}
  from
    base,
    inverse_xtx

)

select * from linreg
