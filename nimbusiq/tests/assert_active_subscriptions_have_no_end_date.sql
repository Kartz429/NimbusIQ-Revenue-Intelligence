-- ACTIVE subscriptions must not have ended.
select subscription_id, status, end_date
from {{ ref('stg_subscriptions') }}
where status = 'ACTIVE'
    and end_date is not null
