select sum(monthly_price) * 12 as arr
from {{ ref('fact_subscription') }}
where status = 'ACTIVE'
