/* Open ticket - store / region lookup 
Requested by: (player coaches)
*/
SET NOCOUNT ON;

--DECLARE @REGION VARCHAR(2) = 'NE'
--DECLARE @LOCATION VARCHAR(3) = 'che'

SELECT IncidentDimvw.Id
	, IncidentDimvw.CreatedDate
	, SG_NAME.DISPLAYNAME							AS [SUPPORT GROUP]
	, Priority = 'P' + cast(INCIDENTDIMVW.Priority as varchar(max))
	, IncidentDimvw.Title
	, IncidentDimvw.Description
	, IncidentStatusvw.IncidentStatusValue			AS [STATUS]
	
	, IncidentDimvw.Region
	, IncidentDimvw.Location
	, Smart_Region = CASE 
		when left(rtrim(ltrim(substring(IncidentDimvw.Title, patindex('%[^a-z][a-z][a-z][^a-z][a-z][a-z][a-z][^a-z]%', IncidentDimvw.Title)+1, 2))),2)
			IN ('MA','PN','SP','NC','RM','FL','NA','SW','SO','MW','NE','CE','TS')
			then rtrim(ltrim(substring(IncidentDimvw.Title, patindex('%[^a-z][a-z][a-z][^a-z][a-z][a-z][a-z][^a-z]%', IncidentDimvw.Title)+1, 2)))
		when left(rtrim(ltrim(substring(IncidentDimvw.Title, patindex('%[^a-z0-9][0-9][0-9][0-9][^a-z0-9][a-z][a-z][a-z][^a-z]%', IncidentDimvw.Title)+1, 2))),3) = '365'
			then rtrim(ltrim(substring(IncidentDimvw.Title, patindex('%[^a-z0-9][0-9][0-9][0-9][^a-z0-9][a-z][a-z][a-z][^a-z]%', IncidentDimvw.Title)+1, 3)))
			 else IncidentDimvw.Region
		end
	, Smart_Location = CASE
		when left(rtrim(ltrim(substring(IncidentDimvw.Title, patindex('%[^a-z][a-z][a-z][^a-z][a-z][a-z][a-z][^a-z]%', IncidentDimvw.Title)+1, 2))),2)
			IN ('MA','PN','SP','NC','RM','FL','NA','SW','SO','MW','NE','CE','TS')
			then rtrim(ltrim(substring(IncidentDimvw.Title, patindex('%[^a-z][a-z][a-z][^a-z][a-z][a-z][a-z][^a-z]%', IncidentDimvw.Title)+4, 3)))
		when left(rtrim(ltrim(substring(IncidentDimvw.Title, patindex('%[^a-z0-9][0-9][0-9][0-9][^a-z0-9][a-z][a-z][a-z][^a-z]%', IncidentDimvw.Title)+1, 2))),3) = '365'
			then rtrim(ltrim(substring(IncidentDimvw.Title, patindex('%[^a-z0-9][0-9][0-9][0-9][^a-z0-9][a-z][a-z][a-z][^a-z]%', IncidentDimvw.Title)+5, 3)))
			ELSE IncidentDimvw.Location
		end

		
FROM IncidentDimvw 
	JOIN IncidentTierQueuesvw ON IncidentDimvw.TierQueue_IncidentTierQueuesId=IncidentTierQueuesvw.IncidentTierQueuesId
	JOIN DisplayStringDimvw SG_NAME ON IncidentTierQueuesvw.ENUMTYPEID = SG_NAME.BASEMANAGEDENTITYID
		AND SG_NAME.LANGUAGECODE = 'ENU'
	JOIN IncidentStatusvw ON IncidentDimvw.Status_IncidentStatusId=IncidentStatusvw.IncidentStatusId
	 
WHERE
		INCIDENTDIMVW.CREATEDDATE >= '2016-01-01'
		AND IncidentStatusvw.IncidentStatusValue IN ('ACTIVE', 'PENDING')
		AND (IncidentTierQueuesvw.INCIDENTTIERQUEUESID IN (7,12) OR IncidentTierQueuesvw.PARENTID IN (7,8))


		--AND CASE when patindex('%[^a-z][a-z][a-z][^a-z][a-z][a-z][a-z][^a-z]%', Left(IncidentDimvw.Title, 22)) > 0
		--		then rtrim(ltrim(substring(IncidentDimvw.Title, patindex('%[^a-z][a-z][a-z][^a-z][a-z][a-z][a-z][^a-z]%', IncidentDimvw.Title)+1, 2)))
		--		else IncidentDimvw.Region
		--	end
		--	IN (@REGION)
		--AND	CASE when patindex('%[^a-z][a-z][a-z][^a-z][a-z][a-z][a-z][^a-z]%', Left(IncidentDimvw.Title, 22)) > 0
		--		then rtrim(ltrim(substring(IncidentDimvw.Title, patindex('%[^a-z][a-z][a-z][^a-z][a-z][a-z][a-z][^a-z]%', IncidentDimvw.Title)+4, 3)))
		--		ELSE IncidentDimvw.Location
		--	end
		--	IN (@LOCATION)

ORDER BY IncidentDimvw.CreatedDate



















/* old 
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


*/