/* OVOT - Service Requests

Created by:	CJ
Date:		1/17/2019

Requestor: PN & P in GHD

Purpose: 
			See open SERVICE REQUEST volume over time. Return open list for any given day.

Query Description: 
			For a calendar, get the tickets (1) open and (2) assigned to the GHD as of those dates.
			Cross join dates & tic list to get all permutations of date/tic 
				inner join with historical SCDs to constrain historical dim data, 
				and filter via row_number for duplicates.

Data sources:
			SRs.

			
*/

SET NOCOUNT ON;

declare @StartDateTime datetime		= '2017-01-01 12:29:00'  
declare @StartDate date				= cast(@StartDateTime as date)
declare @EndDate datetime			= '2018-03-01 23:29:00'
--declare @SupportGroup int			= 4
--declare @Status int					= 'something'
;


WITH DATE_RANGE AS (
		SELECT @StartDate AS DATE
		UNION ALL
		SELECT DATEADD(DAY,1,DATE) FROM DATE_RANGE AS DATE
		WHERE DATEADD(DAY,1,DATE) <= @EndDate
)


, CALENDAR AS (
		SELECT *
			-- DATETIME 8AM. ADJUST FOR DLS 2017 ONLY
			, DATETIME = CASE WHEN DATE < '2017-03-12' OR DATE > '2017-11-04' THEN DATEADD(HOUR, 9, CAST(DATE AS DATETIME)) 
				ELSE DATEADD(HOUR, 8, CAST(DATE AS DATETIME)) 
				END
		FROM DATE_RANGE 
)


, OUTPUT AS (
SELECT CALENDAR.*
	, STATUS_SG_START_ORDER = ROW_NUMBER() OVER(PARTITION BY CALENDAR.DATE, SR.ID ORDER BY SG_DUR.STARTDATETIME, S_DUR.STARTDATETIME)
	, sr.Id
	, sr.Title
	, 'PRIORITY' = P.ServiceRequestPriorityValue
	, 'SUPPORT GROUP START' = SG_DUR.StartDateTime
	, 'SUPPORT GROUP FINISH' = SG_DUR.FinishDateTime
	, 'STATUS START' = S_DUR.StartDateTime
	, 'STATUS FINISH' = S_DUR.FinishDateTime
	, 'SUPPORT GROUP' = SG.SERVICEREQUESTSUPPORTGROUPVALUE
	, 'STATUS' = S.SERVICEREQUESTSTATUSVALUE
	, SR.CreatedDate
	, SR.CompletedDate	
	

FROM CALENDAR 
	CROSS JOIN SERVICEREQUESTDIMVW SR
	LEFT JOIN ServiceRequestPriorityvw P ON SR.Priority_ServiceRequestPriorityId = P.ServiceRequestPriorityId

	-- JOIN SUPPORT GROUP HISTORY: WHAT IS ASSIGNED ON THE DATETIME
	JOIN ServiceRequestSupportGroupStatusDurationFactvw SG_DUR 
		ON SR.SERVICEREQUESTDIMKEY = SG_DUR.ServiceRequestDimKey
		AND SG_DUR.STARTDATETIME <= CALENDAR.DATETIME
		AND (SG_DUR.FINISHDATETIME > CALENDAR.DATETIME OR SG_DUR.FINISHDATETIME IS NULL)
		AND SG_DUR.SERVICEREQUESTSUPPORTGROUPID = 4	 -- SUPPORT GROUP: GHD

		LEFT JOIN ServiceRequestSupportGroupvw SG ON SG.SERVICEREQUESTSUPPORTGROUPID = SG_DUR.SERVICEREQUESTSUPPORTGROUPID

	-- JOIN STATUS HISTORY. CONSTRAINS TO ONLY OPEN SRS AS OF THE CALENDAR DATETIME.
	JOIN [ServiceRequestStatusDurationFactvw] S_DUR
		ON SR.ServiceRequestDimKey = S_DUR.ServiceRequestDimKey
		AND S_DUR.STARTDATETIME <= CALENDAR.DATETIME
		AND (S_DUR.FINISHDATETIME > CALENDAR.DATETIME OR S_DUR.FINISHDATETIME IS NULL)
		AND S_DUR.SERVICEREQUESTSTATUSID IN (2,7,8)  -- STATUS: NEW, IN PROGRESS, ON HOLD

		LEFT JOIN [ServiceRequestStatusvw] S ON S.SERVICEREQUESTSTATUSID = S_DUR.SERVICEREQUESTSTATUSID
)


SELECT * FROM OUTPUT
WHERE STATUS_SG_START_ORDER = 1  -- LIMIT TO EARLIEST SUPPORT GROUP START & STATUS START DATES
ORDER BY DATE, ID
OPTION (MAXRECURSION 500)  -- REQUIRED BECAUSE OF CALENDAR RECURSIVE CTE.
