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
		name = N'Raleigh2014'
)
BEGIN
	--CREATE SCHEMA must be the first statement in a batch, so we're executing
	--it as dynamic SQL here.
	EXEC(N'CREATE SCHEMA Raleigh2014;');
END
GO
/*
Next:  run the Raleigh Incident 2014 import package.  It is called RaleighIncident2014Load.dtsx.
Double-click the package to get a prompt.  Go to the Connection Managers tab
	and make sure that the SourceConnectionFlatFile points to your RaleighIncidents2014.csv
	file.  You may need to unzip the file.
Then hit Execute and the package should load.
NOTE:  if you already have a table called RaleighIncident2014, you should drop it before running the package.
NOTE:  in the event the package does not load, you can import data via SSMS using the
Import Data wizard.  The settings you want to change are:
	- The text qualifier should be "
	- LCR DESC should have a length of 500
*/