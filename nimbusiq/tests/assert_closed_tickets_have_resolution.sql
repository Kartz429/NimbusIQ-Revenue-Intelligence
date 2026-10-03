-- Closed tickets must have a resolution timestamp.
select ticket_id, status, resolved_at
from {{ ref('stg_tickets') }}
where status = 'Closed'
    and resolved_at is null
