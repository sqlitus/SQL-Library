

/* *** */
-- 6/5/2017
-- TEMP TABLE FOR MULTIPLE POSSIBLE STRING MATCHES
-- FOR XML PATH EXAMPLE

IF OBJECT_ID('tempdb..#patterns') IS NOT NULL
	DROP TABLE #patterns
	;

CREATE TABLE   #patterns 
(
	pattern VARCHAR(max)
);

INSERT INTO #patterns VALUES 
('TS'), ('SP'), ('MA'), ('PN'), ('RM'), ('SO'), ('MW'), ('FL'), ('UK'), ('SW'), ('CE'), ('NC'), ('NE'), ('NA')
;

-- FOR XML PATH AND STUFF() TO GET MULTIPLE COLUMN VALUES INTO A SINGLE ROW

		select IncidentDimvw.id
		, [REGIONPATTERN] = #PATTERNS.PATTERN
		, IncidentDimvw.Title
		, NUMREGIONS = COUNT(*) OVER(PARTITION BY IncidentDimvw.id)
		, REGIONS = STUFF((SELECT ', ' + #patterns.pattern FROM #patterns 
			WHERE IncidentDimvw.Title like '%[ ]' + #patterns.pattern + '[ ]%'
			FOR XML PATH('')),1,1,'')
		from IncidentDimvw
			join  #patterns  on IncidentDimvw.Title like '%[ ]' + #patterns.pattern + '[ ]%'
		where IncidentDimvw.createddate > '2017-05-01'
		ORDER BY COUNT(*) OVER(PARTITION BY IncidentDimvw.id) DESC

/* *** */
