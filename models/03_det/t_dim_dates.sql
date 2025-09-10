/*
  ************************************************************************
  *               _____          _____       _                           *
  *              / ____|        / ____|     | |                          *
  *             | |  __  ___   | (___   __ _| | ___  ___                 *
  *             | | |_ |/ _ \   \___ \ / _` | |/ _ \/ __|                *
  *             | |__| | (_) |  ____) | (_| | |  __/\__ \                *
  *              \_____|\___/  |_____/ \__,_|_|\___||___/                *
  *                                                                      *
  ************************************************************************
  * Path:           models/03_det
  * Program:        t_dim_dates.sql
  * Project:        dbt_sample_postgres
  * Description:    Dimension model for GO Sales dates with various date 
  *                 attributes including year, month, day, week, and 
  *                 weekend/weekday flags
  * Author:         Manzar Ahmed
  * First Created:  Jul 2025
  ************************************************************************
  * Program history:
  ************************************************************************
  * Date        Programmer             Description
  * ----------  ---------------------- -----------------------------------
  * 2025-07-06  Manzar Ahmed           v0.01/Initial version
  * 2025-08-07  Manzar Ahmed           v0.02/change to postgres endpoint
  ************************************************************************
*/

{{ config(
    materialized = 'table',
    schema = 'det'
) }}

with date_span as (
    select generate_series(
        date '2000-01-01',
        date '2000-01-01' + interval '50 years',
        interval '1 day'
    )::date as full_date
),

dim_dates as (
    select
        cast(full_date as date) as date_key,
        full_date,
        extract(year from full_date) as year,
        extract(month from full_date) as month,
        extract(day from full_date) as day,
        extract(week from full_date) as week_of_year,
        extract(dow from full_date) as weekday_number,
        extract(doy from full_date) as day_of_year,
        to_char(full_date, 'YYYY-MM') as month_label,
        to_char(full_date, 'IYYY-IW') as week_label,
        concat(to_char(full_date, 'YYYY'), '-Q', ((extract(month from full_date) - 1) / 3 + 1)::int) as quarter_label,
        (extract(dow from full_date) in (0, 6)) as is_weekend,
        (extract(dow from full_date) between 1 and 5) as is_weekday
    from date_span
)

select * from dim_dates