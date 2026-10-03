select sum(monthly_price) as mrr
from {{ ref('fact_subscription') }}
where status = 'ACTIVE'
