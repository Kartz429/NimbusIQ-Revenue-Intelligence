with source as (

    select * from {{ source('raw', 'payments') }}

),

renamed as (

    select
        payment_id,
        customer_id,
        try_to_decimal(amount::varchar, 10, 2) as amount,
        payment_method,
        upper(trim(currency)) as currency,
        try_to_date(payment_date::varchar) as payment_date
    from source

)

select * from renamed
