{#-
    Drops every schema that belongs to one CI run:
        dbt run-operation drop_ci_schemas --args '{schema_prefix: CI_PR_42}'

    Guard rail: the prefix must start with CI_, so this can never touch
    RAW / STAGING / INTERMEDIATE / ANALYTICS / SNAPSHOTS.
-#}
{% macro drop_ci_schemas(schema_prefix) %}
    {% set prefix = schema_prefix | upper %}
    {% if not prefix.startswith('CI_') %}
        {{ exceptions.raise_compiler_error("Refusing to drop schemas: prefix must start with CI_ (got '" ~ prefix ~ "')") }}
    {% endif %}

    {% set find_schemas %}
        select schema_name
        from {{ target.database }}.information_schema.schemata
        where schema_name like '{{ prefix }}%'
    {% endset %}

    {% if execute %}
        {% set results = run_query(find_schemas) %}
        {% for row in results.rows %}
            {% do log('Dropping CI schema ' ~ target.database ~ '.' ~ row[0], info=True) %}
            {% do run_query('drop schema if exists ' ~ target.database ~ '.' ~ row[0] ~ ' cascade') %}
        {% endfor %}
    {% endif %}
{% endmacro %}
