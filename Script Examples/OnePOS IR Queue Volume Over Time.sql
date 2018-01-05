/* OnePOS IR Queue Volume Over Time 

Created by:	Chris Jabr
Date:		5/23/2017

Purpose: 
			See open ticket volume over time; see the open ticket volume at any point in time

Query Description: 
			grabs the open incidents [for OnePOS] as they were at a starting point in time.
			From this datetime, increment by 1 [hour OR day] and deposit the results in a table variable
			do this until end datetime is reached


Note:
			daylight savings will still be a pain - since current method recursively adds a [hour/day] to the start time
			case when correlated subquery check for duplicate non-null enddate statuses using max(start) is more efficient in the join than where clause


Use:
			modifying by day/hour for two different SSRS queries
			day - pulls info at specific time - increments by day - adjusts for DLS
			hour - pulls info at specific time - increment by hour - aggregate due to data size

Log:
			8/10/2017 - added flag for 'adult' IRs - IRs with no children. Also displays the ParentID if the IR has one.
			10/10/2017 - DISTINCT records to remove duplicate assignments

*/

SET NOCOUNT ON;

declare @Date_Adjusted datetime		= '2017-07-02 12:29:00'  --'2017-04-29 12:29:00'
declare @EndDate datetime			= '2017-07-06 23:29:00'
declare @Increment varchar(max) 	= 'Hour' -- or Hour

declare @ResultTable table(ID varchar(max), [Status] varchar(max), [Support Group] varchar(max),  [DateTime] datetime
	--, [Date] date, [Hour] int		[Assigned To] varchar(max),
	,  AssignedStatus varchar(max)
	, Grouping varchar(max)
	, AdultFlag int
	, ParentId varchar(15)
);


;

while (@Date_Adjusted) <= (@EndDate)

begin
		
		-- only works for flat time if choosing day ..........if choosing hour, unnecessary due to SSRS tz conversions
		--if cast(@Date_Adjusted as date) < '2017-03-11'
		--	set @Date_Adjusted = cast(cast(@Date_Adjusted as date) as datetime) + cast('1900-01-01 01:29:00.000' as datetime)
		--if cast(@Date_Adjusted as date) > '2017-03-11'
		--	set @Date_Adjusted = cast(cast(@Date_Adjusted as date) as datetime) + cast('1900-01-01 12:29:00.000' as datetime)



		-- !! if before DLS, and is morning/afternoon, set to opposite; if after DLS, and is morning/afternoon, set to DLS-opposite
		if cast(@Date_Adjusted as date) < '2017-03-12' OR cast(@Date_Adjusted as date) > '2017-11-04'
				begin
					if cast(@Date_Adjusted as time) < '14:00:00.0000000'
						set @Date_Adjusted = cast(cast(@Date_Adjusted as date) as datetime) + cast('1900-01-01 21:29:00.000' as datetime);
					else --if cast(@Date_Adjusted as time) > '14:00:00.0000000'
						set @Date_Adjusted = cast(cast(@Date_Adjusted as date) as datetime) + cast('1900-01-01 13:29:00.000' as datetime);
				end

		-- if the date's after DLS (3/12), and before 2pm (UTC), set to 8pm UTC. -5 for CST = ~3:30pm.
		else if cast(@Date_Adjusted as date) >= '2017-03-12'
				begin
					if cast(@Date_Adjusted as time) < '14:00:00.0000000'
						set @Date_Adjusted = cast(cast(@Date_Adjusted as date) as datetime) + cast('1900-01-01 20:29:00.000' as datetime);
					else --if cast(@Date_Adjusted as time) > '14:00:00.0000000'
						set @Date_Adjusted = cast(cast(@Date_Adjusted as date) as datetime) + cast('1900-01-01 12:29:00.000' as datetime);
				end;

	INSERT @ResultTable
	
	SELECT DISTINCT IncidentDimvw.Id								AS [ID]
		,IncidentStatusvw.IncidentStatusValue			AS [Status]
		,IncidentTierQueuesvw.IncidentTierQueuesValue	AS [Support Group]
		--,ASSIGNED_USER.DisplayName						AS [Assigned To]
		,@Date_Adjusted									AS [DateTime]
		--,cast(@Date_Adjusted as date)					AS [Date]
		--,datepart(hour,@Date_Adjusted)					AS [Hour] -- need to calc this after TZ conversion in SSRS
		,case when ASSIGNED_USER.DisplayName is not null 
			then 'Assigned' else 'Unassigned' end		AS AssignedStatus

		, [Grouping] = CASE 
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId IN (9,10,11,55) THEN 'L4'
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId IN (7,60,63,67) THEN 'Retail Support (L1, L2, L3)'
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId = 12 THEN 'Retail Payments'
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId = 8 THEN IncidentTierQueuesvw.IncidentTierQueuesValue
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId IN (56,61) THEN 'Aloha'
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId = 62 THEN 'Hardware-R10'
			WHEN IncidentTierQueuesvw.IncidentTierQueuesId = 65 THEN 'Hardware-Aloha'
			ELSE 'OTHER' END 

		--, CHILD_IDS.maxparent
		, AdultFlag = CASE WHEN CHILD_IDS.maxparent IS NULL THEN 1 END
		, ParentId = PARENTS.Id
	
	FROM WorkItemDimvw
		INNER JOIN EntityDimvw
			ON WorkItemDimvw.EntityDimKey = EntityDimvw.EntityDimKey
		INNER JOIN IncidentDimvw
			ON IncidentDimvw.EntityDimKey = WorkItemDimvw.EntityDimKey

		-- STATUS
		JOIN IncidentStatusDurationFactvw 
			ON IncidentDimvw.IncidentDimKey=IncidentStatusDurationFactvw.IncidentDimKey
			AND IncidentStatusDurationFactvw.StartDateTime <= @Date_Adjusted
			AND (IncidentStatusDurationFactvw.FinishDateTime > @Date_Adjusted or IncidentStatusDurationFactvw.FinishDateTime IS NULL)
			AND CASE 
				WHEN IncidentStatusDurationFactvw.FinishDateTime IS NOT NULL THEN IncidentStatusDurationFactvw.StartDateTime
				WHEN IncidentStatusDurationFactvw.FinishDateTime IS NULL 
					THEN (SELECT MAX(ISD.StartDateTime) FROM IncidentStatusDurationFactvw ISD 
							WHERE ISD.IncidentDimKey = IncidentStatusDurationFactvw.INCIDENTDIMKEY) 	
				END = IncidentStatusDurationFactvw.StartDateTime
		JOIN IncidentStatusvw ON IncidentStatusDurationFactvw.IncidentStatusId=IncidentStatusvw.IncidentStatusId

		-- SUPPORT GROUP
		JOIN IncidentTierQueueDurationFactvw
			ON IncidentDimvw.IncidentDimKey=IncidentTierQueueDurationFactvw.IncidentDimKey
			AND IncidentTierQueueDurationFactvw.StartDateTime <= @Date_Adjusted
			AND (IncidentTierQueueDurationFactvw.FinishDateTime > @Date_Adjusted OR IncidentTierQueueDurationFactvw.FinishDateTime IS NULL)
		JOIN IncidentTierQueuesvw ON IncidentTierQueueDurationFactvw.IncidentTierQueuesId=IncidentTierQueuesvw.IncidentTierQueuesId

		-- ASSIGNED USER - potentially null
		LEFT JOIN WorkItemAssignedToUserFactvw
			ON WorkItemDimvw.WorkItemDimKey=WorkItemAssignedToUserFactvw.WorkItemDimKey
			AND WorkItemAssignedToUserFactvw.CreatedDate <= @Date_Adjusted
			AND (WorkItemAssignedToUserFactvw.DeletedDate > @Date_Adjusted OR WorkItemAssignedToUserFactvw.DeletedDate IS NULL)
		LEFT JOIN UserDimvw ASSIGNED_USER ON WorkItemAssignedToUserFactvw.WorkItemAssignedToUser_UserDimKey=ASSIGNED_USER.UserDimKey


		-- identifying 'adult' tickets
		LEFT JOIN 
				(SELECT WorkItemDimKey
					, maxparent = MAX([WorkItemHasParentWorkItem_WorkItemDimKey])
				FROM [WorkItemHasParentWorkItemFactvw]
				GROUP BY WorkItemDimKey)
		CHILD_IDS ON WorkItemDimvw.WorkItemDimKey = CHILD_IDS.WorkItemDimKey
		LEFT JOIN workitemdimvw PARENTS ON CHILD_IDS.maxparent = PARENTS.workitemdimkey

	WHERE INCIDENTDIMVW.CreatedDate >= '2016-01-01'
		AND IncidentStatusvw.IncidentStatusId IN (2,5)
		AND (IncidentTierQueuesvw.IncidentTierQueuesId IN (7,12) OR IncidentTierQueuesvw.ParentId IN (7,8))


	--if @Increment = 'Day'
	--	SET @Date_Adjusted = dateadd(DAY,1,@Date_Adjusted);
	--if @Increment = 'Hour'
		--SET @Date_Adjusted = dateadd(HOUR,1,@Date_Adjusted);

		-- !! if evening, add a day
		if cast(@Date_Adjusted as time) > '14:00:00.0000000'
			set @Date_Adjusted = dateadd(day,1,@Date_Adjusted);

end

select *
--DateTime, [Support Group], Status, AssignedStatus, IRs = count(*)
from @ResultTable
--group by DateTime, [Support Group], Status, AssignedStatus
order by datetime