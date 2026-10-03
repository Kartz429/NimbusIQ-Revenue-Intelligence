{#-
    SCD Type 2 history of subscription plan and status.
    prod writes to SNAPSHOTS (history preserved across runs); dev and CI write to
    <target.schema>_SNAPSHOTS so they never touch production history.
-#}
{% snapshot subscription_snapshot %}

{{
    config(
        target_schema=('SNAPSHOTS' if target.name == 'prod' else target.schema ~ '_SNAPSHOTS'),
        unique_key='subscription_id',
        strategy='check',
        check_cols=['plan_name', 'status'],
        invalidate_hard_deletes=True
    )
}}

select * from {{ ref('stg_subscriptions') }}

{% endsnapshot %}
