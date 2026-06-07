{{ config(
    materialized='table',
    schema='silver'
) }}

with encounters as (
    select * from {{ ref('stg_encounters') }}
),

--  find out the people who returned to hospital agian within 30 days 
encounter_pairs as (
    select
        e1.encounter_id                             as index_encounter_id,
        e1.patient_id,
        e1.encounter_start                          as index_admission,
        e1.encounter_end                            as index_discharge,
        e1.encounter_class                          as index_class,
        e2.encounter_id                             as readmission_encounter_id,
        e2.encounter_start                          as readmission_date,
        e2.encounter_class                          as readmission_class,
        datediff('day',
            e1.encounter_end,
            e2.encounter_start)                     as days_to_readmission
    from encounters e1
    left join encounters e2
        on e1.patient_id = e2.patient_id
        and e2.encounter_start > e1.encounter_end
        and datediff('day', e1.encounter_end, e2.encounter_start) <= 30
        and e1.encounter_id != e2.encounter_id
        and e1.encounter_class in ('inpatient', 'emergency')
),

final as (
    select
        index_encounter_id,
        patient_id,
        index_admission,
        index_discharge,
        index_class,
        readmission_encounter_id,
        readmission_date,
        readmission_class,
        days_to_readmission,
        case
            when readmission_encounter_id is not null then true
            else false
        end                                         as is_readmitted_30d
    from encounter_pairs
)

select * from final