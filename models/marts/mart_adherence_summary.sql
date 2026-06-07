{{ config(
    materialized='table',
    schema='gold'
) }}

with adherence as (
    select * from {{ ref('int_medication_adherence') }}
),

-- 整体依从率统计
overall as (
    select
        count(patient_id)                           as total_patients,
        sum(case when is_adherent then 1 else 0 end) as adherent_patients,
        round(
            sum(case when is_adherent then 1 else 0 end) * 100.0
            / nullif(count(patient_id), 0)
        , 2)                                        as overall_adherence_pct,
        avg(active_rate_pct)                        as avg_active_rate_pct,
        avg(unique_medications)                     as avg_medications_per_patient,
        avg(total_prescriptions)                    as avg_prescriptions_per_patient
    from adherence
),

-- 按年龄组统计依从率
by_age_group as (
    select
        age_group,
        count(patient_id)                           as patients_in_group,
        sum(case when is_adherent then 1 else 0 end) as adherent_count,
        round(
            sum(case when is_adherent then 1 else 0 end) * 100.0
            / nullif(count(patient_id), 0)
        , 2)                                        as adherence_pct,
        avg(active_rate_pct)                        as avg_active_rate_pct,
        avg(unique_medications)                     as avg_unique_medications
    from adherence
    group by 1
),

-- 按性别统计依从率
by_gender as (
    select
        gender_display,
        count(patient_id)                           as patients_in_group,
        sum(case when is_adherent then 1 else 0 end) as adherent_count,
        round(
            sum(case when is_adherent then 1 else 0 end) * 100.0
            / nullif(count(patient_id), 0)
        , 2)                                        as adherence_pct
    from adherence
    group by 1
)

select
    'overall'                                       as segment_type,
    'All Patients'                                  as segment_value,
    o.total_patients                                as patients_in_group,
    o.adherent_patients                             as adherent_count,
    o.overall_adherence_pct                         as adherence_pct,
    o.avg_active_rate_pct,
    o.avg_medications_per_patient                   as avg_unique_medications
from overall o

union all

select
    'age_group'                                     as segment_type,
    age_group                                       as segment_value,
    patients_in_group,
    adherent_count,
    adherence_pct,
    avg_active_rate_pct,
    avg_unique_medications
from by_age_group

union all

select
    'gender'                                        as segment_type,
    gender_display                                  as segment_value,
    patients_in_group,
    adherent_count,
    adherence_pct,
    null                                            as avg_active_rate_pct,
    null                                            as avg_unique_medications
from by_gender