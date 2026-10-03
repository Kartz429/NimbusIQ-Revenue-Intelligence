with source as (

    select * from {{ source('raw', 'events') }}

),

renamed as (

    select
        event_id,
        customer_id,
        event_type,
        try_to_timestamp_ntz(event_time::varchar) as event_time
    from source

)

select * from renamed
