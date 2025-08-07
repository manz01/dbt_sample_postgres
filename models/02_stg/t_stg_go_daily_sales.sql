/*-------------------------------------------------------------------------------
Program:        t_stg_go_daily_sales
Project:        duckdb-core-sample-go-sales
Description:    Staging model for GO Sales products daily sales
                with raw data from source
Input(s):       raw.t_raw_go_daily_sales
Output(s):      stg.t_stg_go_daily_sales
Author:         Manzar Ahmed
First Created:  Jun 2025
--------------------------------------------------------------------------------
Program history:
--------------------------------------------------------------------------------
Date        Programmer             Description
----------  ---------------------  ---------------------------------------------
2025-06-11  Manzar Ahmed           v0.01/Initial version
-------------------------------------------------------------------------------*/

select
    retailer_code,
    product_number,
    order_method_code,
    TO_DATE(transaction_date, 'DD/MM/YYYY')  as transaction_date,
    quantity,
    unit_price,
    unit_sale_price

from {{ ref('t_raw_go_daily_sales') }}



