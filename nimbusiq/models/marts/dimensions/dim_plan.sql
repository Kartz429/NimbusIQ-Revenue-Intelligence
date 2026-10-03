select distinct
    plan_name,
    monthly_price
from {{ ref('stg_subscriptions') }}
