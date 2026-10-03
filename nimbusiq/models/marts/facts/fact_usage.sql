select
    customer_id,
    total_events,
    last_activity_date as last_activity
from {{ ref('int_customer_activity') }}
