select
    customer_id,
    total_revenue,
    total_payments as payment_count,
    avg_payment_value as avg_payment
from {{ ref('int_customer_revenue') }}
