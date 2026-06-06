{{ config(
    materialized='table',
    schema='gold'
) }}

with patients as (
    select * from {{ ref('stg_patients') }}
),

summary as (
    select
        patient_id,
        first_name,
        last_name,
        birth_date,
        gender,
        city,
        state,
        postal_code,
        age_years,
        case
            when age_years < 18  then '0-17'
            when age_years < 35  then '18-34'
            when age_years < 50  then '35-49'
            when age_years < 65  then '50-64'
            else '65+'
        end                         as age_group,
        case
            when gender = 'male'   then 'Male'
            when gender = 'female' then 'Female'
            else 'Other'
        end                         as gender_display,
        _loaded_at
    from patients
)

select * from summary