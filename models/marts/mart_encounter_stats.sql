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
        first_name,
        last_name,
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
        city,
        state
    from {{ ref('stg_patients') }}
),

stats as (
    select
        e.patient_id,
        p.first_name,
        p.last_name,
        p.age_years,
        p.age_group,
        p.gender_display,
        p.city,
        p.state,
        count(e.encounter_id)                       as total_encounters,
        count(case when e.encounter_class = 'ambulatory'
              then 1 end)                           as ambulatory_count,
        count(case when e.encounter_class = 'emergency'
              then 1 end)                           as emergency_count,
        count(case when e.encounter_class = 'inpatient'
              then 1 end)                           as inpatient_count,
        avg(e.duration_minutes)                     as avg_duration_minutes,
        min(e.encounter_start)                      as first_encounter,
        max(e.encounter_start)                      as last_encounter
    from encounters e
    left join patients p
        on e.patient_id = p.patient_id
    group by 1,2,3,4,5,6,7,8
)

select * from stats