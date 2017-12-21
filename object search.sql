 /* DATABASE OBJECT/SCHEMA SEARCH */



SELECT *
FROM [DWDataMart].sys.all_objects
WHERE upper(name) like upper('%response%')  
;
go


SELECT  *
FROM    INFORMATION_SCHEMA.TABLES
WHERE   TABLE_NAME LIKE '%assigned%'
;
GO

SELECT  *
FROM    INFORMATION_SCHEMA.COLUMNS
WHERE   COLUMN_NAME LIKE '%response%'
;
GO


/* SEARCH TEMPDB */

select * from tempdb..sysobjects