/* dynamic sql query
query run, columns selected based on switch parameters ...
sp_executesql

*/

-- GET COLUMN IF PARAM = T

DECLARE @SWITCH VARCHAR(5) = 'N'

SELECT DISTINCT REGION, LOCATION,
	CASE WHEN @SWITCH = 'ON' THEN Location END
FROM IncidentDimvw
ORDER BY REGION, Location

/*
SQL / SSRS
CONDITIONALLY RUN COLUMNS
QUERY COLUMNS

*/


declare @sql nvarchar(max) = 'SELECT uniqueId, columnTwo, ' +
    (case when exists (select *
                       from INFORMATION_SCHEMA.COLUMNS 
                       where tablename = @TableName and
                             columnname = 'ColumnThree' -- and schema name too, if you like
                      )
          then 'ColumnThree'
          else 'NULL as ColumnThree'
     end) + '
FROM (select * from '+@SourceName+' s
';