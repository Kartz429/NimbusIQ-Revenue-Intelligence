-- Revenue per customer in the fact table must sum to the payment ledger (USD).
with fact as (

    select sum(total_revenue) as fact_total from {{ ref('fact_revenue') }}

),

ledger as (

    select sum(amount_usd) as ledger_total from {{ ref('int_payments_usd') }}

)

select fact.fact_total, ledger.ledger_total
from fact
cross join ledger
where abs(fact.fact_total - ledger.ledger_total) > 0.01
