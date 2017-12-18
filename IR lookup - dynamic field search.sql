/*  DYNAMIC FIELD SEARCHING FOR IR TEXT LOOKUP */

DECLARE @FIELD VARCHAR(MAX) = 'description'
DECLARE @START DATE = '2017-05-05'
DECLARE @END DATE = '2017-05-08'
DECLARE @TEXT VARCHAR(MAX) = null -- 'R10'
DECLARE @OPERATOR VARCHAR(MAX) = 'NOT LIKE'
;

SELECT I.ID, I.CREATEDDATE, I.TITLE, I.DESCRIPTION
FROM INCIDENTDIMVW I
WHERE I.CREATEDDATE BETWEEN @START AND @END

AND 
	CASE 
		WHEN @FIELD = 'TITLE' THEN I.TITLE
		WHEN @FIELD = 'DESCRIPTION' THEN I.DESCRIPTION
	END 
	
	
	LIKE
	
	
	'%' + @TEXT + '%'