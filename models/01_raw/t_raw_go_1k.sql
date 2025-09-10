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
  * Program:        t_raw_go_1k.sql
  * Project:        dbt_sample_postgres
  * Description:    raw data model for go sales 1k transactions
  * Author:         Manzar Ahmed
  * First Created:  Aug 2025
  ************************************************************************
  * Program history:
  ************************************************************************
  * Date        Programmer             Description
  * ----------  ---------------------- -----------------------------------
  * 2025-08-29  Manzar Ahmed           v0.01 / Initial version
  ************************************************************************
*/

{{ config(
    materialized = 'copy_to_postgres',
    csv_path = '/warehouse/rawdata/gosales/go_1k.csv',
    columns = '
        retailer_code BIGINT,
        product_number BIGINT,
        transaction_date TEXT,
        quantity INTEGER
    '
) }}

