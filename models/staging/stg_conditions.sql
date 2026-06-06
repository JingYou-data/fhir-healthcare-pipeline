{{ config(
    materialized='view',
    schema='silver'
) }}

with source as (
    select * from {{ source('bronze', 'conditions') }}
),

renamed as (
    select
        condition_id,
        patient_id,
        encounter_id,
        code                                        as condition_code,
        description                                 as condition_description,
        onset_date::timestamp                       as onset_date,
        recorded_date::timestamp                    as recorded_date,
        _loaded_at
    from source
)

select * from renamed