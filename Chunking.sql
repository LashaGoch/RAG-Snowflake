--################################################
-- Building a Simple RAG on PDFs
--################################################



--################################################
-- STEP 1: Create a stage and upload documents
--################################################

CREATE STAGE DATABASE.SCHEMA.RAG_DEMO
  ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
  DIRECTORY = ( ENABLE = true );

//DROP STAGE DATABASE.SCHEMA.RAG_DEMO;

-- Upload documens directly on Stage you created

-- List the documents from the stage
USE DATABASE.SCHEMA;

ls @RAG_DEMO;


--################################################
-- STEP 2: Read PDF from the Stage: 
-- Use the function SNOWFLAKE.CORTEX.PARSE_DOCUMENT 
-- to read the PDF documents directly from the staging area
--################################################

CREATE OR REPLACE TEMPORARY TABLE RAG_RAW_TEXT AS
SELECT 
    RELATIVE_PATH,
    SIZE,
    FILE_URL,
    build_scoped_file_url(@RAG_DEMO, relative_path) as scoped_file_url,
    TO_VARCHAR (
        SNOWFLAKE.CORTEX.PARSE_DOCUMENT (
            '@RAG_DEMO',
            RELATIVE_PATH,
            {'mode': 'LAYOUT'} ):content
        ) AS EXTRACTED_LAYOUT 
FROM 
    DIRECTORY('@RAG_DEMO');

-- Check the extracted text from the PDF
SELECt * FROM RAG_RAW_TEXT limit 10;

--################################################
-- STEP 3: Create the table where we are going to store the chunks for each PDF
--################################################

CREATE OR REPLACE TABLE RAG_DEMO_CHUNKS ( 
    RELATIVE_PATH VARCHAR(16777216),   -- Relative path to the PDF file
    SIZE NUMBER(38,0),                 -- Size of the PDF
    FILE_URL VARCHAR(16777216),        -- URL for the PDF
    SCOPED_FILE_URL VARCHAR(16777216), -- Scoped url (you can choose which one to keep depending on your use case)
    CHUNK VARCHAR(16777216),           -- Piece of text
    CHUNK_INDEX INTEGER                -- Index for the text
);


--################################################
-- STEP 4: Create chunks. Split the text into shorter strings. 
-- Use the function SNOWFLAKE.CORTEX.SPLIT_TEXT_RECURSIVE_CHARACTER
--################################################

INSERT INTO RAG_DEMO_CHUNKS (relative_path, size, file_url,
                            scoped_file_url, chunk, chunk_index)

    SELECT relative_path, 
            size,
            file_url, 
            scoped_file_url,
            c.value::TEXT as chunk,
            c.INDEX::INTEGER as chunk_index
            
    FROM 
        RAG_RAW_TEXT,
        LATERAL FLATTEN( input => SNOWFLAKE.CORTEX.SPLIT_TEXT_RECURSIVE_CHARACTER (
              EXTRACTED_LAYOUT,
              'markdown',
              1512,             -- CHUNK_SIZE
              256,              -- CHUNK_OVERLAP
              ['\n\n', '\n', ' ', '']
           )) c;


-- Check the data
SELECT * FROM RAG_DEMO_CHUNKS limit 20;

--################################################
-- STEP 6: Cleanup. Delete small chunks with unnecessary info
--################################################
SELECT * FROM DATABASE.SCHEMA.RAG_DEMO_CHUNKS WHERE len(chunk) < 300 AND chunk NOT ILIKE '%$%'; 

DELETE FROM DATABASE.SHEMA.RAG_DEMO_CHUNKS WHERE LENGTH(chunk) < 300 AND chunk NOT ILIKE '%$%';
