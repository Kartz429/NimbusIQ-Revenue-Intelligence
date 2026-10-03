with source as (

    select * from {{ source('raw', 'subscriptions') }}

),

renamed as (

    select
        subscription_id,
        customer_id,
        plan_name,
        try_to_decimal(monthly_price::varchar, 10, 2) as monthly_price,
        upper(trim(status)) as status,
        try_to_date(start_date::varchar) as start_date,
        try_to_date(end_date::varchar) as end_date
    from source

)

select * from renamed
