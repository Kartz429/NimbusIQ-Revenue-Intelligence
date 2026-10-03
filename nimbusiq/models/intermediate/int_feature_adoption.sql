select
    feature_name,
    count(distinct customer_id) as unique_users,
    sum(usage_count) as total_usage
from {{ ref('stg_feature_usage') }}
group by feature_name
