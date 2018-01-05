/* 

Escalations - MODULAR
Raw Escalation Volume - OnePOS IR Team Changes

Created by: Chris Jabr
Created: 4/18/2017

Purpose: Modular SSRS dataset that can find the escalations / pass backs between any support groups chosen via parameters

Note:
	INCIDENTS ONLY CURRENTLY - NEED A DIFFERENT QUERY FOR SERVICE REQUEST POTENTIALLY....
		- can either use separate query, or resort to support group display names, and distinguish somehow in end query...

*/


-- Variables
--	DECLARE @STARTDATE AS DATE = '2017-05-01'
--	DECLARE @ENDDATE AS DATE = '2017-05-05'
	
--	DECLARE @FROM_TEAM_1A VARCHAR(MAX) = 5
--	DECLARE @FROM_TEAM_1B VARCHAR(MAX) = NULL
--	DECLARE @TO_TEAM_1A VARCHAR(MAX) = 7
--	DECLARE @TO_TEAM_1B VARCHAR(MAX) = NULL


--	DECLARE @FROM_TEAM_2A VARCHAR(MAX) = 0
--	DECLARE @FROM_TEAM_2B VARCHAR(MAX) = NULL
--	DECLARE @TO_TEAM_2A VARCHAR(MAX) = 0
--	DECLARE @TO_TEAM_2B VARCHAR(MAX) = null
--;

-- START LIST: IRs with [FROM_TEAM / TO_TEAM PARAMETERS] assignments between date range
WITH CTE AS (
		SELECT DISTINCT IncidentDimKey
		FROM IncidentTierQueueDurationFactvw JOIN IncidentTierQueuesvw ON IncidentTierQueueDurationFactvw.IncidentTierQueuesId=IncidentTierQueuesvw.IncidentTierQueuesId
		WHERE StartDateTime BETWEEN @STARTDATE AND @ENDDATE 
			AND IncidentTierQueuesvw.IncidentTierQueuesId 
				IN (@FROM_TEAM_1A,  @FROM_TEAM_2A, 
					@TO_TEAM_1A,  @TO_TEAM_2A)
)

-- CREATE ESCALATION FLAGS
, FLAGS AS (
		SELECT IncidentDimvw.Id
			,IncidentTierQueueDurationFactvw.StartDateTime
			,LAG(SG_NAMES.DisplayName) OVER(PARTITION BY IncidentDimvw.Id ORDER BY IncidentTierQueueDurationFactvw.StartDateTime)
					AS [FROM]
			,SG_NAMES.DisplayName AS [TO]

			-- to/from teams 1
			,CASE WHEN LAG(IncidentTierQueuesvw.IncidentTierQueuesId) OVER(PARTITION BY IncidentDimvw.Id ORDER BY IncidentTierQueueDurationFactvw.StartDateTime)
				IN (@FROM_TEAM_1A) AND IncidentTierQueuesvw.IncidentTierQueuesId IN (@TO_TEAM_1A)
				THEN 1 ELSE 0 END AS [Teams 1 Escalations]
			,CASE WHEN 
				LAG(IncidentTierQueuesvw.IncidentTierQueuesId) OVER(PARTITION BY IncidentDimvw.Id ORDER BY IncidentTierQueueDurationFactvw.StartDateTime) 
					IN (@FROM_TEAM_1A) 
				AND IncidentTierQueuesvw.IncidentTierQueuesId IN (@TO_TEAM_1A)
				AND LEAD(IncidentTierQueuesvw.IncidentTierQueuesId) OVER(PARTITION BY IncidentDimvw.Id ORDER BY IncidentTierQueueDurationFactvw.StartDateTime) 
					IN (@FROM_TEAM_1A)
				THEN 1 ELSE 0 END AS [TEAMS 1 GETS PASSED BACK]

			-- to/from teams 2
			,CASE WHEN LAG(IncidentTierQueuesvw.IncidentTierQueuesId) OVER(PARTITION BY IncidentDimvw.Id ORDER BY IncidentTierQueueDurationFactvw.StartDateTime)
				IN (@FROM_TEAM_2A) AND IncidentTierQueuesvw.IncidentTierQueuesId IN (@TO_TEAM_2A) 
				THEN 1 ELSE 0 END AS [Teams 2 Escalations]

			,CASE WHEN 
				LAG(IncidentTierQueuesvw.IncidentTierQueuesId) OVER(PARTITION BY IncidentDimvw.Id ORDER BY IncidentTierQueueDurationFactvw.StartDateTime) 
					IN (@FROM_TEAM_2A) 
				AND IncidentTierQueuesvw.IncidentTierQueuesId IN (@TO_TEAM_2A)
				AND LEAD(IncidentTierQueuesvw.IncidentTierQueuesId) OVER(PARTITION BY IncidentDimvw.Id ORDER BY IncidentTierQueueDurationFactvw.StartDateTime) 
					IN (@FROM_TEAM_2A)
				THEN 1 ELSE 0 END AS [TEAMS 2 GETS PASSED BACK]

			,Source = ISvw.INCIDENTSOURCEVALUE
			,IncidentDimvw.Title
			,IncidentDimvw.Description
			--,[Previous Analyst] = PREV_ANALYST.Displayname


		FROM CTE JOIN IncidentTierQueueDurationFactvw ON CTE.IncidentDimKey = IncidentTierQueueDurationFactvw.IncidentDimKey
			JOIN IncidentTierQueuesvw ON IncidentTierQueueDurationFactvw.IncidentTierQueuesId = IncidentTierQueuesvw.IncidentTierQueuesId
			LEFT JOIN DisplayStringDimvw SG_NAMES ON IncidentTierQueuesvw.EnumTypeId = SG_NAMES.BaseManagedEntityId
				AND SG_NAMES.LanguageCode = 'ENU'
			JOIN IncidentDimvw ON CTE.IncidentDimKey = IncidentDimvw.IncidentDimKey

			LEFT JOIN IncidentSourcevw ISvw ON IncidentDimvw.Source_IncidentSourceId = ISvw.INCIDENTSOURCEID

			-- PASSING ANALYST; 7734 RECORDS
			LEFT JOIN WORKITEMDIMVW W ON INCIDENTDIMVW.ENTITYDIMKEY = W.ENTITYDIMKEY

--			LEFT JOIN WORKITEMASSIGNEDTOUSERFACTVW WIATU ON W.WorkItemDimKey = WIATU.WORKITEMDIMKEY
--				AND (
--					(WIATU.CREATEDDATE < IncidentTierQueueDurationFactvw.StartDateTime 
--						AND WIATU.DELETEDDATE >= IncidentTierQueueDurationFactvw.StartDateTime)
--					OR WIATU.CREATEDDATE < IncidentTierQueueDurationFactvw.StartDateTime AND WIATU.DELETEDDATE IS NULL
--				)
--			LEFT JOIN USERDIMVW PREV_ANALYST ON WIATU.WORKITEMASSIGNEDTOUSER_USERDIMKEY = PREV_ANALYST.USERDIMKEY
)

SELECT * FROM FLAGS
ORDER BY Id, StartDateTime