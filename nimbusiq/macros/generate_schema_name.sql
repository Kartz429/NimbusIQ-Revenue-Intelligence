{#-
    Schema routing.

    prod  : the custom schema is used as-is -> STAGING / INTERMEDIATE / ANALYTICS
    other : <target.schema>_<custom schema> -> DBT_KARTIK_STAGING, CI_PR_42_ANALYTICS

    Developers and CI can therefore never write into the production schemas.
-#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- elif target.name == 'prod' -%}
        {{ custom_schema_name | trim | upper }}
    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name | trim | upper }}
    {%- endif -%}
{%- endmacro %}
