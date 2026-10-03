select
    customer_id,
    count(payment_id) as total_payments,
    sum(amount_usd) as total_revenue,
    avg(amount_usd) as avg_payment_value
from {{ ref('int_payments_usd') }}
group by customer_id
