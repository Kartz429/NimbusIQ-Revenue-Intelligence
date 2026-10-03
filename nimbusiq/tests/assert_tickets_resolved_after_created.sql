-- A ticket cannot be resolved before it was created.
select ticket_id, created_at, resolved_at
from {{ ref('stg_tickets') }}
where resolved_at is not null
    and resolved_at < created_at
