{{ config(
    materialized='table',
    schema='gold'
) }}

with encounters as (
    select * from {{ ref('stg_encounters') }}
),

patients as (
    select
        patient_id,
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
        end                         as gender_display
    from {{ ref('stg_patients') }}
),

final as (
    select
        e.encounter_class,
        e.encounter_type,
        p.age_group,
        p.gender_display,
        count(e.encounter_id)                       as total_encounters,
        avg(e.duration_minutes)                     as avg_duration_minutes,
        max(e.duration_minutes)                     as max_duration_minutes,
        count(distinct e.patient_id)                as unique_patients
    from encounters e
    left join patients p
        on e.patient_id = p.patient_id
    group by 1,2,3,4
)

select * from final
order by total_encounters desc