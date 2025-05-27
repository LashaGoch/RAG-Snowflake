--################################################
-- STEP 7: Create Cortex Search Service
--################################################

CREATE CORTEX SEARCH SERVICE DATABASE.SCHEMA.RAG_DEMO
    ON CHUNK
    //ATTRIBUTES  CUSTOMER_NAME, CUSTOMER_AND_SITE_ID, SALES_PERSON_NAME, SIEBEL_SHIP_TO_ID, CHUNK_TYPE
    WAREHOUSE = DS_TEAM2_WH
    TARGET_LAG = '1 day'
    AS (
        SELECT *
        FROM DATABASE.SCHEMA.RAG_DEMO_CHUNKS
    );
    
    
//DROP CORTEX SEARCH SERVICE DATABASE.SCHEMA.RAG_DEMO;
