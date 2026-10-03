with source as (

    select * from {{ source('raw', 'customers') }}

),

renamed as (

    select
        customer_id,
        upper(trim(country)) as country,
        lower(trim(email)) as email,
        industry,
        try_to_number(company_size::varchar) as company_size,
        try_to_date(signup_date::varchar) as signup_date
    from source

)

select * from renamed
