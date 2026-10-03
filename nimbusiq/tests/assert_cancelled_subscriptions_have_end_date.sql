{{ config(severity='warn') }}

-- Data-quality warning: cancelled subscriptions should carry an end_date.
-- The sample generator historically left end_date empty for all rows.
select subscription_id, status, end_date
from {{ ref('stg_subscriptions') }}
where status = 'CANCELLED'
    and end_date is null
