{{ config(
    materialized='view',
    schema='silver'
) }}

with source as (
    select * from {{ source('bronze', 'encounters') }}
),

renamed as (
    select
        encounter_id,
        patient_id,
        "start"::timestamp                          as encounter_start,
        "end"::timestamp                            as encounter_end,
        datediff('minute', 
            "start"::timestamp, 
            "end"::timestamp)                       as duration_minutes,
        status,
        class                                       as encounter_class,
        type                                        as encounter_type,
        _loaded_at
    from source
)

select * from renamed