select
    (
        sum(monthly_price)
        * (1 + {{ var('nrr_expansion_rate') }} - {{ var('nrr_contraction_rate') }})
        / nullif(sum(monthly_price), 0)
    ) * 100 as nrr
from {{ ref('stg_subscriptions') }}
where status = 'ACTIVE'
