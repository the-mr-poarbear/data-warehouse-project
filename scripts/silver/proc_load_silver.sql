-- =============================================================
-- Stored Procedure: Silver Layer Data Load
-- Purpose: Cleans raw data from Bronze layer into the Silver layer tables
--          of the data warehouse.
--          Existing data is truncated before each load, and
--          execution time is logged for monitoring purposes.
-- Accepts no parameters 
-- Usage: CALL silver.load_silver();
-- =============================================================

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
	start_bronze TIMESTAMP;
	end_bronze TIMESTAMP;
BEGIN

    RAISE NOTICE '===============================';
    RAISE NOTICE 'Starting silver layer load...';
    RAISE NOTICE '===============================';

    RAISE NOTICE '--------------------------------';
    RAISE NOTICE 'Loading CRM tables';
    RAISE NOTICE '--------------------------------';

	start_bronze := clock_timestamp();
    start_time := clock_timestamp();
	
	RAISE NOTICE '>> Truncating crm_cust_info';
	TRUNCATE TABLE silver.crm_cust_info;
	RAISE NOTICE '>> Inserting crm_cust_info';
	--insert into crm_cust_info silver layer
	INSERT INTO silver.crm_cust_info(
	cst_id, 
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date
	)
	
	SELECT cst_id, 
	cst_key, 
	TRIM(cst_firstname) AS  cst_firstname , 
	TRIM(cst_lastname) AS cst_lastname, 
	CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
		 WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
		 ELSE 'n/a'
	END cst_marital_status,
	CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
		 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
		 ELSE 'n/a'
	END cst_gndr,
	cst_create_date  
	FROM (
		SELECT 
		ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date desc) AS r , * 
		FROM bronze.crm_cust_info
		)
	where r = 1;

	end_time := clock_timestamp();
	RAISE NOTICE 'crm_cust_info loaded successfully';
    RAISE NOTICE 'Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

	start_time := clock_timestamp();
	RAISE NOTICE '>> Truncating crm_prd_info';
	TRUNCATE TABLE silver.crm_prd_info;
	RAISE NOTICE '>> Inserting crm_prd_info';
	--insert into crm_prd_info silver layer
	INSERT INTO silver.crm_prd_info(
		prd_id,
		prd_key,
		cat_id,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt
	)
	SELECT 
		prd_id,
		SUBSTRING(prd_key,7,LENGTH(prd_key)) AS pred_key,
		REPLACE(SUBSTRING(prd_key,1,5), '-' , '_') AS cat_id,
		prd_nm,
		COALESCE(prd_cost , 0) as prd_cost,
		CASE UPPER(TRIM(prd_line))
			WHEN 'M' THEN 'Mountain'
			WHEN 'R' THEN 'Road'
			WHEN 'S' THEN 'Other Sales'
			WHEN 'T' THEN 'Touring'
			ELSE 'n/a'
		END AS prd_line,
		CAST(prd_start_dt AS DATE) AS prd_start_dt,
		CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt )-1 AS DATE) AS prd_end_dt
	FROM bronze.crm_prd_info;

	end_time := clock_timestamp();

    RAISE NOTICE 'crm_prd_info loaded successfully';
    RAISE NOTICE 'Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));


	start_time := clock_timestamp();
	RAISE NOTICE '>> Truncating crm_sales_details';
	TRUNCATE TABLE silver.crm_sales_details;
	RAISE NOTICE '>> Inserting crm_sales_details';
	--insert into crm_sales_details silver layer
	INSERT INTO silver.crm_sales_details(
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		sls_order_dt,
		sls_ship_dt,
		sls_due_dt,
		sls_sales,
		sls_quantity,
		sls_price
	)
	SELECT
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		
		CASE WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::TEXT) != 8 THEN NULL
			ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
		END AS sls_order_dt,
		
		CASE WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt::TEXT) != 8 THEN NULL
			ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
		END AS sls_ship_dt,
		
		CASE WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt::TEXT) != 8 THEN NULL
			ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
		END AS sls_due_dt,
		
		CASE WHEN sls_sales <=0 OR sls_sales IS NULL OR sls_sales != sls_quantity * ABS(sls_price) 
				THEN sls_quantity * ABS(sls_price)
			ELSE sls_sales
		END AS sls_sales,
		
		sls_quantity,
		
		CASE WHEN sls_price <0 THEN ABS(sls_price)
			WHEN sls_price = 0 OR sls_price IS NULL 
				THEN ABS(sls_sales)/ NULLIF(sls_quantity,0)
			ELSE sls_price
		END AS sls_price
		
	FROM bronze.crm_sales_details;

	end_time := clock_timestamp();

    RAISE NOTICE 'crm_sales_details loaded successfully';
    RAISE NOTICE 'Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

	RAISE NOTICE '--------------------------------';
    RAISE NOTICE 'Loading ERP tables';
    RAISE NOTICE '--------------------------------';

	start_time := clock_timestamp();
	RAISE NOTICE '>> Truncating erp_cust_az12';
	TRUNCATE TABLE silver.erp_cust_az12;
	RAISE NOTICE '>> Inserting erp_cust_az12';
	--insert into erp_cust_az12 silver layer
	INSERT INTO silver.erp_cust_az12(
	cid,
	bdate,
	gen
	)
	SELECT 
		CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LENGTH(cid))
			ELSE cid
		END AS cid,
		CASE WHEN bdate > CURRENT_DATE THEN NULL
			ELSE bdate
		END AS bdate,
		CASE
			WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
			WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
			ELSE 'n/a'
		END AS gen
	FROM bronze.erp_cust_az12;

	end_time := clock_timestamp();

    RAISE NOTICE 'erp_cust_az12 loaded successfully';
    RAISE NOTICE 'Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));


	start_time := clock_timestamp();
	RAISE NOTICE '>> Truncating erp_loc_a101';
	TRUNCATE TABLE silver.erp_loc_a101;
	RAISE NOTICE '>> Inserting erp_loc_a101';
	--insert into erp_loc_a101 silver layer
	INSERT INTO silver.erp_loc_a101
	(cid,cntry)
	SELECT 
	REPLACE(cid,'-','')as cid,
	CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
		WHEN TRIM(cntry) IN ('US' , 'USA') THEN 'United States'
		WHEN cntry IS NULL OR TRIM(cntry) = '' THEN 'n/a'
		ELSE cntry
	END AS cntry
	FROM bronze.erp_loc_a101;

	RAISE NOTICE 'erp_loc_a101 loaded successfully';
    RAISE NOTICE 'Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));
		
	start_time := clock_timestamp();
	RAISE NOTICE '>> Truncating erp_px_cat_g1v2';
	TRUNCATE TABLE silver.erp_px_cat_g1v2;
	RAISE NOTICE '>> Inserting erp_px_cat_g1v2';
	--insert into erp_px_cat_g1v2 silver layer
	INSERT INTO silver.erp_px_cat_g1v2 (
		id,
		cat,
		subcat,
		maintenance
	)
	SELECT 
		id,
		cat,
		subcat,
		maintenance
	FROM bronze.erp_px_cat_g1v2;
	
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
	
