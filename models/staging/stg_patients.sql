{{ config(
    materialized='view',
    schema='silver'
) }}

with source as (
    select * from {{ source('bronze', 'patients') }}
),

renamed as (
    select
        patient_id,
        first_name,
        last_name,
        birth_date::date                          as birth_date,
        gender,
        city,
        state,
        postal_code,
        datediff('year', birth_date::date, current_date()) as age_years,
        _loaded_at
    from source
)

select * from renamed