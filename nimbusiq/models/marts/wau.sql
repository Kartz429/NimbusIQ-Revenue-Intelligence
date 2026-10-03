select count(distinct customer_id) as wau
from {{ ref('stg_events') }}
where event_time >= dateadd(day, -7, current_timestamp())
