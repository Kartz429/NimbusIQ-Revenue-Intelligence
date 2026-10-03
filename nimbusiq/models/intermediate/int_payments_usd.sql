{#- Normalises every payment to USD using the currency_rates seed. -#}
with payments as (

    select * from {{ ref('stg_payments') }}

),

rates as (

    select * from {{ ref('currency_rates') }}

),

converted as (

    select
        payments.payment_id,
        payments.customer_id,
        payments.amount,
        payments.currency,
        payments.payment_method,
        payments.payment_date,
        rates.usd_rate,
        round(payments.amount * rates.usd_rate, 2) as amount_usd
    from payments
    left join rates
        on payments.currency = rates.currency

)

select * from converted
