{###############################################################################
## Simple univariate regression.
###############################################################################}

{% macro regress(y, x, add_constant=True) %}
  {{ return(
    adapter.dispatch('regress', 'dbt_linreg')
    (y, x, add_constant=add_constant)
  ) }}
{% endmacro %}

{% macro default__regress(y, x, add_constant=True) -%}
  {%- if add_constant -%}
  covar_pop({{ x }}, {{ y }}) / var_pop({{ x }})
  {%- else -%}
  sum({{ x }} * {{ y }}) / sum({{ x }} * {{ x }})
  {%- endif -%}
{%- endmacro %}

{% macro snowflake__regress(y, x, add_constant=True) -%}
  {%- if add_constant -%}
  regr_slope({{ x }}, {{ y }})
  {%- else -%}
  sum({{ x }} * {{ y }}) / sum({{ x }} * {{ x }})
  {%- endif -%}
{%- endmacro %}

{###############################################################################
## Final select
###############################################################################}

{# Every OLS method ends with a "_dbt_linreg_final_coefs" CTE with a common
   interface. This interface can then be transformed in a standard way using the
   final_select() macro, which formats the output for the user. #}
{% macro final_select(exog=none,
                      exog_aliased=none,
                      group_by=none,
                      add_constant=true,
                      output=none,
                      output_options=none,
                      calculate_standard_error=false) -%}
{%- if output == 'long' %}
{%- if add_constant %}
select
  {{ dbt_linreg._unalias_gb_cols(group_by, prefix='b') | indent(2) }}
  {{ dbt.string_literal(dbt_linreg._get_output_option('constant_name', output_options, 'const')) }} as {{ dbt_linreg._get_output_option('variable_column_name', output_options, 'variable_name') }},
  {{ dbt_linreg._maybe_round('x0_coef', dbt_linreg._get_output_option('round', output_options)) }} as {{ dbt_linreg._get_output_option('coefficient_column_name', output_options, 'coefficient') }}{% if calculate_standard_error %},
  {{ dbt_linreg._maybe_round('x0_stderr', dbt_linreg._get_output_option('round', output_options)) }} as {{ dbt_linreg._get_output_option('standard_error_column_name', output_options, 'standard_error') }},
  {{ dbt_linreg._maybe_round('x0_coef/x0_stderr', dbt_linreg._get_output_option('round', output_options)) }} as {{ dbt_linreg._get_output_option('t_statistic_column_name', output_options, 't_statistic') }}
  {%- endif %}
from _dbt_linreg_final_coefs as b
{%- if calculate_standard_error %}
{{ dbt_linreg._join_on_groups(group_by, 'b', '_dbt_linreg_stderrs') }}
{%- endif %}
{%- if exog_aliased %}
union all
{%- endif %}
{%- endif %}
{%- for i in exog_aliased %}
select
  {{ dbt_linreg._unalias_gb_cols(group_by, prefix='b') | indent(2) }}
  {{ dbt.string_literal(dbt_linreg._strip_quotes(exog[loop.index0], output_options)) }} as {{ dbt_linreg._get_output_option('variable_column_name', output_options, 'variable_name') }},
  {{ dbt_linreg._maybe_round(i~'_coef', dbt_linreg._get_output_option('round', output_options)) }} as {{ dbt_linreg._get_output_option('coefficient_column_name', output_options, 'coefficient') }}{% if calculate_standard_error %},
  {{ dbt_linreg._maybe_round(i~'_stderr', dbt_linreg._get_output_option('round', output_options)) }} as {{ dbt_linreg._get_output_option('standard_error_column_name', output_options, 'standard_error') }},
  {{ dbt_linreg._maybe_round(i~'_coef/'~i~'_stderr', dbt_linreg._get_output_option('round', output_options)) }} as {{ dbt_linreg._get_output_option('t_statistic_column_name', output_options, 't_statistic') }}
  {%- endif %}
from _dbt_linreg_final_coefs as b
{%- if calculate_standard_error %}
{{ dbt_linreg._join_on_groups(group_by, 'b', '_dbt_linreg_stderrs') }}
{%- endif %}
{%- if not loop.last %}
union all
{%- endif %}
{%- endfor %}
{%- elif output == 'wide' %}
select
  {%- if add_constant -%}
  {{ dbt_linreg._unalias_gb_cols(group_by) | indent(2) }}
  {{ dbt_linreg._maybe_round('x0_coef', dbt_linreg._get_output_option('round', output_options)) }} as {{ dbt_linreg._format_wide_variable_column(dbt_linreg._get_output_option('constant_name', output_options, 'const'), output_options) }}
  {%- if exog_aliased -%}
  ,
  {%- endif -%}
  {%- endif -%}
  {%- for i in exog_aliased %}
  {{ dbt_linreg._maybe_round(i~'_coef', dbt_linreg._get_output_option('round', output_options)) }} as {{ dbt_linreg._format_wide_variable_column(exog[loop.index0], output_options) }}
  {%- if not loop.last -%}
  ,
  {%- endif %}
  {%- endfor %}
from _dbt_linreg_final_coefs
{%- else %}
{#- Fallback option (which should never happen!) is to just select star. #}
select * from _dbt_linreg_final_coefs
{%- endif %}
{%- endmacro %}

{###############################################################################
## Misc.
###############################################################################}

{# Users can pass columns such as '"foo"', with the double quotes included.
   In this situation, we want to strip the double quotes when presenting
   outputs in a long format. #}
{% macro _strip_quotes(x, output_options) -%}
  {% if dbt_linreg._get_output_option('strip_quotes', output_options) | default(True) %}
    {% if x[0] == '"' and x[-1] == '"' and (x | length) > 1 %}
    {{ return(x[1:-1]) }}
    {% endif %}
  {% endif %}
  {{ return(x)}}
{%- endmacro %}

{% macro _format_wide_variable_column(x, output_options) -%}
  {% if x[0] == '"' and x[-1] == '"' and (x | length) > 1 %}
    {% set _add_quotes = True %}
    {% set x = x[1:-1] %}
  {% else %}
    {% set _add_quotes = False %}
  {% endif %}
  {% if dbt_linreg._get_output_option('variable_column_prefix', output_options) %}
    {% set x = dbt_linreg._get_output_option('variable_column_prefix', output_options) ~ x %}
  {% endif %}
  {% if dbt_linreg._get_output_option('variable_column_suffix', output_options) %}
    {% set x = x ~ dbt_linreg._get_output_option('variable_column_suffix', output_options) %}
  {% endif %}
  {% if _add_quotes %}
    {% set x = '"' ~ x ~ '"' %}
  {% endif %}
  {{ return(x)}}
{%- endmacro %}

{# To ensure no namespace conflicts, f"gb{index}" is used in group by
   statements instead of the actual column names. This macro adds aliases. #}
{% macro _alias_gb_cols(group_by) -%}
{%- if group_by %}
{%- for gb in group_by %}
{{ gb }} as gb{{ loop.index }},
{%- endfor %}
{%- endif %}
{%- endmacro %}

{# This macros reverses gb column aliases at the end of an OLS query. #}
{% macro _unalias_gb_cols(group_by, prefix=None) -%}
{%- if group_by %}
{%- for gb in group_by %}
{%- if prefix %}
{{ prefix }}.gb{{ loop.index }} as {{ gb }},
{%- else %}
gb{{ loop.index }} as {{ gb }},
{%- endif %}
{%- endfor %}
{%- endif %}
{%- endmacro %}

{# Round the final coefficient if the user specifies the `round` format
   option. Otherwise, keep as is. #}

{% macro _maybe_round(x, round_) %}
  {{ return(
    adapter.dispatch('_maybe_round', 'dbt_linreg')(x, round_)
  ) }}
{% endmacro %}

{% macro default___maybe_round(x, round_) %}
  {% if round_ is not none %}
    {{ return('round(' ~ x ~ ', ' ~ round_ ~ ')') }}
  {% else %}
    {{ return(x) }}
  {% endif %}
{% endmacro %}

{% macro postgres___maybe_round(x, round_) %}
  {% if round_ is not none %}
    {{ return('round((' ~ x ~ ')::numeric, ' ~ round_ ~ ')') }}
  {% else %}
    {{ return('(' ~ x ~ ')::numeric') }}
  {% endif %}
{% endmacro %}

{% macro redshift___maybe_round(x, round_) %}
  {% if round_ is not none %}
    {{ return('round(' ~ x ~ ', ' ~ round_ ~ ')') }}
  {% else %}
    {{ return(x) }}
  {% endif %}
{% endmacro %}

{# Alias and write group by columns in a standard way. #}
{% macro _gb_cols(group_by, trailing_comma=False, prefix=None) -%}
{%- if group_by %}
{%- for gb in group_by %}
{%- if prefix %}
{{ prefix }}.gb{{ loop.index }}
{%- else %}
gb{{ loop.index }}
{%- endif %}
{%- if (not loop.last) or trailing_comma -%}
,
{%- endif %}
{%- endfor %}
{%- endif %}
{%- endmacro %}

{# Take exog and gen a list containing 'x1', 'x2', etc. #}
{% macro _alias_exog(x) -%}
{% set li = [] %}
{% for i in x %}
  {% do li.append('x' ~ loop.index) %}
{% endfor %}
{{ return(li) }}
{%- endmacro %}

{# Join on gb1, gb2 etc. from a table to another table.
   If there is no group by column, assume `join_to` is just 1 row.
   And in that case, just do a cross join. #}
{% macro _join_on_groups(group_by, join_from, join_to) -%}
{%- if not group_by %}
cross join {{ join_to }}
{%- else %}
inner join {{ join_to }}
on
  {%- for _ in group_by %}
  {{ join_from }}.gb{{ loop.index }} = {{ join_to }}.gb{{ loop.index }}
  {% if not loop.last -%}
  and
  {%- endif %}
  {%- endfor %}
{%- endif %}
{%- endmacro %}

{% macro _get_output_option(field, output_options, default=none) %}
  {{ return(output_options.get(field, var("dbt_linreg", {}).get("output_options", {}).get(field, default))) }}
{% endmacro %}

{% macro _get_method_option(method, field, method_options, default=none) %}
  {{ return(method_options.get(field, var("dbt_linreg", {}).get("method_options", {}).get("method", {}).get(field, default))) }}
{% endmacro %}
