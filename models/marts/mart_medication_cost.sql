{{ config(
    materialized='table',
    schema='gold'
) }}

with medications as (
    select * from {{ ref('stg_medications') }}
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
        end                         as gender_display,
        state
    from {{ ref('stg_patients') }}
),

med_summary as (
    select
        m.patient_id,
        m.medication_code,
        m.medication_name,
        m.status,
        m.is_active,
        count(m.medication_id)                      as prescription_count,
        count(case when m.is_active then 1 end)     as active_prescriptions,
        p.age_group,
        p.gender_display,
        p.state
    from medications m
    left join patients p
        on m.patient_id = p.patient_id
    group by 1,2,3,4,5,8,9,10
),

top_meds as (
    select
        medication_name,
        medication_code,
        sum(prescription_count)                     as total_prescriptions,
        sum(active_prescriptions)                   as total_active,
        count(distinct patient_id)                  as patients_prescribed,
        round(sum(active_prescriptions) * 100.0
              / nullif(sum(prescription_count), 0), 2) as active_rate_pct,
        rank() over (
            order by sum(prescription_count) desc
        )                                           as prescription_rank
    from med_summary
    group by 1, 2
)

select * from top_meds
order by prescription_rank