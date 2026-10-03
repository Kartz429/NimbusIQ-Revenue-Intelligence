with source as (

    select * from {{ source('raw', 'feature_usage') }}

),

renamed as (

    select
        feature_id,
        customer_id,
        feature_name,
        try_to_number(usage_count::varchar) as usage_count,
        try_to_date(usage_date::varchar) as usage_date
    from source

)

select * from renamed
