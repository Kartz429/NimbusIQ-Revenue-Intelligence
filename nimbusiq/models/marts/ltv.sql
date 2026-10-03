with arpu as (

    select arpu from {{ ref('arpu') }}

)

select arpu * {{ var('ltv_lifetime_months') }} as estimated_ltv
from arpu
