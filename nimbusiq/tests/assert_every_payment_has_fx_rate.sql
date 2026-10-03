-- Fails if a payment currency has no row in the currency_rates seed.
select payment_id, currency
from {{ ref('int_payments_usd') }}
where amount_usd is null
