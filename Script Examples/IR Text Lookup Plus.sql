/* OnePOS Incidents dataset - Fully parameterized (WIP) */


--declare @SupportGroupId varchar(255) = 5 
--declare @SupportGroupParent varchar(255) = null 

--declare @StartDate_BaseValue_Adjusted  date = NULL --'2016-10-01'
--declare @EndDate_BaseValue_Adjusted  date = NULL

--declare @Status varchar(50) = null

--declare @TextSearch1 varchar(max) = NULL
--declare @TextSearch2 varchar(max) = 'KRONOS'
--declare @andTextSearch1 varchar(max) = NULL
--declare @andTextSearch2 varchar(max) = NULL
--declare @notTextSearch1 varchar(max) = NULL
--declare @notTextSearch2 varchar(max) = NULL

--DECLARE @FIELD1 VARCHAR(MAX) = 'TITLE'
--DECLARE @FIELD2 VARCHAR(MAX) = 'TITLE'
--DECLARE @FIELD3 VARCHAR(MAX) = 'TITLE'
--DECLARE @TEXT1 VARCHAR(MAX) = 'R10'
--DECLARE @TEXT2 VARCHAR(MAX) = 'R10'
--DECLARE @TEXT3 VARCHAR(MAX) = 'R10'
--;


SELECT
/* Entity Properties */
EntityDimvw.LastModified AS [Modified],

/* WorkItem Properties */
WorkItemDimvw.Id AS [Id],
--WorkItemDimvw.IsDeleted AS [Archived],

/*  Incident Properties */
IncidentDimvw.Title AS [Title],
IncidentDimvw.CreatedDate AS [Created],
IncidentDimvw.ResolvedDate AS [Resolved],
--IncidentDimvw.ClosedDate AS [Closed],
--IncidentDimvw.FirstResponseDate AS [First Response],
--IncidentDimvw.FirstAssignedDate AS [First Assigned],
IncidentDimvw.Priority AS [Priority],
IncidentDimvw.Description AS [Description],
--IncidentDimvw.IsParent AS [Is Parent],
--IncidentDimvw.IsDowntime AS [Major Incident],
IncidentDimvw.Region AS [Region],
IncidentDimvw.Location AS [Location],
--IncidentDimvw.IncidentDimKey AS [IncidentDimKey],
IncidentDimvw.ResolutionDescription,

/* Look Up Values */
                [Classification] = IncidentClassificationvw.IncidentClassificationValue,
                --[Source] = IncidentSourcevw.IncidentSourceValue,
                --[Impact] = IncidentImpactvw.IncidentImpactValue,
                --[Urgency] = IncidentUrgencyvw.IncidentUrgencyValue,
                [Support Group] = DISPLAYSTRINGDIMVW.displayname,
                [Status] = IncidentStatusvw.IncidentStatusValue,
                [Resolution Category] = RESOLUTION_CATEGORY_NAME.DISPLAYNAME, -- *** COMMA
		
/* User Fields */
                [Assigned To] = AssignedToUser.DisplayName,
                --[Affected User] = AffectedUser.DisplayName,
                --[Affected User Company] = AffectedUser.Company,
                --[Created By] = CreatedByUser.DisplayName,
                --[Primary Owner] = PrimaryOwner.DisplayName,
                [Resolved By] = ResolvedByUser.DisplayName
	
,IncidentDimvw.External_Ref_ID
	

, StoreNumber = case when (patindex('%[^0-9][0-9][0-9][0-9][0-9][0-9][^0-9]%',' '+IncidentDimvw.Title)>0) 
	then substring(IncidentDimvw.Title,patindex('%[^0-9][0-9][0-9][0-9][0-9][0-9][^0-9]%',IncidentDimvw.Title)+1,5) 
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
				
FROM WorkItemDimvw

INNER JOIN EntityDimvw
    ON WorkItemDimvw.EntityDimKey = EntityDimvw.EntityDimKey
INNER JOIN IncidentDimvw
    ON IncidentDimvw.EntityDimKey = WorkItemDimvw.EntityDimKey

/* Joins for Lookup Values */
  LEFT OUTER JOIN IncidentClassificationvw
    ON IncidentDimvw.Classification_IncidentClassificationId = IncidentClassificationvw.IncidentClassificationId
  LEFT OUTER JOIN IncidentSourcevw
    ON IncidentDimvw.Source_IncidentSourceId = IncidentSourcevw.IncidentSourceId
  LEFT OUTER JOIN IncidentImpactvw
    ON IncidentDimvw.Impact_IncidentImpactId = IncidentImpactvw.IncidentImpactId
  LEFT OUTER JOIN IncidentUrgencyvw
    ON  IncidentDimvw.Urgency_IncidentUrgencyId = IncidentUrgencyvw.IncidentUrgencyId
  LEFT OUTER JOIN IncidentTierQueuesvw
    ON IncidentDimvw.TierQueue_IncidentTierQueuesId = IncidentTierQueuesvw.IncidentTierQueuesId

	LEFT JOIN DISPLAYSTRINGDIMVW 
		ON INCIDENTTIERQUEUESVW.EnumTypeId = DISPLAYSTRINGDIMVW.BASEMANAGEDENTITYID
		AND DISPLAYSTRINGDIMVW.LANGUAGECODE = 'ENU'

  LEFT OUTER JOIN IncidentStatusvw
    ON IncidentDimvw.Status_IncidentStatusId = IncidentStatusvw.IncidentStatusId
  LEFT OUTER JOIN IncidentResolutionCategoryvw
    ON IncidentDimvw.ResolutionCategory_IncidentResolutionCategoryId = IncidentResolutionCategoryvw.IncidentResolutionCategoryId
	LEFT JOIN DISPLAYSTRINGDIMVW RESOLUTION_CATEGORY_NAME ON RESOLUTION_CATEGORY_NAME.BaseManagedEntityId = IncidentResolutionCategoryvw.ENUMTYPEID
		AND RESOLUTION_CATEGORY_NAME.LANGUAGECODE = 'ENU'



/* Joins for User Relationships */
                Left Outer Join dbo.WorkItemAssignedToUserFactvw 
                                ON WorkItemDimvw.WorkItemDimKey = WorkItemAssignedToUserFactvw.WorkItemDimKey
                                And WorkItemAssignedToUserFactvw.DeletedDate IS NULL
                Left Outer Join dbo.UserDimvw AssignedToUser
                                ON WorkItemAssignedToUserFactvw.WorkItemAssignedToUser_UserDimKey = AssignedToUser.UserDimKey

                --Left Outer Join dbo.WorkItemAffectedUserFactvw
                --                ON WorkItemAffectedUserFactvw.WorkItemDimKey = WorkItemDimvw.WorkItemDimKey
                --                And WorkItemAffectedUserFactvw.DeletedDate IS NULL
                --Left Outer Join dbo.UserDimvw AffectedUser
                --                ON WorkItemAffectedUserFactvw.WorkItemAffectedUser_UserDimKey = AffectedUser.UserDimKey

                --Left Outer Join dbo.WorkItemCreatedByUserFactvw
                --                ON WorkItemCreatedByUserFactvw.WorkItemDimKey = WorkItemDimvw.WorkItemDimKey
                --                And WorkItemCreatedByUserFactvw.DeletedDate IS NULL
                --Left Outer Join dbo.UserDimvw CreatedByUser
                --                ON WorkItemCreatedByUserFactvw.WorkItemCreatedByUser_UserDimKey = CreatedByUser.UserDimKey

                --Left Outer Join IncidentHasPrimaryOwnerFactvw
                --                ON IncidentHasPrimaryOwnerFactvw.IncidentDimKey = IncidentDimvw.IncidentDimKey
                --                AND IncidentHasPrimaryOwnerFactvw.DeletedDate IS NULL
                --Left Outer Join dbo.UserDimvw PrimaryOwner
                --                ON IncidentHasPrimaryOwnerFactvw.IncidentPrimaryOwner_UserDimKey = PrimaryOwner.UserDimKey

                Left Outer Join dbo.IncidentResolvedByUserFactvw
                                ON IncidentResolvedByUserFactvw.IncidentDimKey = IncidentDimvw.IncidentDimKey
                                AND IncidentResolvedByUserFactvw.DeletedDate IS NULL
                Left Outer Join dbo.UserDimvw ResolvedByUser
                                ON IncidentResolvedByUserFactvw.TroubleTicketResolvedByUser_UserDimKey = ResolvedByUser.UserDimKey

				
		
WHERE

-- SUPPORT GROUP
(
( IncidentTierQueuesvw.IncidentTierQueuesId in (@SupportGroupId) )
)

-- CREATED DATE
AND 

(
	( IncidentDimvw.CreatedDate >= @StartDate_BaseValue_Adjusted  OR @StartDate_BaseValue_Adjusted IS NULL)
	AND 
	( IncidentDimvw.CreatedDate <= @EndDate_BaseValue_Adjusted  OR @EndDate_BaseValue_Adjusted IS NULL )
)


-- STATUS
AND

( IncidentStatusvw.IncidentStatusValue IN (@Status) )		-- ** OR NULL CLAUSE WAS NOT WORKING. something with datasets...

-- TEXT OR SEARCCH
AND 
(
	(
		(IncidentDimvw.Title LIKE '%'+@TextSearch1+'%' OR IncidentDimvw.Description LIKE '%'+@TextSearch1+'%' OR IncidentDimvw.ResolutionDescription LIKE '%' + @TextSearch1 + '%') 
		OR
		(IncidentDimvw.Title LIKE '%'+@TextSearch2+'%' OR IncidentDimvw.Description LIKE '%'+@TextSearch2+'%' OR IncidentDimvw.ResolutionDescription LIKE '%' + @TextSearch2 + '%') 
		OR
		(IncidentDimvw.Title LIKE '%'+@TextSearch3+'%' OR IncidentDimvw.Description LIKE '%'+@TextSearch3+'%' OR IncidentDimvw.ResolutionDescription LIKE '%' + @TextSearch3 + '%') 
		OR
		(IncidentDimvw.Title LIKE '%'+@TextSearch4+'%' OR IncidentDimvw.Description LIKE '%'+@TextSearch4+'%' OR IncidentDimvw.ResolutionDescription LIKE '%' + @TextSearch4 + '%') 
		OR
		(IncidentDimvw.Title LIKE '%'+@TextSearch5+'%' OR IncidentDimvw.Description LIKE '%'+@TextSearch5+'%' OR IncidentDimvw.ResolutionDescription LIKE '%' + @TextSearch5 + '%') 

		OR (IncidentDimvw.Title LIKE '%'+@TextSearch6+'%' OR IncidentDimvw.Description LIKE '%'+@TextSearch6+'%' OR IncidentDimvw.ResolutionDescription LIKE '%' + @TextSearch6 + '%')
		OR (IncidentDimvw.Title LIKE '%'+@TextSearch7+'%' OR IncidentDimvw.Description LIKE '%'+@TextSearch7+'%' OR IncidentDimvw.ResolutionDescription LIKE '%' + @TextSearch7 + '%')
		OR (IncidentDimvw.Title LIKE '%'+@TextSearch8+'%' OR IncidentDimvw.Description LIKE '%'+@TextSearch8+'%' OR IncidentDimvw.ResolutionDescription LIKE '%' + @TextSearch8 + '%')
		OR (IncidentDimvw.Title LIKE '%'+@TextSearch9+'%' OR IncidentDimvw.Description LIKE '%'+@TextSearch9+'%' OR IncidentDimvw.ResolutionDescription LIKE '%' + @TextSearch9 + '%')
		OR (IncidentDimvw.Title LIKE '%'+@TextSearch10+'%' OR IncidentDimvw.Description LIKE '%'+@TextSearch10+'%' OR IncidentDimvw.ResolutionDescription LIKE '%' + @TextSearch10 + '%')
		OR (IncidentDimvw.Title LIKE '%'+@TextSearch11+'%' OR IncidentDimvw.Description LIKE '%'+@TextSearch11+'%' OR IncidentDimvw.ResolutionDescription LIKE '%' + @TextSearch11 + '%')
		OR (IncidentDimvw.Title LIKE '%'+@TextSearch12+'%' OR IncidentDimvw.Description LIKE '%'+@TextSearch12+'%' OR IncidentDimvw.ResolutionDescription LIKE '%' + @TextSearch12 + '%')
		OR (IncidentDimvw.Title LIKE '%'+@TextSearch13+'%' OR IncidentDimvw.Description LIKE '%'+@TextSearch13+'%' OR IncidentDimvw.ResolutionDescription LIKE '%' + @TextSearch13 + '%')
		OR (IncidentDimvw.Title LIKE '%'+@TextSearch14+'%' OR IncidentDimvw.Description LIKE '%'+@TextSearch14+'%' OR IncidentDimvw.ResolutionDescription LIKE '%' + @TextSearch14 + '%')
		OR (IncidentDimvw.Title LIKE '%'+@TextSearch15+'%' OR IncidentDimvw.Description LIKE '%'+@TextSearch15+'%' OR IncidentDimvw.ResolutionDescription LIKE '%' + @TextSearch15 + '%')
		OR (IncidentDimvw.Title LIKE '%'+@TextSearch16+'%' OR IncidentDimvw.Description LIKE '%'+@TextSearch16+'%' OR IncidentDimvw.ResolutionDescription LIKE '%' + @TextSearch16 + '%')
		OR (IncidentDimvw.Title LIKE '%'+@TextSearch17+'%' OR IncidentDimvw.Description LIKE '%'+@TextSearch17+'%' OR IncidentDimvw.ResolutionDescription LIKE '%' + @TextSearch17 + '%')
		OR (IncidentDimvw.Title LIKE '%'+@TextSearch18+'%' OR IncidentDimvw.Description LIKE '%'+@TextSearch18+'%' OR IncidentDimvw.ResolutionDescription LIKE '%' + @TextSearch18 + '%')
		OR (IncidentDimvw.Title LIKE '%'+@TextSearch19+'%' OR IncidentDimvw.Description LIKE '%'+@TextSearch19+'%' OR IncidentDimvw.ResolutionDescription LIKE '%' + @TextSearch19 + '%')
		OR (IncidentDimvw.Title LIKE '%'+@TextSearch20+'%' OR IncidentDimvw.Description LIKE '%'+@TextSearch20+'%' OR IncidentDimvw.ResolutionDescription LIKE '%' + @TextSearch20 + '%')

)
	OR 
		(@TextSearch1 IS NULL AND @TextSearch2 IS NULL AND @TextSearch3 IS NULL AND @TextSearch4 IS NULL AND @TextSearch5 IS NULL
			AND @TextSearch6 IS NULL
			AND @TextSearch7 IS NULL
			AND @TextSearch8 IS NULL
			AND @TextSearch9 IS NULL
			AND @TextSearch10 IS NULL
			AND @TextSearch11 IS NULL
			AND @TextSearch12 IS NULL
			AND @TextSearch13 IS NULL
			AND @TextSearch14 IS NULL
			AND @TextSearch15 IS NULL
			AND @TextSearch16 IS NULL
			AND @TextSearch17 IS NULL
			AND @TextSearch18 IS NULL
			AND @TextSearch19 IS NULL
			AND @TextSearch20 IS NULL
		)
)



-- TEXT AND SEARCH
and
(
	(IncidentDimvw.Title LIKE '%'+@andTextSearch1+'%' OR IncidentDimvw.Description LIKE '%'+@andTextSearch1+'%' OR IncidentDimvw.ResolutionDescription LIKE '%' + @andTextSearch1 + '%' OR @andTextSearch1 IS NULL) 
	AND
	(IncidentDimvw.Title LIKE '%'+@andTextSearch2+'%' OR IncidentDimvw.Description LIKE '%'+@andTextSearch2+'%' OR IncidentDimvw.ResolutionDescription LIKE '%' + @andTextSearch2 + '%' OR @andTextSearch2 IS NULL) 
)

-- TEXT NOT SEARCH
and
(
	( (IncidentDimvw.Title NOT LIKE '%'+@notTextSearch1+'%' AND IncidentDimvw.Description NOT LIKE '%'+@notTextSearch1+'%' AND IncidentDimvw.ResolutionDescription NOT LIKE '%'+@notTextSearch1+'%') OR @notTextSearch1 IS NULL) 
	AND
	( (IncidentDimvw.Title NOT LIKE '%'+@notTextSearch2+'%' AND IncidentDimvw.Description NOT LIKE '%'+@notTextSearch2+'%' AND IncidentDimvw.ResolutionDescription NOT LIKE '%'+@notTextSearch2+'%') OR @notTextSearch2 IS NULL) 
)


-- DYNAMIC FIELD SEARCH - AND
AND (CASE
		WHEN @FIELD1 = 'Title' THEN IncidentDimvw.Title
		WHEN @FIELD1 = 'Description' THEN IncidentDimvw.Description
		WHEN @FIELD1 = 'ResolutionDescription' THEN IncidentDimvw.ResolutionDescription
	END
	LIKE '%' + @TEXT1 + '%' 
	OR @TEXT1 IS NULL)

AND (CASE
		WHEN @FIELD2 = 'Title' THEN IncidentDimvw.Title
		WHEN @FIELD2 = 'Description' THEN IncidentDimvw.Description
		WHEN @FIELD2 = 'ResolutionDescription' THEN IncidentDimvw.ResolutionDescription
	END
	LIKE '%' + @TEXT2 + '%'
	OR @TEXT2 IS NULL)

AND (CASE
		WHEN @FIELD3 = 'Title' THEN IncidentDimvw.Title
		WHEN @FIELD3 = 'Description' THEN IncidentDimvw.Description
		WHEN @FIELD3 = 'ResolutionDescription' THEN IncidentDimvw.ResolutionDescription
	END
	LIKE '%' + @TEXT3 + '%'
	OR @TEXT3 IS NULL)


-- DYNAMIC FIELD SEARCH - OR
AND 
(
		CASE
			WHEN @FIELD4 = 'Title' THEN IncidentDimvw.Title
			WHEN @FIELD4 = 'Description' THEN IncidentDimvw.Description
			WHEN @FIELD4 = 'ResolutionDescription' THEN IncidentDimvw.ResolutionDescription
		END
		LIKE '%' + @TEXT4 + '%'

	OR CASE
			WHEN @FIELD5 = 'Title' THEN IncidentDimvw.Title
			WHEN @FIELD5 = 'Description' THEN IncidentDimvw.Description
			WHEN @FIELD5 = 'ResolutionDescription' THEN IncidentDimvw.ResolutionDescription
		END
		LIKE '%' + @TEXT5 + '%'

	OR CASE
			WHEN @FIELD6 = 'Title' THEN IncidentDimvw.Title
			WHEN @FIELD6 = 'Description' THEN IncidentDimvw.Description
			WHEN @FIELD6 = 'ResolutionDescription' THEN IncidentDimvw.ResolutionDescription
		END
		LIKE '%' + @TEXT6 + '%'

	OR (@TEXT4 IS NULL AND @TEXT5 IS NULL AND @TEXT6 IS NULL)
)


-- DYNAMIC FIELD SEARCH - NOT. NO OCCURRENCE OF WORD AT ALL IN FIELD SPECIFIED
AND 
(
		(CASE
			WHEN @FIELD7 = 'Title' THEN IncidentDimvw.Title
			WHEN @FIELD7 = 'Description' THEN IncidentDimvw.Description
			WHEN @FIELD7 = 'ResolutionDescription' THEN IncidentDimvw.ResolutionDescription
		END
		NOT LIKE '%' + @TEXT7 + '%'
		OR @TEXT7 IS NULL)

	AND (CASE
			WHEN @FIELD8 = 'Title' THEN IncidentDimvw.Title
			WHEN @FIELD8 = 'Description' THEN IncidentDimvw.Description
			WHEN @FIELD8 = 'ResolutionDescription' THEN IncidentDimvw.ResolutionDescription
		END
		NOT LIKE '%' + @TEXT8 + '%'
		OR @TEXT8 IS NULL)

	AND (CASE
			WHEN @FIELD9 = 'Title' THEN IncidentDimvw.Title
			WHEN @FIELD9 = 'Description' THEN IncidentDimvw.Description
			WHEN @FIELD9 = 'ResolutionDescription' THEN IncidentDimvw.ResolutionDescription
		END
		NOT LIKE '%' + @TEXT9 + '%'
		OR @TEXT9 IS NULL)
)