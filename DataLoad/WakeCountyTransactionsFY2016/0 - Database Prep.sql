IF NOT EXISTS
(
	SELECT 1
	FROM sys.databases
	WHERE
		name = N'OutlierDetection'
)
BEGIN
	CREATE DATABASE OutlierDetection;
END
GO
USE [OutlierDetection]
GO
IF NOT EXISTS
(
	SELECT 1
	FROM sys.schemas
	WHERE
		name = N'Wake'
)
BEGIN
	--CREATE SCHEMA must be the first statement in a batch, so we're executing
	--it as dynamic SQL here.
	EXEC(N'CREATE SCHEMA Wake;');
END
GO
/*
Next:  run the Wake Transactions import R script.  It is called "1 - Create Staging Table.R".
NOTE:  if you already have a table called dbo.WakeCountyTransactionsFY2016, you should drop it before running the script.
*/
