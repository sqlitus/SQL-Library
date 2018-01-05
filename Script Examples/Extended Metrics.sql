/* EXTENDED METRICS */
/* FIRST CALL FIX + OTHERS */



SET NOCOUNT ON;


--declare @START_DATE as date = '2017-06-01'
--declare @END_DATE as date = '2017-06-16'
--declare @SupportGroup as varchar(255) = 7
--declare @SupportGroupParent as varchar(255) = 7
--;

/* GRABBING LIST OF TEAMS ASSIGNED TO ONEPOS */
WITH CTE AS (
		SELECT DISTINCT IncidentDimvw.IncidentDimKey
			,WorkItemDimvw.EntityDimKey
			,WorkItemDimvw.WorkItemDimKey
		FROM IncidentTierQueueDurationFactvw JOIN IncidentTierQueuesvw ON IncidentTierQueueDurationFactvw.IncidentTierQueuesId = IncidentTierQueuesvw.IncidentTierQueuesId
			JOIN IncidentDimvw ON IncidentTierQueueDurationFactvw.IncidentDimKey = IncidentDimvw.IncidentDimKey
			JOIN WorkItemDimvw ON IncidentDimvw.EntityDimKey = WorkItemDimvw.EntityDimKey
		WHERE ( IncidentTierQueuesvw.IncidentTierQueuesId IN (@SupportGroup) OR IncidentTierQueuesvw.ParentId IN (@SupportGroupParent) )
			AND
			(
				(
					( IncidentDimvw.CreatedDate >= @START_DATE OR @START_DATE IS NULL )
					AND
					( IncidentDimvw.CreatedDate <= @END_DATE  OR @END_DATE IS NULL )
				)
				or
				(
					( IncidentDimvw.ResolvedDate >= @START_DATE OR @START_DATE IS NULL )
					AND
					( IncidentDimvw.ResolvedDate <= @END_DATE  OR @END_DATE IS NULL )
				)

			)
)

/* AGGREGATE TEAM CHANGE HISTORIES */
, CTE_TEAMS AS ( 
SELECT IncidentTierQueueDurationFactvw.IncidentDimKey
	, COUNT(IncidentTierQueueDurationFactvw.IncidentTierQueuesId) AS [NUM TEAMS]
	, COUNT(DISTINCT IncidentTierQueueDurationFactvw.IncidentTierQueuesId) AS [NUM DISTINCT TEAMS]
	, MIN(IncidentTierQueueDurationFactvw.StartDateTime) AS [MIN_SG_DATE]
FROM CTE JOIN IncidentTierQueueDurationFactvw ON CTE.IncidentDimKey=IncidentTierQueueDurationFactvw.IncidentDimKey
GROUP BY IncidentTierQueueDurationFactvw.IncidentDimKey
)

/* AGGREGATE ASSIGNED CHANGE HISTORIES */
, CTE_ASSIGNS AS (
SELECT CTE.WorkItemDimKey
	, COUNT(WorkItemAssignedToUserFactvw.WorkItemAssignedToUser_UserDimKey) AS [NUM ASSIGNS]
	, COUNT(DISTINCT WorkItemAssignedToUserFactvw.WorkItemAssignedToUser_UserDimKey) AS [NUM DISTINCT ASSIGNED]
	, MIN(WorkItemAssignedToUserFactvw.CREATEDDATE) AS [MIN_ASSIGN_DATE]
	, MAX(WorkItemAssignedToUserFactvw.CREATEDDATE) AS [MAX_ASSIGN_DATE]
FROM CTE LEFT JOIN WorkItemAssignedToUserFactvw ON CTE.WorkItemDimKey=WorkItemAssignedToUserFactvw.WorkItemDimKey
GROUP BY CTE.WorkItemDimKey
)

/* FLAG INCIDENTS WITH 1 REAL-ANALYST ASSIGN (EXCLUDES FIRST CALL BACK NEEDED ASSIGN) */
, CTE_ASSIGNS_2 AS (
select  IncidentDimKey
from 
(
		SELECT IncidentDimvw.IncidentDimKey
				,[assign order] = RANK() over(partition by IncidentDimvw.IncidentDimKey order by WorkItemAssignedToUserFactvw.createddate)
				,[total assigns] = count(*) over(partition by IncidentDimvw.IncidentDimKey)
				,[prev assign] = lag(WorkItemAssignedToUserFactvw.WorkItemAssignedToUser_UserDimKey) 
									over(partition by  IncidentDimvw.IncidentDimKey order by WorkItemAssignedToUserFactvw.createddate)
		FROM WorkItemAssignedToUserFactvw
				join WorkItemDimvw on WorkItemAssignedToUserFactvw.workitemdimkey = workitemdimvw.workitemdimkey
				join IncidentDimvw on IncidentDimvw.EntityDimKey = WorkItemDimvw.EntityDimKey
		where 
				(
					(IncidentDimvw.CreatedDate between @START_DATE and @END_DATE) 
					OR (IncidentDimvw.ResolvedDate between @START_DATE and @END_DATE) 
				)
				AND IncidentDimvw.Id LIKE 'IR%'
) x
where [total assigns] = 1
	OR ( [total assigns] = 2 and [assign order] = 2 and [prev assign] = 220633)
)

/* first real-analyst assign. copy of above, but not filtering on FCF */
, CTE_ASSIGNS_3 AS (
select  IncidentDimKey, [Real Analyst Assign Date]
from 
(
		SELECT IncidentDimvw.IncidentDimKey
				,[assign order] = RANK() over(partition by IncidentDimvw.IncidentDimKey order by WorkItemAssignedToUserFactvw.createddate)
				,[prev assign] = lag(WorkItemAssignedToUserFactvw.WorkItemAssignedToUser_UserDimKey) 
									over(partition by  IncidentDimvw.IncidentDimKey order by WorkItemAssignedToUserFactvw.createddate)
				,[assign] = WorkItemAssignedToUserFactvw.WorkItemAssignedToUser_UserDimKey
				,[Real Analyst Assign Date] = WorkItemAssignedToUserFactvw.createddate
		FROM WorkItemAssignedToUserFactvw
				join WorkItemDimvw on WorkItemAssignedToUserFactvw.workitemdimkey = workitemdimvw.workitemdimkey
				join IncidentDimvw on IncidentDimvw.EntityDimKey = WorkItemDimvw.EntityDimKey
		where 
				(
					(IncidentDimvw.CreatedDate between @START_DATE and @END_DATE) 
					OR (IncidentDimvw.ResolvedDate between @START_DATE and @END_DATE) 
				)
				AND IncidentDimvw.Id LIKE 'IR%'
) x
where [assign order] = 1 and [assign] <> 220633
	OR ([assign order] = 2 and [prev assign] = 220633)
)

/* FIRST CREATED USER */
, CTE_CREATED_USER AS (
SELECT CTE.WorkItemDimKey
	, MIN(WorkItemCreatedByUserFactvw.CreatedDate)	AS [MIN_CREATED_DATE]
FROM CTE LEFT JOIN WorkItemCreatedByUserFactvw ON CTE.WorkItemDimKey = WorkItemCreatedByUserFactvw.WorkItemDimKey
GROUP BY CTE.WorkItemDimKey
)

/* LAST RESOLVED USER */
, CTE_RESOLVED_USER AS (
SELECT CTE.IncidentDimKey
	, MAX(IncidentResolvedByUserFactvw.CreatedDate)	AS [MAX_RESOLVED_DATE]
FROM CTE LEFT JOIN IncidentResolvedByUserFactvw ON CTE.IncidentDimKey = IncidentResolvedByUserFactvw.IncidentDimKey
GROUP BY CTE.IncidentDimKey
)


/* FLAGGING ESCALATION INFO */
, FLAGS AS (
		SELECT IncidentTierQueueDurationFactvw.IncidentDimKey
			,IncidentTierQueueDurationFactvw.StartDateTime
			,[L1 to L2] = CASE WHEN LAG(IncidentTierQueuesvw.IncidentTierQueuesId) OVER(PARTITION BY IncidentTierQueueDurationFactvw.IncidentDimKey ORDER BY IncidentTierQueueDurationFactvw.StartDateTime)
				IN (7,63) AND IncidentTierQueuesvw.IncidentTierQueuesId = 60 THEN 1 ELSE 0 END 
			,[L2 to L3] = CASE WHEN LAG(IncidentTierQueuesvw.IncidentTierQueuesId) OVER(PARTITION BY IncidentTierQueueDurationFactvw.IncidentDimKey ORDER BY IncidentTierQueueDurationFactvw.StartDateTime)
				= 60 AND IncidentTierQueuesvw.IncidentTierQueuesId = 8 THEN 1 ELSE 0 END 
			,[L1 to L3] = CASE WHEN LAG(IncidentTierQueuesvw.IncidentTierQueuesId) OVER(PARTITION BY IncidentTierQueueDurationFactvw.IncidentDimKey ORDER BY IncidentTierQueueDurationFactvw.StartDateTime)
				IN (7,63) AND IncidentTierQueuesvw.IncidentTierQueuesId = 8 THEN 1 ELSE 0 END 
			,[L1 to Hardware] = CASE WHEN LAG(IncidentTierQueuesvw.IncidentTierQueuesId) OVER(PARTITION BY IncidentTierQueueDurationFactvw.IncidentDimKey ORDER BY IncidentTierQueueDurationFactvw.StartDateTime)
				IN (7,63) AND IncidentTierQueuesvw.IncidentTierQueuesId = 62 THEN 1 ELSE 0 END 

		FROM CTE JOIN IncidentTierQueueDurationFactvw ON CTE.IncidentDimKey = IncidentTierQueueDurationFactvw.IncidentDimKey
			JOIN IncidentTierQueuesvw ON IncidentTierQueueDurationFactvw.IncidentTierQueuesId = IncidentTierQueuesvw.IncidentTierQueuesId
)
, SUM_FLAGS AS (
	SELECT INCIDENTDIMKEY
		,SUM([L1 to L2]) AS [L1 to L2]
		,SUM([L2 to L3]) AS [L2 to L3]
		,SUM([L1 to L3]) AS [L1 to L3]
		,SUM([L1 to Hardware]) AS [L1 to Hardware]
	FROM FLAGS
	GROUP BY INCIDENTDIMKEY
)

/* COMBINE USING FIRST CTE AS BASE */
SELECT IncidentDimvw.Id
	, EntityDimvw.LastModified
	, IncidentDimvw.Title
	, CTE_TEAMS.[NUM TEAMS]
	, CTE_TEAMS.[NUM DISTINCT TEAMS]
	, CTE_ASSIGNS.[NUM ASSIGNS] 
	, CTE_ASSIGNS.[NUM DISTINCT ASSIGNED]
	, CASE WHEN CTE_TEAMS.[NUM TEAMS] <= 1 
				AND IncidentDimvw.ResolvedDate IS NOT NULL
				AND IncidentStatusvw.IncidentStatusValue NOT IN ('Active','Pending') THEN 1 ELSE 0 END		AS [FIRST TEAM RESOLVE]
	, CASE WHEN CTE_ASSIGNS.[NUM ASSIGNS] <=1
				AND IncidentDimvw.ResolvedDate IS NOT NULL
				AND IncidentStatusvw.IncidentStatusValue NOT IN ('Active','Pending') THEN 1 ELSE 0 END		AS [FIRST ANALYST RESOLVE]
	, IncidentStatusvw.IncidentStatusValue			AS [STATUS]
	, FIRST_SG_NAME.DISPLAYNAME						AS [FIRST SUPPORT GROUP]
	, SG_NAME.DISPLAYNAME							AS [LAST SUPPORT GROUP]
	, IncidentDimvw.CreatedDate
	, IncidentDimvw.FirstAssignedDate
	, IncidentDimvw.ResolvedDate

	, DATEDIFF(MINUTE,IncidentDimvw.CreatedDate,IncidentDimvw.ResolvedDate)	AS [Open To Resolve Time (M)]
	--, DATEDIFF(DAY,IncidentDimvw.CreatedDate,IncidentDimvw.ClosedDate)		AS [OpenToCloseTime (D)]
	, DATEDIFF(MINUTE,IncidentDimvw.CreatedDate,IncidentDimvw.FirstAssignedDate)	AS [Time To First Assign (M)]
	, DATEDIFF(MINUTE,IncidentDimvw.CreatedDate,IncidentDimvw.ResolvedDate) / CTE_TEAMS.[NUM DISTINCT TEAMS]	AS [Avg Time Per Team (M)]
	, DATEDIFF(MINUTE,IncidentDimvw.FirstAssignedDate,IncidentDimvw.ResolvedDate) 
		/ CASE WHEN CTE_ASSIGNS.[NUM DISTINCT ASSIGNED] = 0 THEN 1 ELSE CTE_ASSIGNS.[NUM DISTINCT ASSIGNED] END AS [Avg Time Per Analyst (M)]

	


	, CREATED_USER.DisplayName						AS [CREATED USER]
	, FIRST_ASSIGNED_TO_USER.DisplayName			AS [FIRST ASSIGNED]
	, LAST_ASSIGNED_TO_USER.DisplayName				AS [LAST ASSIGNED]
	, RESOLVED_USER.DisplayName						AS [RESOLVED USER]
	, CASE WHEN FIRST_ASSIGNED_TO_USER.DisplayName IS NULL THEN CREATED_USER.DisplayName ELSE FIRST_ASSIGNED_TO_USER.DisplayName END AS [Chris First Assigned]
	, CASE WHEN LAST_ASSIGNED_TO_USER.DisplayName IS NULL THEN CREATED_USER.DisplayName ELSE LAST_ASSIGNED_TO_USER.DisplayName END AS [Chris Last Assigned]
	, CASE WHEN RESOLVED_USER.DisplayName IS NULL 
				AND LAST_ASSIGNED_TO_USER.DisplayName IS NOT NULL 
				AND IncidentStatusvw.IncidentStatusValue NOT IN ('Active','Pending') THEN LAST_ASSIGNED_TO_USER.DisplayName
			WHEN RESOLVED_USER.DisplayName IS NULL 
				AND LAST_ASSIGNED_TO_USER.DisplayName IS NULL 
				AND IncidentStatusvw.IncidentStatusValue NOT IN ('Active','Pending') THEN CREATED_USER.DisplayName
			ELSE RESOLVED_USER.DisplayName END AS [Chris Resolved By]

	, SUM_FLAGS.[L1 to L2]
	, SUM_FLAGS.[L2 to L3]
	, SUM_FLAGS.[L1 to L3]
	, SUM_FLAGS.[L1 to Hardware]
	, IncidentDimvw.Region
	, IncidentDimvw.Location
	, Title_Region = case
		when patindex('%[^a-z][a-z][a-z][^a-z][a-z][a-z][a-z][^a-z]%', Left(IncidentDimvw.Title, 22)) > 0
			then rtrim(ltrim(substring(IncidentDimvw.Title, patindex('%[^a-z][a-z][a-z][^a-z][a-z][a-z][a-z][^a-z]%', IncidentDimvw.Title)+1, 2)))
		end
	, Title_Location = case
		when patindex('%[^a-z][a-z][a-z][^a-z][a-z][a-z][a-z][^a-z]%', Left(IncidentDimvw.Title, 22)) > 0
			then rtrim(ltrim(substring(IncidentDimvw.Title, patindex('%[^a-z][a-z][a-z][^a-z][a-z][a-z][a-z][^a-z]%', IncidentDimvw.Title)+ 4, 3)))
		end
	, Smart_Region = CASE 
		when patindex('%[^a-z][a-z][a-z][^a-z][a-z][a-z][a-z][^a-z]%', Left(IncidentDimvw.Title, 22)) > 0
			then rtrim(ltrim(substring(IncidentDimvw.Title, patindex('%[^a-z][a-z][a-z][^a-z][a-z][a-z][a-z][^a-z]%', IncidentDimvw.Title)+1, 2)))
			else IncidentDimvw.Region
		end
	, Smart_Location = CASE
		when patindex('%[^a-z][a-z][a-z][^a-z][a-z][a-z][a-z][^a-z]%', Left(IncidentDimvw.Title, 22)) > 0
			then rtrim(ltrim(substring(IncidentDimvw.Title, patindex('%[^a-z][a-z][a-z][^a-z][a-z][a-z][a-z][^a-z]%', IncidentDimvw.Title)+4, 3)))
			ELSE IncidentDimvw.Location
		end

	, [flag_AnalystNoCBN] = CTE_ASSIGNS_2.IncidentDimKey
	, [First Real Assign Date] = CTE_ASSIGNS_3.[Real Analyst Assign Date]
	, [Time to Response (M)] = datediff(mi, incidentdimvw.createddate, CTE_ASSIGNS_3.[Real Analyst Assign Date])

	, ONEPOS_LIST = CASE WHEN ( IncidentTierQueuesvw.IncidentTierQueuesId IN (@SupportGroup) OR IncidentTierQueuesvw.ParentId IN (@SupportGroupParent) ) THEN 1 END

	, [Last SG Grouping] = CASE 
		WHEN IncidentTierQueuesvw.IncidentTierQueuesId IN (7,63) then 'L1'
		WHEN IncidentTierQueuesvw.IncidentTierQueuesId IN (60) then 'L2'
		WHEN IncidentTierQueuesvw.IncidentTierQueuesId IN (67) THEN 'L3'
		WHEN IncidentTierQueuesvw.IncidentTierQueuesId IN (9,10,11,55,68) THEN 'L4'
		WHEN IncidentTierQueuesvw.IncidentTierQueuesId IN (56,61,65) THEN 'Aloha'
		WHEN IncidentTierQueuesvw.IncidentTierQueuesId IN (62) THEN 'L0'
		WHEN IncidentTierQueuesvw.IncidentTierQueuesId IN (8,12) THEN SG_NAME.DisplayName
		WHEN IncidentTierQueuesvw.PARENTID IN (7,8) THEN 'OTHER'
		ELSE 'OUTSIDE' END 
	, [First SG Grouping] = CASE 
		WHEN FIRST_SG.IncidentTierQueuesId IN (7,63) then 'L1'
		WHEN FIRST_SG.IncidentTierQueuesId IN (60) then 'L2'
		WHEN FIRST_SG.IncidentTierQueuesId IN (67) THEN 'L3'
		WHEN FIRST_SG.IncidentTierQueuesId IN (9,10,11,55,68) THEN 'L4'
		WHEN FIRST_SG.IncidentTierQueuesId IN (56,61,65) THEN 'Aloha'
		WHEN FIRST_SG.IncidentTierQueuesId IN (62) THEN 'L0'
		WHEN FIRST_SG.IncidentTierQueuesId IN (8,12) THEN FIRST_SG_NAME.DisplayName
		WHEN FIRST_SG.PARENTID IN (7,8) THEN 'OTHER'
		ELSE 'OUTSIDE' END 
		



	, [Incident Type] = CASE
	-- round 4 additions
		WHEN IncidentDimvw.Title LIKE '%xpi%' THEN 'XPI'
		WHEN IncidentDimvw.Title LIKE '%VALIDATION%' THEN 'Validation'
	-- round 3 additions
		WHEN IncidentDimvw.Title LIKE '%cartnado%' THEN 'Cartnado'
		WHEN IncidentDimvw.Title LIKE '%veribalance%' THEN 'Veribalance'	
		WHEN IncidentDimvw.Title LIKE '%Token%'THEN 'Token'
		WHEN IncidentDimvw.Title LIKE '%Customer display%' THEN 'Customer display'
		WHEN IncidentDimvw.Title LIKE '%Mpos%' OR IncidentDimvw.Title LIKE '%TAB%' THEN 'Mpos/Tab'


		WHEN IncidentDimvw.Title LIKE '%OK KEY%' OR IncidentDimvw.Title LIKE '%OK BUTTON%' 
			THEN 'OK key/button'
		WHEN IncidentDimvw.Title LIKE '%defect%' THEN 'Defect'
		WHEN IncidentDimvw.Title LIKE '%ERROR%' THEN 'Error'
		WHEN IncidentDimvw.Title LIKE '%FREEZ%' OR IncidentDimvw.Title LIKE '%FROZ%' 
			THEN 'Lane Frozen'
		WHEN IncidentDimvw.Title LIKE '%msr%' OR IncidentDimvw.Title LIKE '%pinpad%' 
			THEN 'MSR/Pinpad'
		WHEN IncidentDimvw.Title LIKE '%office client%'	THEN 'Office Client'
		WHEN IncidentDimvw.Title LIKE '%Unable to Remote%'	THEN 'Unable to Remote'
		WHEN IncidentDimvw.Title LIKE '%digital%'	THEN 'digital'
		WHEN IncidentDimvw.Title LIKE '%REWARD%' OR IncidentDimvw.Title LIKE '%REDEEM%' 
			OR IncidentDimvw.Title LIKE '%REDEMPTION%' 
			THEN 'Redemption Issues'
		WHEN IncidentDimvw.Title LIKE '%chip%'	THEN 'chip'
		WHEN IncidentDimvw.Title LIKE '%apple%'	OR IncidentDimvw.Title LIKE '%contactless%' 
			THEN 'Apple/Contactless'
		WHEN IncidentDimvw.Title LIKE '%Affinity%' OR IncidentDimvw.Title LIKE '%promo%' 
			OR IncidentDimvw.Title LIKE '%Aff%' 
			THEN 'Affinity/Promo'
		WHEN IncidentDimvw.Title LIKE '%variance%' THEN 'variance'
		WHEN IncidentDimvw.Title LIKE '%DOWN%' OR IncidentDimvw.Title LIKE '%OFFLINE%' 
			OR IncidentDimvw.Title LIKE '%outage%' 
			THEN 'Lane Down'
		WHEN IncidentDimvw.Title LIKE '%refund%'	THEN 'Refund'
		WHEN IncidentDimvw.Title LIKE '%LATENCY%' THEN 'Latency Issue'
		WHEN IncidentDimvw.Title LIKE '%Slow%'	THEN 'Slow'
		WHEN IncidentDimvw.Title LIKE '%android pay%' THEN 'Android Pay'
		WHEN ' ' +IncidentDimvw.Title + ' ' LIKE '%[^a-z]tap[^a-z]%' THEN 'Tap Issues'
		WHEN IncidentDimvw.Title LIKE '%SHUT%' OR IncidentDimvw.Title LIKE '%STUCK%' 
			THEN 'Lane Stuck'
		WHEN IncidentDimvw.Title LIKE '%EOD%' THEN 'EOD'
		END
	
	, INCIDENTDIMVW.Priority

	, StoreNumber = case when (patindex('%[^0-9][0-9][0-9][0-9][0-9][0-9][^0-9]%',' '+IncidentDimvw.Title)>0) 
		then rtrim(ltrim(substring(IncidentDimvw.Title,patindex('%[^0-9][0-9][0-9][0-9][0-9][0-9][^0-9]%',IncidentDimvw.Title)+1,5)))
		END
	, LaneAffected = case
		when CHARINDEX ('ALL LANE', UPPER(' ' +IncidentDimvw.Title)) > 0
			then 'All Lanes'
		when (CHARINDEX ( 'LANE' ,UPPER(' ' + IncidentDimvw.Title) ) > 0) 
			and REPLACE(REPLACE(LTRIM(RTRIM(substring(IncidentDimvw.Title,CHARINDEX ( 'LANE' ,UPPER(' ' + IncidentDimvw.Title) ) + 4,4))),',',''),'-','') like '%[0-9][0-9]%'		
			then replace(replace(REPLACE(REPLACE(LTRIM(RTRIM(substring(IncidentDimvw.Title,CHARINDEX ( 'LANE' ,UPPER(' ' + IncidentDimvw.Title) ) + 4,4))),',',''),'-',''), '#', ''), '/', '')
		when (CHARINDEX ( 'REG' ,UPPER(' ' + IncidentDimvw.Title) ) > 0) 
			and replace(REPLACE(REPLACE(LTRIM(RTRIM(substring(IncidentDimvw.Title,CHARINDEX ( 'REG' ,UPPER(' ' + IncidentDimvw.Title) ) + 3,3))),',',''),'-',''),'#', '') like '%[0-9][0-9]%'
			then replace(replace(REPLACE(REPLACE(LTRIM(RTRIM(substring(IncidentDimvw.Title,CHARINDEX ( 'REG' ,UPPER(' ' + IncidentDimvw.Title) ) + 3,3))),',',''),'-',''),'#', ''), '/', '')
		when (CHARINDEX ( 'REGISTER' ,UPPER(' ' + IncidentDimvw.Title) ) > 0) 
			and replace(REPLACE(REPLACE(LTRIM(RTRIM(substring(IncidentDimvw.Title,CHARINDEX ( 'REGISTER' ,UPPER(' ' + IncidentDimvw.Title) ) + 8,3))),',',''),'-',''),'#', '') like '%[0-9][0-9]%'
			then replace(replace(REPLACE(REPLACE(LTRIM(RTRIM(substring(IncidentDimvw.Title,CHARINDEX ( 'REGISTER' ,UPPER(' ' + IncidentDimvw.Title) ) + 8,3))),',',''),'-',''),'#', ''), '/', '')
		END	


	-- round 4 additions
	, IncidentDimvw.External_Ref_ID
	, [External_Ref_NCR_Ticket] = CASE
		WHEN PATINDEX('%[^0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][^0-9]%', ' ' + IncidentDimvw.External_Ref_ID + ' ') > 0
		THEN RTRIM(LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(IncidentDimvw.External_Ref_ID, PATINDEX('%[^0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][^0-9]%', ' ' + IncidentDimvw.External_Ref_ID + ' '), 10),'/', ''), ',', ''), ')', '')))
		END
	, [External_Ref_Defect] = CASE
		WHEN PATINDEX('%[^0-9][0-9][0-9][0-9][0-9][^0-9]%', ' ' + IncidentDimvw.External_Ref_ID + ' ') > 0
		THEN RTRIM(LTRIM(SUBSTRING(IncidentDimvw.External_Ref_ID, PATINDEX('%[^0-9][0-9][0-9][0-9][0-9][^0-9]%', ' ' + IncidentDimvw.External_Ref_ID + ' '), 4)))
		END

	-- round 5 additions - multi-resolves
	, RESOLVE_AGGREGATES.multiple_resolve_flag
	, RESOLVE_AGGREGATES.num_resolves
	, incidentdimvw.ClosedDate
	, IncidentDimvw.Description

	-- round 6 additions - more descriptor info for extended extended metrics sheet (not the automated export)
	, Resolution_Description = incidentdimvw.ResolutionDescription
	, [Resolution_Category] = RESOLUTION_CATEGORY_NAME.DISPLAYNAME
	, [Classification] = IncidentClassificationvw.IncidentClassificationValue

FROM CTE 
 JOIN CTE_TEAMS ON CTE.IncidentDimKey=CTE_TEAMS.IncidentDimKey
 JOIN CTE_ASSIGNS ON CTE.WorkItemDimKey=CTE_ASSIGNS.WorkItemDimKey
 JOIN IncidentDimvw ON CTE.IncidentDimKey=IncidentDimvw.IncidentDimKey
	JOIN EntityDimvw ON IncidentDimvw.EntityDimKey = EntityDimvw.EntityDimKey
	JOIN IncidentTierQueuesvw ON IncidentDimvw.TierQueue_IncidentTierQueuesId=IncidentTierQueuesvw.IncidentTierQueuesId
	JOIN DisplayStringDimvw SG_NAME ON IncidentTierQueuesvw.ENUMTYPEID = SG_NAME.BASEMANAGEDENTITYID
		AND SG_NAME.LANGUAGECODE = 'ENU'
	JOIN IncidentStatusvw ON IncidentDimvw.Status_IncidentStatusId=IncidentStatusvw.IncidentStatusId
	 
		
		-- GET FIRST SUPPORT GROUP
		LEFT JOIN IncidentTierQueueDurationFactvw ON CTE_TEAMS.IncidentDimKey = IncidentTierQueueDurationFactvw.IncidentDimKey
			AND CTE_TEAMS.MIN_SG_DATE = IncidentTierQueueDurationFactvw.StartDateTime
		LEFT JOIN IncidentTierQueuesvw FIRST_SG ON IncidentTierQueueDurationFactvw.IncidentTierQueuesId=FIRST_SG.IncidentTierQueuesId
		LEFT JOIN DISPLAYSTRINGDIMVW FIRST_SG_NAME ON FIRST_SG.ENUMTYPEID = FIRST_SG_NAME.BASEMANAGEDENTITYID
			AND FIRST_SG_NAME.LANGUAGECODE = 'ENU'

		-- GET FIRST/LAST ANALYST
		LEFT JOIN WorkItemAssignedToUserFactvw FIRST_ASSIGNED_TO 
			ON CTE_ASSIGNS.WorkItemDimKey = FIRST_ASSIGNED_TO.WorkItemDimKey
			AND CTE_ASSIGNS.MIN_ASSIGN_DATE = FIRST_ASSIGNED_TO.CreatedDate
		LEFT JOIN UserDimvw FIRST_ASSIGNED_TO_USER ON FIRST_ASSIGNED_TO.WorkItemAssignedToUser_UserDimKey=FIRST_ASSIGNED_TO_USER.UserDimKey

		LEFT JOIN WorkItemAssignedToUserFactvw LAST_ASSIGNED_TO 
			ON CTE_ASSIGNS.WorkItemDimKey = LAST_ASSIGNED_TO.WorkItemDimKey
			AND CTE_ASSIGNS.MAX_ASSIGN_DATE = LAST_ASSIGNED_TO.CreatedDate
		LEFT JOIN UserDimvw LAST_ASSIGNED_TO_USER ON LAST_ASSIGNED_TO.WorkItemAssignedToUser_UserDimKey=LAST_ASSIGNED_TO_USER.UserDimKey

		-- GET [FIRST] CREATED USER
		LEFT JOIN CTE_CREATED_USER ON CTE.WorkItemDimKey = CTE_CREATED_USER.WorkItemDimKey
		LEFT JOIN WorkItemCreatedByUserFactvw 
			ON CTE_CREATED_USER.WorkItemDimKey = WorkItemCreatedByUserFactvw.WorkItemDimKey
			AND CTE_CREATED_USER.MIN_CREATED_DATE = WorkItemCreatedByUserFactvw.CreatedDate
		LEFT JOIN UserDimvw CREATED_USER ON WorkItemCreatedByUserFactvw.WorkItemCreatedByUser_UserDimKey = CREATED_USER.UserDimKey

		-- GET [LAST] RESOLVED USER
		LEFT JOIN CTE_RESOLVED_USER ON CTE.IncidentDimKey = CTE_RESOLVED_USER.IncidentDimKey
		LEFT JOIN IncidentResolvedByUserFactvw
			ON CTE_RESOLVED_USER.IncidentDimKey = IncidentResolvedByUserFactvw.IncidentDimKey
			AND CTE_RESOLVED_USER.MAX_RESOLVED_DATE = IncidentResolvedByUserFactvw.CreatedDate
		LEFT JOIN UserDimvw RESOLVED_USER ON IncidentResolvedByUserFactvw.TroubleTicketResolvedByUser_UserDimKey = RESOLVED_USER.UserDimKey

		-- ESCALATION
		LEFT JOIN SUM_FLAGS ON CTE.IncidentDimKey = SUM_FLAGS.IncidentDimKey

		-- JOIN TO ASSIGNED USER 2 - ALL IRS WITH 1 'REAL ANALYST' ASSIGNMENT
		LEFT JOIN CTE_ASSIGNS_2 ON CTE.IncidentDimKey = CTE_ASSIGNS_2.IncidentDimKey

		-- to get first real-analyst assign date
		LEFT JOIN CTE_ASSIGNS_3 ON CTE.INCIDENTDIMKEY = CTE_ASSIGNS_3.INCIDENTDIMKEY

		-- get number of resolves 
		LEFT JOIN 
			(	SELECT [IncidentDimKey]
					, num_resolves = count(case when IncidentStatusId = 4 then 1 end)
					, multiple_resolve_flag = case when count(case when incidentstatusid = 4 then 1 end) > 1 then 1 end
				FROM [dbo].[IncidentStatusDurationFactvw]
				GROUP BY IncidentDimKey )
		RESOLVE_AGGREGATES ON IncidentDimvw.IncidentDimKey = RESOLVE_AGGREGATES.INCIDENTDIMKEY

		-- other dimensions
		  LEFT OUTER JOIN IncidentClassificationvw
			ON IncidentDimvw.Classification_IncidentClassificationId = IncidentClassificationvw.IncidentClassificationId
		  LEFT OUTER JOIN IncidentResolutionCategoryvw
			ON IncidentDimvw.ResolutionCategory_IncidentResolutionCategoryId = IncidentResolutionCategoryvw.IncidentResolutionCategoryId
			LEFT JOIN DISPLAYSTRINGDIMVW RESOLUTION_CATEGORY_NAME ON RESOLUTION_CATEGORY_NAME.BaseManagedEntityId = IncidentResolutionCategoryvw.ENUMTYPEID
				AND RESOLUTION_CATEGORY_NAME.LANGUAGECODE = 'ENU'

/* runtime log */
/*
8/4/2017 - 51 secs - 7449 rows

*/

/* NOTES */
/* CTES ARE LEFT JOINED WHERE APPROPRIATE - MAIN QUERY DOES NOT NEED TO

COUNTING ON COLUMN VALUE - NOT COUNT(*) 

FIRST ASSIGNED - SOMETIMES BEFORE CREATED DATE, SO NEGATIVE VALUE



SSRS METRICS - TIME BASED
	1. FIRST CALL FIX
	2. FIRST DAY RESOLVE

*** FCFR AND FDR TO BE DETERMINED IN SSRS (TIMEZONE DEPENDENT) ***


[flag_AnalystNoCBN]
	- this returns a value if the ticket either had <= 1 assigned analyst, OR if the ticket had 2 analysts, with first analyst being Call back needed

=iif( 
Fields!NUM_TEAMS.Value=1 
	and (Fields!NUM_ASSIGNS.Value<= 1 OR IsNothing(Fields!flag_AnalystNoCBN.Value) = false)
	and Fields!FIRST_DAY_RESOLVE.Value = 1
,1,0)



**************************
LISTS
**************************


-----------
ONEPOS LIST
-----------

WITH CTE AS (
SELECT IncidentDimvw.IncidentDimKey
	, IncidentDimvw.EntityDimKey
	, WorkItemDimvw.WorkItemDimKey
FROM IncidentDimvw JOIN WorkItemDimvw ON IncidentDimvw.EntityDimKey = WorkItemDimvw.EntityDimKey

LEFT JOIN IncidentTierQueuesvw ON IncidentDimvw.TierQueue_IncidentTierQueuesId=IncidentTierQueuesvw.IncidentTierQueuesId
WHERE ( IncidentTierQueuesvw.IncidentTierQueuesId IN (@SupportGroup) OR IncidentTierQueuesvw.ParentId IN (@SupportGroupParent) )
	AND 
	(
		( IncidentDimvw.CreatedDate >= @START_DATE  OR @START_DATE IS NULL)
		AND 
		( IncidentDimvw.CreatedDate <= @END_DATE  OR @END_DATE IS NULL )
	)
)


----------------------------------------
ANY IR THAT HAS EVER TOUCHED ONEPOS (THE PARAMETERS) - LIST
----------------------------------------

WITH CTE AS (
		SELECT DISTINCT IncidentDimvw.IncidentDimKey
			,WorkItemDimvw.EntityDimKey
			,WorkItemDimvw.WorkItemDimKey
		FROM IncidentTierQueueDurationFactvw JOIN IncidentTierQueuesvw ON IncidentTierQueueDurationFactvw.IncidentTierQueuesId = IncidentTierQueuesvw.IncidentTierQueuesId
			JOIN IncidentDimvw ON IncidentTierQueueDurationFactvw.IncidentDimKey = IncidentDimvw.IncidentDimKey
			JOIN WorkItemDimvw ON IncidentDimvw.EntityDimKey = WorkItemDimvw.EntityDimKey
		WHERE ( IncidentTierQueuesvw.IncidentTierQueuesId IN (@SupportGroup) OR IncidentTierQueuesvw.ParentId IN (@SupportGroupParent) )
			AND
			(
				( IncidentDimvw.CreatedDate >= @START_DATE OR @START_DATE IS NULL )
				AND
				( IncidentDimvw.CreatedDate <= @END_DATE  OR @END_DATE IS NULL )
			)
)

*/