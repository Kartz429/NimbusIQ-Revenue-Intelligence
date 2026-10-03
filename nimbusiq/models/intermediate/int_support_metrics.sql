select
    customer_id,
    count(*) as total_tickets,
    count(case when status = 'Closed' then 1 end) as closed_tickets,
    count(case when status = 'Open' then 1 end) as open_tickets,
    count(case when status = 'In Progress' then 1 end) as in_progress_tickets,
    avg(datediff('hour', created_at, resolved_at)) as avg_resolution_hours
from {{ ref('stg_tickets') }}
group by customer_id
