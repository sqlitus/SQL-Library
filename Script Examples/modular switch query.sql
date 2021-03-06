/* modular query - runs if @switch = ON 

best practices template

*/


-- PERFORMANCE
SET NOCOUNT ON;


-- VARIABLES
DECLARE @SWITCH VARCHAR(MAX) = 'OFF'
DECLARE @PARAM VARCHAR(MAX) = 'ON'
DECLARE @COUNT INT = 0
DECLARE @RESULT_TABLE TABLE(
	ID INT, TEAM VARCHAR(MAX), DESIGNATION VARCHAR(MAX)
)
;

-- HELPER FUNCTIONS
INSERT INTO @RESULT_TABLE
	SELECT ID = INCIDENTTIERQUEUESID
		, TEAM = INCIDENTTIERQUEUESVALUE 
		, 'PLACEHOLDER'
	FROM INCIDENTTIERQUEUESVW

SELECT * FROM @RESULT_TABLE


IF @PARAM = 'ON'
BEGIN
	UPDATE @RESULT_TABLE
	SET DESIGNATION = @PARAM
	SELECT * FROM @RESULT_TABLE
END


-- MAIN
IF @SWITCH <> 'ON'
	RETURN;
ELSE
	-- RETURN SOME VARIABLE MANIUPLATION
	SET @PARAM = 'ON'
	PRINT 'PARAM = ' + @PARAM
;

IF @SWITCH = 'ON'
BEGIN
	SELECT * FROM INCIDENTTIERQUEUESVW
END

IF @SWITCH = 'ON'
	WHILE @COUNT < 10
		SELECT * FROM IncidentTierQueuesvw WHERE IncidentTierQueuesId = @COUNT
