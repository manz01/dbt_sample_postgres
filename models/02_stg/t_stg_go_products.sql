/*-------------------------------------------------------------------------------
Program:        t_stg_go_products
Project:        duckdb-core-sample-go-sales
Description:    Staging model for GO Sales products
                with raw data from source
Input(s):       raw.t_raw_go_products
Output(s):      stg.t_stg_go_products
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
    product_number,
    product_line,
    product_type,
    product,
    product_brand,
    product_color,
    unit_cost,
    unit_price
from {{ ref('t_raw_go_products') }}