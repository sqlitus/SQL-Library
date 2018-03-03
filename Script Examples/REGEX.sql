/* SQL "REGEX" PATINDEX LOCATION & DETECTION PATTERNS */

-- NOTES:
-- BEST TO WRAP TEXT FIELD IN SPACES SO THAT PATINDEX > 0 TO AVOID FALSE NEGATIVES


WITH CTE_TEXT AS (
SELECT 1 AS NUM, 'ESL SOMETHING THING' AS 'TEXT_COL', 'BLAHBLAH ESL BLAHBLAH' AS T2
UNION SELECT 2 AS NUM, 'SOMETHING ESL THING', 'BLAHBLAH ESL BLAHBLAH' AS T2
UNION SELECT 3 AS NUM, 'SOMETHING THING ESL', 'BLAHBLAH ESL BLAHBLAH' AS T2

UNION SELECT 4 AS NUM, 'ESLABC SOMETHING THING', 'BLAHBLAH AESL BLAHBLAH' AS T2
UNION SELECT 5 AS NUM, 'SOMETHING ESLABC THING', 'BLAHBLAH AESL BLAHBLAH' AS T2
UNION SELECT 6 AS NUM, 'SOMETHING THING ESLABC', 'BLAHBLAH AESL BLAHBLAH' AS T2

UNION SELECT 7 AS NUM, 'ESL,SOMETHING THING', 'BLAHBLAH ESL BLAHBLAH' AS T2
UNION SELECT 8 AS NUM, 'SOMETHING#ESL THING', 'BLAHBLAH ESL BLAHBLAH' AS T2
UNION SELECT 9 AS NUM, 'SOMETHING THING:ESL', 'BLAHBLAH ESL BLAHBLAH' AS T2

UNION SELECT 10 AS NUM, 'ESL123SOMETHING THING', 'BLAHBLAH ESL BLAHBLAH' AS T2
UNION SELECT 11 AS NUM, 'SOMETHING ESL123 THING', 'BLAHBLAH ESL BLAHBLAH' AS T2
UNION SELECT 12 AS NUM, 'SOMETHING THING ESL123', 'BLAHBLAH ESL BLAHBLAH' AS T2

UNION SELECT 13 AS NUM, 'SOME THING ELSE', 'BLAHBLAH,ESL#LOL' AS T2
UNION SELECT 14 AS NUM, 'SOMETHING ELSE IS ESL', 'BLAHBLAH,ESL#LOL' AS T2
UNION SELECT 15 AS NUM, 'SOME THING IS ESL', 'BLAHBLAH,ESL#LOL' AS T2
UNION SELECT 14 AS NUM, 'ESL SOME THING', 'BLAHBLAH,ESL#LOL' AS T2
UNION SELECT 15 AS NUM, 'ESLABC IS SOME', 'BLAHBLAH,ESL#LOL' AS T2
)

SELECT		*
			, RAW_PATTERN = PATINDEX('%[^A-Z]ESL[^A-Z]%', TEXT_COL)
			, SPACED_PATTERN = PATINDEX('%[^A-Z]ESL[^A-Z]%', ' ' + TEXT_COL + ' ')
			, RAW_DOUBLE_PATTERN = PATINDEX('%[^A-Z]ESL[^A-Z]%', TEXT_COL + T2)
			, SPACED_DOUBLE_PATTERN = PATINDEX('%[^A-Z]ESL[^A-Z]%', TEXT_COL + ' ' + T2)
			, FULLY_SPACED_DOUBLE_PATTERN = PATINDEX('%[^A-Z]ESL[^A-Z]%', ' ' +TEXT_COL + ' ' + T2 + ' ')
			, LIKE_PATTERN_WORD = CASE WHEN ' ' +TEXT_COL + ' ' + T2 + ' ' LIKE '%[^A-Z]ESL[^A-Z]%' THEN 'IS ESL WORD' END
			, LIKE_PATTERN_STRING = CASE WHEN ' ' +TEXT_COL + ' ' + T2 + ' ' LIKE '%ESL%' THEN 'IS ESL WORD' END

			, MULTIPLE_WORD_LABELS = CASE 

			WHEN ' ' +TEXT_COL + ' ' + T2 + ' ' LIKE '%SOMETHING%' 
				OR ' ' +TEXT_COL + ' ' + T2 + ' ' LIKE '%ELSE%' 
			THEN 'SOMETHING OR ELSE'
			WHEN ' ' +TEXT_COL + ' ' + T2 + ' ' LIKE '%ESL%' 
				OR ' ' +TEXT_COL + ' ' + T2 + ' ' LIKE '%THING%' 
				OR ' ' +TEXT_COL + ' ' + T2 + ' ' LIKE '%SOME%' 
			THEN 'ESL OR SOME OR THING' 
			END

FROM		CTE_TEXT
















/* REGION / LOCATION STUFF */



DECLARE @START DATE = '2017-03-05'
DECLARE @END DATE = '2017-07-10'


select * from (

SELECT INCIDENTDIMVW.ID
	, CREATEDDATE
	, RESOLVEDDATE
	, TITLE
	, Description
	--, REGION
	--, LOCATION
	--, SMARTER_REGION = CASE
	--	WHEN ' '+IncidentDimvw.TITLE+' ' LIKE '%[^A-Z]TS[^A-Z]%' THEN 'TS'
	--	WHEN ' '+IncidentDimvw.TITLE+' ' LIKE '%[^A-Z]SP[^A-Z]%' THEN 'SP'
	--	WHEN ' '+IncidentDimvw.TITLE+' ' LIKE '%[^A-Z]MA[^A-Z]%' THEN 'MA'
	--	WHEN ' '+IncidentDimvw.TITLE+' ' LIKE '%[^A-Z]PN[^A-Z]%' THEN 'PN'
	--	WHEN ' '+IncidentDimvw.TITLE+' ' LIKE '%[^A-Z]RM[^A-Z]%' THEN 'RM'
	--	WHEN ' '+IncidentDimvw.TITLE+' ' LIKE '%[^A-Z]SO[^A-Z]%' THEN 'SO'
	--	WHEN ' '+IncidentDimvw.TITLE+' ' LIKE '%[^A-Z]MW[^A-Z]%' THEN 'MW'
	--	WHEN ' '+IncidentDimvw.TITLE+' ' LIKE '%[^A-Z]FL[^A-Z]%' THEN 'FL'
	--	WHEN ' '+IncidentDimvw.TITLE+' ' LIKE '%[^A-Z]UK[^A-Z]%' THEN 'UK'
	--	WHEN ' '+IncidentDimvw.TITLE+' ' LIKE '%[^A-Z]SW[^A-Z]%' THEN 'SW'
	--	WHEN ' '+IncidentDimvw.TITLE+' ' LIKE '%[^A-Z]CE[^A-Z]%' THEN 'CE'
	--	WHEN ' '+IncidentDimvw.TITLE+' ' LIKE '%[^A-Z]NC[^A-Z]%' THEN 'NC'
	--	WHEN ' '+IncidentDimvw.TITLE+' ' LIKE '%[^A-Z]NE[^A-Z]%' THEN 'NE'
	--	WHEN ' '+IncidentDimvw.TITLE+' ' LIKE '%[^A-Z]NA[^A-Z]%' THEN 'NA'
	--	ELSE IncidentDimvw.Region
	--	END
	--, SMARTER_LOCATION = CASE
	--	WHEN PATINDEX('%[^A-Z]SP [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN RTRIM(LTRIM(SUBSTRING(' '+IncidentDimvw.TITLE+' ', PATINDEX('%[^A-Z]SP [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+4, 3)))
	--	WHEN PATINDEX('%[^A-Z]MA [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN RTRIM(LTRIM(SUBSTRING(' '+IncidentDimvw.TITLE+' ', PATINDEX('%[^A-Z]MA [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+4, 3)))
	--	WHEN PATINDEX('%[^A-Z]PN [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN RTRIM(LTRIM(SUBSTRING(' '+IncidentDimvw.TITLE+' ', PATINDEX('%[^A-Z]PN [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+4, 3)))
	--	WHEN PATINDEX('%[^A-Z]RM [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN RTRIM(LTRIM(SUBSTRING(' '+IncidentDimvw.TITLE+' ', PATINDEX('%[^A-Z]RM [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+4, 3)))
	--	WHEN PATINDEX('%[^A-Z]SO [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN RTRIM(LTRIM(SUBSTRING(' '+IncidentDimvw.TITLE+' ', PATINDEX('%[^A-Z]SO [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+4, 3)))
	--	WHEN PATINDEX('%[^A-Z]MW [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN RTRIM(LTRIM(SUBSTRING(' '+IncidentDimvw.TITLE+' ', PATINDEX('%[^A-Z]MW [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+4, 3)))
	--	WHEN PATINDEX('%[^A-Z]FL [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN RTRIM(LTRIM(SUBSTRING(' '+IncidentDimvw.TITLE+' ', PATINDEX('%[^A-Z]FL [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+4, 3)))
	--	WHEN PATINDEX('%[^A-Z]UK [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN RTRIM(LTRIM(SUBSTRING(' '+IncidentDimvw.TITLE+' ', PATINDEX('%[^A-Z]UK [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+4, 3)))
	--	WHEN PATINDEX('%[^A-Z]SW [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN RTRIM(LTRIM(SUBSTRING(' '+IncidentDimvw.TITLE+' ', PATINDEX('%[^A-Z]SW [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+4, 3)))
	--	WHEN PATINDEX('%[^A-Z]CE [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN RTRIM(LTRIM(SUBSTRING(' '+IncidentDimvw.TITLE+' ', PATINDEX('%[^A-Z]CE [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+4, 3)))
	--	WHEN PATINDEX('%[^A-Z]NC [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN RTRIM(LTRIM(SUBSTRING(' '+IncidentDimvw.TITLE+' ', PATINDEX('%[^A-Z]NC [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+4, 3)))
	--	WHEN PATINDEX('%[^A-Z]NE [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN RTRIM(LTRIM(SUBSTRING(' '+IncidentDimvw.TITLE+' ', PATINDEX('%[^A-Z]NE [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+4, 3)))
	--	WHEN PATINDEX('%[^A-Z]NA [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN RTRIM(LTRIM(SUBSTRING(' '+IncidentDimvw.TITLE+' ', PATINDEX('%[^A-Z]NA [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+4, 3)))
	--	WHEN PATINDEX('%[^A-Z]TS [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN RTRIM(LTRIM(SUBSTRING(' '+IncidentDimvw.TITLE+' ', PATINDEX('%[^A-Z]TS [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+4, 3)))
	--	ELSE IncidentDimvw.Location
	--	END



	--, Smart_Region = CASE 
	--	when patindex('%[^a-z][a-z][a-z][^a-z][a-z][a-z][a-z][^a-z]%', Left(IncidentDimvw.Title, 22)) > 0
	--		then rtrim(ltrim(substring(IncidentDimvw.Title, patindex('%[^a-z][a-z][a-z][^a-z][a-z][a-z][a-z][^a-z]%', IncidentDimvw.Title)+1, 2)))
	--		else IncidentDimvw.Region
	--	end
	--, Smart_Location = CASE
	--	WHEN PATINDEX('%[^A-Z][A-Z][A-Z] [A-Z][A-Z][A-Z][^A-Z]%', LEFT(INCIDENTDIMVW.TITLE, 22)) > 0
	--		then rtrim(ltrim(substring(IncidentDimvw.Title, patindex('%[^a-z][a-z][a-z] [a-z][a-z][a-z][^a-z]%', IncidentDimvw.Title)+4, 3)))
	--		ELSE IncidentDimvw.Location
	--	end



	, IncidentDimvw.External_Ref_ID
	--, [External_Ref_NCR_Ticket] = CASE
	--	WHEN PATINDEX('%[^0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][^0-9]%', ' ' + IncidentDimvw.External_Ref_ID + ' ') > 0
	--	THEN RTRIM(LTRIM(REPLACE(REPLACE(REPLACE(SUBSTRING(IncidentDimvw.External_Ref_ID, PATINDEX('%[^0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][^0-9]%', ' ' + IncidentDimvw.External_Ref_ID + ' '), 10),'/', ''), ',', ''), ')', '')))
	--	END
	, [External_Ref_Defect] = CASE
		WHEN PATINDEX('%[^0-9][0-9][0-9][0-9][0-9][^0-9]%', ' ' + IncidentDimvw.External_Ref_ID + ' ') > 0
		THEN RTRIM(LTRIM(SUBSTRING(IncidentDimvw.External_Ref_ID, PATINDEX('%[^0-9][0-9][0-9][0-9][0-9][^0-9]%', ' ' + IncidentDimvw.External_Ref_ID + ' '), 4)))
		END


	, [DEFECT TITLE] = CASE
		WHEN PATINDEX('%[^0-9][0-9][0-9][0-9][0-9][^0-9]%', ' ' + IncidentDimvw.Title + ' ') > 0
		THEN RTRIM(LTRIM(SUBSTRING(IncidentDimvw.Title, PATINDEX('%[^0-9][0-9][0-9][0-9][0-9][^0-9]%', ' ' + IncidentDimvw.Title + ' '), 4)))
		END

	, [DEFECT DESCRIPTION 2 - WORD AND NUM] = CASE
		WHEN PATINDEX('%DEFECT%[^0-9][0-9][0-9][0-9][0-9][^0-9]%', ' ' + IncidentDimvw.DESCRIPTION + ' ') > 0
		THEN RTRIM(LTRIM(SUBSTRING(IncidentDimvw.DESCRIPTION, PATINDEX('%DEFECT%[^0-9][0-9][0-9][0-9][0-9][^0-9]%', ' ' + IncidentDimvw.DESCRIPTION + ' ')-14, 30)))
		END

	, [DEFECT DESCRIPTION 3] = CASE
		WHEN PATINDEX('%#[0-9][0-9][0-9][0-9][^0-9]%', ' ' + IncidentDimvw.DESCRIPTION + ' ') > 0
		THEN RTRIM(LTRIM(SUBSTRING(IncidentDimvw.DESCRIPTION, PATINDEX('%#[0-9][0-9][0-9][0-9][^0-9]%', ' ' + IncidentDimvw.DESCRIPTION + ' ')-14, 30)))
		END



FROM INCIDENTDIMVW
	JOIN INCIDENTTIERQUEUESVW ITQ ON INCIDENTDIMVW.[TierQueue_IncidentTierQueuesId] = ITQ.INCIDENTTIERQUEUESID

WHERE CREATEDDATE BETWEEN @START AND @END
	and (incidentdimvw.[TierQueue_IncidentTierQueuesId] in (7,12) OR ITQ.PARENTID IN (7,8))
	
--ORDER BY CREATEDDATE
) x

where 1=1
--and Smart_Region  in
--(
--	'SP',
--	'MA',
--	'PN',
--	'RM',
--	'SO',
--	'MW',
--	'FL',
--	'UK',
--	'SW',
--	'CE',
--	'NC',
--	'NE',
--	'NA',
--	'TS'
--)

--and SMARTER_LOCATION <> Smart_Location
----SMARTER_LOCATION IS NOT NULL






/* notes - 8/17/2017 */
/* 
all tickets in timespan:
2138 total tickets

23 the smart region does not catch
	-> all 23 the smarTER_reg/loc beat

smarter reg/loc captures from teh beginning of the data, current has to skip a beat 
but smarter region captures the DVO and PDR incidents - because these are the beginning of a field


just onepos-ish tickets
520



*/

/*
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

*/







/* aid

	, SMARTER_LOCATION_AID = CASE
	WHEN PATINDEX('%[^A-Z]SP [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]SP [A-Z][A-Z][A-Z][^A-Z]%', INCIDENTDIMVW.TITLE)+5
	WHEN PATINDEX('%[^A-Z]MA [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]MA [A-Z][A-Z][A-Z][^A-Z]%', INCIDENTDIMVW.TITLE)+5
	WHEN PATINDEX('%[^A-Z]PN [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]PN [A-Z][A-Z][A-Z][^A-Z]%', INCIDENTDIMVW.TITLE)+5
	WHEN PATINDEX('%[^A-Z]RM [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]RM [A-Z][A-Z][A-Z][^A-Z]%', INCIDENTDIMVW.TITLE)+5
	WHEN PATINDEX('%[^A-Z]SO [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]SO [A-Z][A-Z][A-Z][^A-Z]%', INCIDENTDIMVW.TITLE)+5
	WHEN PATINDEX('%[^A-Z]MW [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]MW [A-Z][A-Z][A-Z][^A-Z]%', INCIDENTDIMVW.TITLE)+5
	WHEN PATINDEX('%[^A-Z]FL [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]FL [A-Z][A-Z][A-Z][^A-Z]%', INCIDENTDIMVW.TITLE)+5
	WHEN PATINDEX('%[^A-Z]UK [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]UK [A-Z][A-Z][A-Z][^A-Z]%', INCIDENTDIMVW.TITLE)+5
	WHEN PATINDEX('%[^A-Z]SW [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]SW [A-Z][A-Z][A-Z][^A-Z]%', INCIDENTDIMVW.TITLE)+5
	WHEN PATINDEX('%[^A-Z]CE [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]CE [A-Z][A-Z][A-Z][^A-Z]%', INCIDENTDIMVW.TITLE)+5
	WHEN PATINDEX('%[^A-Z]NC [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]NC [A-Z][A-Z][A-Z][^A-Z]%', INCIDENTDIMVW.TITLE)+5
	WHEN PATINDEX('%[^A-Z]NE [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]NE [A-Z][A-Z][A-Z][^A-Z]%', INCIDENTDIMVW.TITLE)+5
	WHEN PATINDEX('%[^A-Z]NA [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]NA [A-Z][A-Z][A-Z][^A-Z]%', INCIDENTDIMVW.TITLE)+5
	WHEN PATINDEX('%[^A-Z]TS [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]TS [A-Z][A-Z][A-Z][^A-Z]%', INCIDENTDIMVW.TITLE)+5

		END


	, SMARTER_LOCATION_AID_2 = CASE
WHEN PATINDEX('%[^A-Z]SP [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]SP [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+5
WHEN PATINDEX('%[^A-Z]MA [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]MA [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+5
WHEN PATINDEX('%[^A-Z]PN [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]PN [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+5
WHEN PATINDEX('%[^A-Z]RM [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]RM [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+5
WHEN PATINDEX('%[^A-Z]SO [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]SO [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+5
WHEN PATINDEX('%[^A-Z]MW [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]MW [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+5
WHEN PATINDEX('%[^A-Z]FL [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]FL [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+5
WHEN PATINDEX('%[^A-Z]UK [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]UK [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+5
WHEN PATINDEX('%[^A-Z]SW [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]SW [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+5
WHEN PATINDEX('%[^A-Z]CE [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]CE [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+5
WHEN PATINDEX('%[^A-Z]NC [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]NC [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+5
WHEN PATINDEX('%[^A-Z]NE [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]NE [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+5
WHEN PATINDEX('%[^A-Z]NA [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]NA [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+5
WHEN PATINDEX('%[^A-Z]TS [A-Z][A-Z][A-Z][^A-Z]%', ' '+IncidentDimvw.TITLE+' ') > 0 THEN PATINDEX('%[^A-Z]TS [A-Z][A-Z][A-Z][^A-Z]%', ' '+INCIDENTDIMVW.TITLE+' ')+5
end

*/