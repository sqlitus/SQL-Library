

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
		where IncidentDimvw.createddate BETWEEN '2017-05-01' AND '2017-05-05'
		ORDER BY COUNT(*) OVER(PARTITION BY IncidentDimvw.id) DESC

/* *** */



/* STUFF FOR XML PATH ACTION LOG SUBQUERY EXAMPLE

				, ACTION_LOG = STUFF(
						(SELECT CHAR(10) + '----- ' + CHAR(10) + cast(ial.EnteredDate as varchar(max)) + CHAR(10) + IAL.Description
						FROM ServiceRequestDimvw SRsub
							LEFT JOIN ServiceRequestRelatesToActionLogFactvw SRRTAL
										ON SRsub.ServiceRequestDimKey = SRRTAL.ServiceRequestDimKey
							LEFT JOIN IncidentActionLogDimvw IAL 
										ON SRRTAL.WorkItemHasActionLog_IncidentActionLogDimKey = IAL.IncidentActionLogDimKey
						WHERE SRsub.EntityDimKey = ServiceRequestDimvw.EntityDimKey
						FOR XML PATH(''))
						,1,1,'')

*/