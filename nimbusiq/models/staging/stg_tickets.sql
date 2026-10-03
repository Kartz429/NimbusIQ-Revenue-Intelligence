with source as (

    select * from {{ source('raw', 'tickets') }}

),

renamed as (

    select
        ticket_id,
        customer_id,
        priority,
        status,
        try_to_timestamp_ntz(created_at::varchar) as created_at,
        try_to_timestamp_ntz(resolved_at::varchar) as resolved_at
    from source

)

select * from renamed
