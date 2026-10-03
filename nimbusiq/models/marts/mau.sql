select count(distinct customer_id) as mau
from {{ ref('stg_events') }}
where event_time >= dateadd(day, -30, current_timestamp())
