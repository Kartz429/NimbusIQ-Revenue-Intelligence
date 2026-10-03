select
    count(case when status = 'CANCELLED' then 1 end) * 100.0
    / nullif(count(*), 0) as churn_rate
from {{ ref('stg_subscriptions') }}
