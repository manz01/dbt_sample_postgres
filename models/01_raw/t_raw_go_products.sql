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
  * Path:           models/01_raw
  * Program:        t_raw_go_products.sql
  * Project:        dbt_sample_postgres
  * Description:    Raw data model for go products
  * Author:         Manzar Ahmed
  * First Created:  Aug 2025
  ************************************************************************
  * Program history:
  ************************************************************************
  * Date        Programmer             Description
  * ----------  ---------------------- -----------------------------------
  * 2025-08-06  Manzar Ahmed           v0.01/Initial version
  ************************************************************************
*/

{{ config(
    materialized = 'copy_to_postgres',
    csv_path = '/warehouse/rawdata/gosales/go_products.csv',
    columns = '
        product_number BIGINT,
        product_line TEXT,
        product_type TEXT,
        product TEXT,
        product_brand TEXT,
        product_color TEXT,
        unit_cost DOUBLE PRECISION,
        unit_price DOUBLE PRECISION
    '
) }}
