select
    customer_id,
    email,
    country,
    industry,
    company_size,
    signup_date
from {{ ref('stg_customers') }}
