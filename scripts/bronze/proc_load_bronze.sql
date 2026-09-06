-- =============================================================
-- Stored Procedure: Bronze Layer Data Load
-- Purpose: Loads raw source data into the Bronze layer tables
--          of the data warehouse.
--          Existing data is truncated before each load, and
--          execution time is logged for monitoring purposes.
-- Accepts no parameters 
-- Usage: CALL bronze.load_bronze();
-- =============================================================

CREATE OR REPLACE PROCEDURE bronze.load_bronze() 
LANGUAGE plpgsql
AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
	start_bronze TIMESTAMP;
	end_bronze TIMESTAMP;
BEGIN

    RAISE NOTICE '===============================';
    RAISE NOTICE 'Starting bronze layer load...';
    RAISE NOTICE '===============================';

    RAISE NOTICE '--------------------------------';
    RAISE NOTICE 'Loading CRM tables';
    RAISE NOTICE '--------------------------------';

	start_bronze := clock_timestamp();
    start_time := clock_timestamp();

    TRUNCATE TABLE bronze.crm_cust_info;

    COPY bronze.crm_cust_info
    FROM '/tmp/datasets/source_crm/cust_info.csv'
    WITH (
        HEADER TRUE,
        DELIMITER ',',
        FORMAT CSV
    );

    end_time := clock_timestamp();

    RAISE NOTICE 'crm_cust_info loaded successfully';
    RAISE NOTICE 'Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));


    -- CRM PRODUCT INFO
    start_time := clock_timestamp();

    TRUNCATE TABLE bronze.crm_prd_info;

    COPY bronze.crm_prd_info
    FROM '/tmp/datasets/source_crm/prd_info.csv'
    WITH (
        HEADER TRUE,
        DELIMITER ',',
        FORMAT CSV
    );

    end_time := clock_timestamp();

    RAISE NOTICE 'crm_prd_info loaded successfully';
    RAISE NOTICE 'Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));


    -- CRM SALES DETAILS
    start_time := clock_timestamp();

    TRUNCATE TABLE bronze.crm_sales_details;

    COPY bronze.crm_sales_details
    FROM '/tmp/datasets/source_crm/sales_details.csv'
    WITH (
        HEADER TRUE,
        DELIMITER ',',
        FORMAT CSV
    );

    end_time := clock_timestamp();

    RAISE NOTICE 'crm_sales_details loaded successfully';
    RAISE NOTICE 'Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));


    RAISE NOTICE '--------------------------------';
    RAISE NOTICE 'Loading ERP tables';
    RAISE NOTICE '--------------------------------';


    -- ERP CUSTOMER
    start_time := clock_timestamp();

    TRUNCATE TABLE bronze.erp_cust_az12;

    COPY bronze.erp_cust_az12
    FROM '/tmp/datasets/source_erp/CUST_AZ12.csv'
    WITH (
        HEADER TRUE,
        DELIMITER ',',
        FORMAT CSV
    );

    end_time := clock_timestamp();

    RAISE NOTICE 'erp_cust_az12 loaded successfully';
    RAISE NOTICE 'Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));


    -- ERP LOCATION
    start_time := clock_timestamp();

    TRUNCATE TABLE bronze.erp_loc_a101;

    COPY bronze.erp_loc_a101
    FROM '/tmp/datasets/source_erp/LOC_A101.csv'
    WITH (
        HEADER TRUE,
        DELIMITER ',',
        FORMAT CSV
    );

    end_time := clock_timestamp();

    RAISE NOTICE 'erp_loc_a101 loaded successfully';
    RAISE NOTICE 'Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));


    -- ERP PRODUCT CATEGORY
    start_time := clock_timestamp();

    TRUNCATE TABLE bronze.erp_px_cat_g1v2;

    COPY bronze.erp_px_cat_g1v2
    FROM '/tmp/datasets/source_erp/PX_CAT_G1V2.csv'
    WITH (
        HEADER TRUE,
        DELIMITER ',',
        FORMAT CSV
    );

    end_time := clock_timestamp();
	end_bronze := clock_timestamp();

    RAISE NOTICE 'erp_px_cat_g1v2 loaded successfully';
    RAISE NOTICE 'Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));


    RAISE NOTICE '===============================';
    RAISE NOTICE 'Bronze layer load completed! Whole process took % seconds' , end_bronze - start_bronze;
    RAISE NOTICE '===============================';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '===============================';
        RAISE NOTICE 'Error: %', SQLERRM;
        RAISE NOTICE '===============================';

        RAISE;
END;
$$;
