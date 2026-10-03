-- A subscription cannot end before it starts.
select subscription_id, start_date, end_date
from {{ ref('stg_subscriptions') }}
where end_date is not null
    and end_date < start_date
