{{ config(
    materialized='table',
    schema='gold'
) }}

with conditions as (
    select * from {{ ref('stg_conditions') }}
),

patients as (
    select * from {{ ref('stg_patients') }}
),

total_patients as (
    select count(distinct patient_id) as total
    from patients
),

condition_counts as (
    select
        condition_code,
        condition_description,
        count(distinct patient_id)              as affected_patients,
        count(condition_id)                     as total_occurrences,
        min(onset_date)                         as first_seen,
        max(onset_date)                         as last_seen
    from conditions
    group by 1, 2
),

final as (
    select
        cc.condition_code,
        cc.condition_description,
        cc.affected_patients,
        cc.total_occurrences,
        tp.total                                as total_patients,
        round(cc.affected_patients * 100.0 
              / tp.total, 2)                    as prevalence_pct,
        cc.first_seen,
        cc.last_seen,
        rank() over (
            order by cc.affected_patients desc
        )                                       as prevalence_rank
    from condition_counts cc
    cross join total_patients tp
)

select * from final
order by prevalence_rank