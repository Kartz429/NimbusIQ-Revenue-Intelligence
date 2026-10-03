select
    customer_id,
    max(event_time) as last_activity_date,
    count(*) as total_events,
    count(distinct cast(event_time as date)) as active_days
from {{ ref('stg_events') }}
group by customer_id
