/* TRANSFERRED OR RESOLVED REPORT - by team

	PURPOSE: 
	For a given list of IRs transferred into a team, calculate how many were transferred to another team, or Resolved in the team

	Backstory: 
	Lori/Brian expressed interest in seeing what quantities of tickets that come in are transferred vs resolved by the teams.
	Answers the question: "what portion of tickets does this team resolve? how many tickets on average are they passing?"
	Further analysis into passed/resolved tickets will show insight into knowledge gaps

	Note: 
		using tier queue duration table grain - aka team assignments
		some assignments/IRs do not have resolve dates OR end times to the support group, yet their status changed to resolved.
			-> these tickets were likely resolved via pager duty

	Method/Description:
		Look at team assignment history table
		filter by records assigned to @team within @time period

		Metric:
		Check if either the resolve date or team_finish date came first (or if null etc)
		use this to determine which were transferred and resolved (handled) by a team

	Note:
		referring to Incident Resolved date, since this value is singular. Using status_resolve time would create duplicates...

	Changelog:
		5/22/2017 - adding escalated teams
		7/17/2017 - revisited query for use in exec metrics; added note
*/


-- Variables
--DECLARE @START DATE = '2017-05-01'
--DECLARE @END DATE	= '2017-05-05'
--DECLARE @SupportGroup VARCHAR(MAX) = 7
--;


-- MAIN QUERY - CALC METRIC
SELECT
	INCIDENTDIMVW.Id
	,SG_NAMES.DISPLAYNAME AS [SUPPORT GROUP]
	,INCIDENTSTATUSVW.INCIDENTSTATUSVALUE AS [CURRENT STATUS]
	,IncidentTierQueueDurationFactvw.StartDateTime
	,IncidentTierQueueDurationFactvw.FinishDateTime
	,INCIDENTDIMVW.CreatedDate
	,INCIDENTDIMVW.ResolvedDate
	,[RESOLVED STATUS TIME]	= [IncidentStatusDurationFactvw].STARTDATETIME

	-- METRIC: CHECK IF TRANSFERRED / RESOLVED / RESOLVED VIA PAGER DUTY / STILL ASSIGNED
	,[TRANSFERRED OR RESOLVED] = CASE 
		WHEN IncidentTierQueueDurationFactvw.FINISHDATETIME < INCIDENTDIMVW.RESOLVEDDATE
			OR IncidentTierQueueDurationFactvw.FINISHDATETIME IS NOT NULL AND INCIDENTDIMVW.RESOLVEDDATE IS NULL
			THEN 'TRANSFERRED' 
		WHEN INCIDENTDIMVW.RESOLVEDDATE < IncidentTierQueueDurationFactvw.FINISHDATETIME 
			OR INCIDENTDIMVW.RESOLVEDDATE IS NOT NULL AND IncidentTierQueueDurationFactvw.FINISHDATETIME IS NULL
			THEN 'RESOLVED'
		WHEN INCIDENTDIMVW.RESOLVEDDATE IS NULL AND IncidentTierQueueDurationFactvw.FINISHDATETIME IS NULL
			AND [IncidentStatusDurationFactvw].STARTDATETIME IS NOT NULL 
			THEN 'RESOLVED VIA PAGER DUTY'
		WHEN INCIDENTDIMVW.RESOLVEDDATE IS NULL AND IncidentTierQueueDurationFactvw.FINISHDATETIME IS NULL
			AND [IncidentStatusDurationFactvw].STARTDATETIME IS NULL 
			THEN 'STILL ASSIGNED'
		ELSE 'ERROR'
	END
	,PreviousTeam = PREV_TEAM_NAME.displayname
	,EscalatedTeam = ESCALATED_TEAM_NAME.DisplayName

	,[TeamLevel] = CASE 
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId IN (7,63) THEN 1
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId = 60 THEN 2
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId IN (67) THEN 3
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId IN (9, 10, 11, 55, 68) THEN 4
		END
	,[EscalatedTeamLevel] = CASE
			WHEN ESCALATED_TEAM.IncidentTierQueuesId IN (7,63) THEN 1
			WHEN ESCALATED_TEAM.IncidentTierQueuesId = 60 THEN 2
			WHEN ESCALATED_TEAM.IncidentTierQueuesId IN (67) THEN 3
			WHEN ESCALATED_TEAM.IncidentTierQueuesId IN (9, 10, 11, 55, 68) THEN 4
		END

	,[EscalationDirection] = CASE 
		WHEN CASE 
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId IN (7,63) THEN 1
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId = 60 THEN 2
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId IN (67) THEN 3
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId IN (9, 10, 11, 55, 68) THEN 4
		END < CASE
			WHEN ESCALATED_TEAM.IncidentTierQueuesId IN (7,63) THEN 1
			WHEN ESCALATED_TEAM.IncidentTierQueuesId = 60 THEN 2
			WHEN ESCALATED_TEAM.IncidentTierQueuesId IN (67) THEN 3
			WHEN ESCALATED_TEAM.IncidentTierQueuesId IN (9, 10, 11, 55, 68) THEN 4
		END THEN 'Escalated Up'
		WHEN CASE 
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId IN (7,63) THEN 1
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId = 60 THEN 2
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId IN (67) THEN 3
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId IN (9, 10, 11, 55, 68) THEN 4
		END < CASE
			WHEN ESCALATED_TEAM.IncidentTierQueuesId IN (7,63) THEN 1
			WHEN ESCALATED_TEAM.IncidentTierQueuesId = 60 THEN 2
			WHEN ESCALATED_TEAM.IncidentTierQueuesId IN (67) THEN 3
			WHEN ESCALATED_TEAM.IncidentTierQueuesId IN (9, 10, 11, 55, 68) THEN 4
		END THEN 'Escalated Down'
		WHEN CASE 
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId IN (7,63) THEN 1
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId = 60 THEN 2
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId IN (67) THEN 3
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId IN (9, 10, 11, 55, 68) THEN 4
		END = CASE
			WHEN ESCALATED_TEAM.IncidentTierQueuesId IN (7,63) THEN 1
			WHEN ESCALATED_TEAM.IncidentTierQueuesId = 60 THEN 2
			WHEN ESCALATED_TEAM.IncidentTierQueuesId IN (67) THEN 3
			WHEN ESCALATED_TEAM.IncidentTierQueuesId IN (9, 10, 11, 55, 68) THEN 4
		END THEN 'Lateral Transfer'
	END

	, Priority = 'P' + cast(incidentdimvw.priority as varchar)
	, ASSIGNED_USER_AT_RESOLVE_TIME = ASSIGNED_USER_AT_RESOLVE_TIME.DISPLAYNAME

FROM IncidentTierQueueDurationFactvw 
	JOIN IncidentTierQueuesvw ON IncidentTierQueueDurationFactvw.IncidentTierQueuesId = IncidentTierQueuesvw.IncidentTierQueuesId
	JOIN DisplayStringDimvw SG_NAMES ON IncidentTierQueuesvw.[EnumTypeId] = SG_NAMES.BaseManagedEntityId
		AND SG_NAMES.LANGUAGECODE = 'ENU'
	JOIN INCIDENTDIMVW ON IncidentTierQueueDurationFactvw.IncidentDimKey = INCIDENTDIMVW.INCIDENTDIMKEY
	JOIN INCIDENTSTATUSVW ON INCIDENTDIMVW.STATUS_INCIDENTSTATUSID = INCIDENTSTATUSVW.INCIDENTSTATUSID


	-- check for time status changed to Resolved for true indicator of 'not resolved'
	LEFT JOIN 
		(	SELECT [IncidentDimKey], MAX([StartDateTime]) MAXDATE
			FROM [dbo].[IncidentStatusDurationFactvw]
			WHERE [IncidentStatusId] = 4
			GROUP BY IncidentDimKey )
	MAX_RESOLVE_STATUS ON IncidentDimvw.IncidentDimKey = MAX_RESOLVE_STATUS.INCIDENTDIMKEY
	LEFT JOIN [dbo].[IncidentStatusDurationFactvw] 
		ON MAX_RESOLVE_STATUS.INCIDENTDIMKEY = [dbo].[IncidentStatusDurationFactvw].INCIDENTDIMKEY
		AND [dbo].[IncidentStatusDurationFactvw].STARTDATETIME = MAX_RESOLVE_STATUS.MAXDATE


	-- escalated team
	LEFT JOIN IncidentTierQueueDurationFactvw ESCALATED 
		ON IncidentTierQueueDurationFactvw.IncidentDimKey = ESCALATED.IncidentDimKey
		AND IncidentTierQueueDurationFactvw.FinishDateTime = ESCALATED.StartDateTime
		LEFT JOIN IncidentTierQueuesvw ESCALATED_TEAM ON ESCALATED.IncidentTierQueuesId = ESCALATED_TEAM.IncidentTierQueuesId
		LEFT JOIN DisplayStringDimvw ESCALATED_TEAM_NAME 
			ON ESCALATED_TEAM.EnumTypeId = ESCALATED_TEAM_NAME.BASEMANAGEDENTITYID
			AND ESCALATED_TEAM_NAME.LanguageCode = 'ENU'

	-- prev team
	LEFT JOIN IncidentTierQueueDurationFactvw PREV 
		ON IncidentTierQueueDurationFactvw.IncidentDimKey = PREV.IncidentDimKey
		AND IncidentTierQueueDurationFactvw.StartDateTime = PREV.FinishDateTime
		LEFT JOIN IncidentTierQueuesvw PREV_TEAM ON PREV.IncidentTierQueuesId = PREV_TEAM.IncidentTierQueuesId
		LEFT JOIN DisplayStringDimvw PREV_TEAM_NAME 
			ON PREV_TEAM.EnumTypeId = PREV_TEAM_NAME.BASEMANAGEDENTITYID
			AND PREV_TEAM_NAME.LanguageCode = 'ENU'


	-- resolved user at resolved status time (from above)
	LEFT JOIN WORKITEMDIMVW ON INCIDENTDIMVW.ENTITYDIMKEY = WORKITEMDIMVW.ENTITYDIMKEY
	LEFT JOIN WORKITEMASSIGNEDTOUSERFACTVW ASSIGNED_USER_AT_RESOLVE
		ON ASSIGNED_USER_AT_RESOLVE.WORKITEMDIMKEY = WORKITEMDIMVW.WORKITEMDIMKEY
		AND MAX_RESOLVE_STATUS.MAXDATE BETWEEN ASSIGNED_USER_AT_RESOLVE.CREATEDDATE AND ASSIGNED_USER_AT_RESOLVE.DELETEDDATE
	LEFT JOIN USERDIMVW ASSIGNED_USER_AT_RESOLVE_TIME 
		ON ASSIGNED_USER_AT_RESOLVE.[WorkItemAssignedToUser_UserDimKey] = ASSIGNED_USER_AT_RESOLVE_TIME.USERDIMKEY

WHERE 
	IncidentTierQueueDurationFactvw.StartDateTime BETWEEN @START AND @END
	AND IncidentTierQueueDurationFactvw.IncidentTierQueuesId IN (@SupportGroup)


ORDER BY CREATEDDATE, Id, StartDateTime



