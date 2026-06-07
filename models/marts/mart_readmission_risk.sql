{{ config(
    materialized='table',
    schema='gold'
) }}

with readmissions as (
    select * from {{ ref('int_readmission_windows') }}
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
        state
    from {{ ref('stg_patients') }}
),

patient_readmission_summary as (
    select
        r.patient_id,
        p.first_name,
        p.last_name,
        p.age_years,
        p.age_group,
        p.gender_display,
        p.state,
        count(r.index_encounter_id)                 as total_index_encounters,
        sum(case when r.is_readmitted_30d 
            then 1 else 0 end)                      as readmission_count,
        round(
            sum(case when r.is_readmitted_30d 
                then 1 else 0 end) * 100.0
            / nullif(count(r.index_encounter_id), 0)
        , 2)                                        as readmission_rate_pct,
        avg(r.days_to_readmission)                  as avg_days_to_readmission,
        case
            when sum(case when r.is_readmitted_30d 
                then 1 else 0 end) >= 3 then 'High'
            when sum(case when r.is_readmitted_30d 
                then 1 else 0 end) >= 1 then 'Medium'
            else 'Low'
        end                                         as risk_level
    from readmissions r
    left join patients p
        on r.patient_id = p.patient_id
    group by 1,2,3,4,5,6,7
)

select * from patient_readmission_summary
order by readmission_count desc