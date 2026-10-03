select count(distinct customer_id) as dau
from {{ ref('stg_events') }}
where cast(event_time as date) = current_date
