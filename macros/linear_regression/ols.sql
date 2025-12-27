{% macro ols(table,
             endog=none,
             exog=none,
             x=none,
             y=none,
             weights=none,
             add_constant=true,
             output='wide',
             output_options=none,
             format=none,
             format_options=none,
             group_by=none,
             alpha=none,
             method=none,
             method_options=none) -%}

  {#############################################################################

    This function does 3 things:

    1. Resolves and casts polymorphic inputs.
    1. Validates inputs.
    2. Dispatches the appropriate call.

    The actual calculations occur elsewhere in the code, depending on the
    implementation chosen.

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

  {% if format_options is not none and output_options is not none %}
    {{ exceptions.raise_compiler_error(
      "`format_options` is deprecated and is another name for `output_options`."
      " Please only set the `output_options`."
    ) }}
  {% endif %}


  {% if format is not none and output is not none %}
    {{ exceptions.raise_compiler_error(
      "`format` is deprecated and is another name for `output`."
      " Please only set the `output`."
    ) }}
  {% elif format is not none and output is none %}
    {% set output = format %}
  {% endif %}

  {% if output_options is none %}
    {% if format_options is not none %}
      {% set output_options = format_options %}
    {% else %}
      {% set output_options = {} %}
    {% endif %}
  {% endif %}

  {% if method_options is none %}
    {% set method_options = {} %}
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
  {% elif exog is string %}
    {% set exog = [exog] %}
  {% endif %}

  {% if group_by is not iterable %}
    {% if group_by is none %}
      {% set group_by = [] %}
    {% else %}
      {% set group_by = [group_by] %}
    {% endif %}
  {% elif group_by is string %}
    {% set group_by = [group_by] %}
  {% endif %}

  {% if alpha is not iterable and alpha is not none %}
    {% set alpha = [alpha] * (exog | length) %}
  {% endif %}

  {% if method is none %}
    {% set method = 'chol' %}
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

  {% if not exog and not add_constant %}
    {{ exceptions.raise_compiler_error(
      "Cannot run dbt_linreg.ols() because there are no exogenous variables"
       " / features to regress!"
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

  {% if format is not none and format not in ['wide', 'long'] %}
      {{ exceptions.raise_compiler_error(
        "Format must be either 'wide' or 'long'; received " ~ output ~ "."
        " Also, `format=` is deprecated; it is suggested you use `output=` instead."
      ) }}
  {% endif %}

  {% if output not in ['wide', 'long'] %}
      {{ exceptions.raise_compiler_error(
        "Output must be either 'wide' or 'long'; received " ~ output ~ "."
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

  {% if method == 'chol' %}
    {{ return(
      dbt_linreg._ols_chol(
        table=table,
        endog=endog,
        exog=exog,
        weights=weights,
        add_constant=add_constant,
        output=output,
        output_options=output_options,
        group_by=group_by,
        alpha=alpha,
        method_options=method_options
      )
    ) }}
  {% elif method == 'fwl' %}
    {{ return(
      dbt_linreg._ols_fwl(
        table=table,
        endog=endog,
        exog=exog,
        weights=weights,
        add_constant=add_constant,
        output=output,
        output_options=output_options,
        group_by=group_by,
        alpha=alpha,
        method_options=method_options
      )
    ) }}
  {% else %}
    {{ exceptions.raise_compiler_error(
      "Invalid method specified. The only valid methods are 'chol' and 'fwl'"
    ) }}
  {% endif %}

{% endmacro %}
