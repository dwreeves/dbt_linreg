{% macro ols(table,
             endog=None,
             exog=None,
             x=None,
             y=None,
             format='wide',
             format_options=None,
             group_by=None,
             alpha=None,
             method='fwl') -%}

  {#############################################################################

    This function does 3 things:

    1. Resolves and casts polymorphic inputs.
    1. Validates inputs.
    2. Dispatches the appropriate call.

    The actual calculations occur elsewhere in the code, depending on the
    implementation chosen. (At the moment, the only implementation method
    supported is method='fwl'.)

  #############################################################################}

  {# Format the variables, and cast strings to lists #}
  {# ----------------------------------------------- #}

  {% if x is not none and exog is none %}
    {% set exog = x %}
  {% elif x is not none and exog is not none %}
    {{ exceptions.raise_compiler_error(
      "Please specify either `exog` (preferred) or `x`, not both."
      " `x` is just an alias for `exog`."
    ) }}
  {% endif %}

  {% if format_options is none %}
    {% set format_options = {} %}
  {% endif %}

  {% if y is not none and endog is none %}
    {% set endog = y %}
  {% elif y is not none and endog is not none %}
    {{ exceptions.raise_compiler_error(
      "Please specify either `endog` (preferred) or `y`, not both."
      " `y` is just an alias for `endog`."
    ) }}
  {% endif %}

  {% if exog is not iterable %}
    {% if exog is none %}
      {% set exog = [] %}
    {% else %}
      {% set exog = [exog] %}
    {% endif %}
  {% endif %}

  {% if group_by is not iterable %}
    {% if group_by is none %}
      {% set group_by = [] %}
    {% else %}
      {% set group_by = [group_by] %}
    {% endif %}
  {% endif %}

  {% if alpha is not iterable and alpha is not none %}
    {% set alpha = [alpha] * (exog | length) %}
  {% endif %}

  {# Check for user input errors #}
  {# --------------------------- #}

  {% if endog is none %}
    {{ exceptions.raise_compiler_error(
      "`endog` is not allowed to be None."
      " Please specify a target variable / y-variable / endogenous variable for"
      " the linear regression."
    ) }}
  {% endif %}

  {% for i in range((exog | length)) %}
    {% for j in range(i, (exog | length)) %}
      {% if i != j %}
        {% if exog[i] == exog[j] %}
          {% if not alpha %}
            {{ exceptions.raise_compiler_error(
              "Duplicate variables are not allowed without regularization, as"
              " that will lead to multicollinearity. Duplicate variable is: "
              ~ exog[i] ~ ", which occurs at positions " ~ i ~ " and " ~ j ~ "."
            ) }}
          {% else %}
            {% do log(
              "Note: exog variable " ~ exog[i] ~ " is duplicated at positions "
              ~ i ~ " and " ~ j ~ "."
             ) %}
          {% endif %}
        {% endif %}
      {% endif %}
    {% endfor %}
  {% endfor %}

  {% if format not in ['wide', 'long'] %}
      {{ exceptions.raise_compiler_error(
        "Format must be either 'wide' or 'long'; received " ~ format ~ "."
      ) }}
  {% endif %}

  {% if alpha is not none and (alpha | length) != (exog | length) %}
      {{ exceptions.raise_compiler_error(
        "The number of values passed in `alpha` must be equivalent to"
        " the number of columns in `exog`."
        " Received " ~ (exog | length) ~ " exog variables and " ~ (alpha | length) ~
        " alpha parameters."
        " Note that the constant term cannot be penalized."
      ) }}
  {% endif %}

  {% if method == 'fwl' %}
    {{ return(
      dbt_linreg._ols_fwl(
        table=table,
        endog=endog,
        exog=exog,
        format=format,
        format_options=format_options,
        group_by=group_by,
        alpha=alpha
      )
    ) }}
  {% else %}
    {{ exceptions.raise_compiler_error(
      "Invalid method specified. The only currently valid method is 'fwl'"
    ) }}
  {% endif %}

{% endmacro %}
