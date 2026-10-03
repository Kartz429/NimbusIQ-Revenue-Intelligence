select
    subscription_id,
    customer_id,
    plan_name,
    monthly_price,
    status,
    start_date,
    end_date
from {{ ref('stg_subscriptions') }}
