{{ config(
    materialized='view',
    schema='silver'
) }}

with source as (
    select * from {{ source('bronze', 'medications') }}
),

renamed as (
    select
        medication_id,
        patient_id,
        encounter_id,
        medication_code,
        medication_name,
        authored_on::timestamp                      as authored_on,
        status,
        case
            when status = 'active' then true
            else false
        end                                         as is_active,
        _loaded_at
    from source
)

select * from renamed