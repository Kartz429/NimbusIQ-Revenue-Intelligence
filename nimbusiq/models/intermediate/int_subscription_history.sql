select
    subscription_id,
    customer_id,
    plan_name,
    monthly_price,
    status,
    start_date,
    end_date,
    case
        when status = 'CANCELLED' then 'CHURNED'
        when status = 'ACTIVE' then 'ACTIVE'
        when status = 'PAUSED' then 'PAUSED'
        else 'UNKNOWN'
    end as lifecycle_status
from {{ ref('stg_subscriptions') }}
