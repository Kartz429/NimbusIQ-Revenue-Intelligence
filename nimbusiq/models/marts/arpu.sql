select
    sum(amount_usd) / nullif(count(distinct customer_id), 0) as arpu
from {{ ref('int_payments_usd') }}
