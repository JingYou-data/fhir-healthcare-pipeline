{{ config(
    materialized='table',
    schema='silver'
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
        end                         as gender_display
    from {{ ref('stg_patients') }}
),


-- PDC (Proportion of Days Covered) >= 80% = adherent
med_per_patient as (
    select
        m.patient_id,
        count(m.medication_id)                      as total_prescriptions,
        count(case when m.is_active then 1 end)     as active_prescriptions,
        count(distinct m.medication_code)           as unique_medications,
        count(case when m.status = 'stopped' 
              then 1 end)                           as stopped_prescriptions,
        round(
            count(case when m.is_active then 1 end) * 100.0
            / nullif(count(m.medication_id), 0)
        , 2)                                        as active_rate_pct,
        case
            when round(
                count(case when m.is_active then 1 end) * 100.0
                / nullif(count(m.medication_id), 0)
            , 2) >= 80 then true
            else false
        end                                         as is_adherent
    from medications m
    group by 1
),

final as (
    select
        mp.patient_id,
        mp.total_prescriptions,
        mp.active_prescriptions,
        mp.unique_medications,
        mp.stopped_prescriptions,
        mp.active_rate_pct,
        mp.is_adherent,
        p.age_group,
        p.gender_display
    from med_per_patient mp
    left join patients p
        on mp.patient_id = p.patient_id
)

select * from final