{{
    config(
        materialized='incremental',
        unique_key='event_id',
        incremental_strategy='merge',
        on_schema_change='append_new_columns'
    )
}}

{#-
    Insert events whose IDs are not in the target yet. Filtering on event_id
    (not on a high-water-mark event_time) means late-arriving events with an
    old event_time are still picked up. Rebuild from scratch with:
        dbt run --full-refresh --select int_events_incremental
-#}
select source_events.*
from {{ ref('stg_events') }} as source_events

{% if is_incremental() %}

where not exists (
    select 1
    from {{ this }} as loaded_events
    where loaded_events.event_id = source_events.event_id
)

{% endif %}
