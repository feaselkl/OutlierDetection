USE [OutlierDetection]
GO
/*
Goals:
	1)  Normalize the tables.  This means breaking out Incident Code (LCR)
		and Incident Description (LCR DESC) into their own table because LCR --> LCR DESC
	2)  Create primary and unique keys to guarantee uniqueness on tables
		and prevent duplicate rows from interfering with analysis.
	3)  Fix names and data types to make analysis easier.
	4)  Create foreign key constraints to give people an idea of how to link data together.
	5)  Create check constraints to ensure that invalid data cannot sneak in.
*/
CREATE TABLE Raleigh2014.IncidentCode
(
	IncidentCode VARCHAR(5) NOT NULL,
	IncidentDescription VARCHAR(55) NOT NULL
);
ALTER TABLE Raleigh2014.IncidentCode ADD CONSTRAINT [PK_IncidentCode]
	PRIMARY KEY CLUSTERED(IncidentCode);
GO
INSERT INTO Raleigh2014.IncidentCode
(
	IncidentCode,
	IncidentDescription
)
SELECT DISTINCT
	LCR,
	[LCR DESC]
FROM Raleigh2014.RaleighIncident2014;
GO

CREATE TABLE Raleigh2014.Incident
(
	IncidentID INT IDENTITY(1,1) NOT NULL,
	IncidentCode VARCHAR(5) NOT NULL,
	IncidentDate DATETIME,
	BeatID INT NOT NULL,
	IncidentNumber VARCHAR(19) NOT NULL,
	IncidentLocation GEOGRAPHY NULL
);
ALTER TABLE Raleigh2014.Incident ADD CONSTRAINT [PK_Incident]
	PRIMARY KEY CLUSTERED(IncidentID)
	WITH(DATA_COMPRESSION = PAGE);
ALTER TABLE Raleigh2014.Incident ADD CONSTRAINT [FK_Incident_IncidentCode]
	FOREIGN KEY(IncidentCode)
	REFERENCES Raleigh2014.IncidentCode(IncidentCode);
ALTER TABLE Raleigh2014.Incident ADD CONSTRAINT [UKC_Incident]
	UNIQUE(IncidentNumber)
	WITH(DATA_COMPRESSION = PAGE);
ALTER TABLE Raleigh2014.Incident ADD CONSTRAINT [CK_Incident_BeatID]
	CHECK(BeatID >= 0);
ALTER TABLE Raleigh2014.Incident ADD CONSTRAINT [CK_Incident_IncidentDate]
	CHECK(IncidentDate >= '2005-01-01' AND IncidentDate < '2015-01-01');

INSERT INTO Raleigh2014.Incident
(
	IncidentCode,
	IncidentDate,
	BeatID,
	IncidentNumber,
	IncidentLocation
)
SELECT
	p.LCR,
	TRY_PARSE(p.[INC DATETIME] AS DATETIME USING 'en-us') AS IncidentDate,
	p.BEAT,
	p.[INC NO],
	CASE
		WHEN NULLIF(p.[LOCATION], '') IS NULL THEN NULL
		ELSE GEOGRAPHY::STPointFromText(CONCAT('POINT(', coord.Longitude, ' ', coord.latitude, ')'), 4326)
	END AS IncidentLocation
FROM Raleigh2014.RaleighIncident2014 p
	--The definition for GEOGRAPHY::STPointFromText for a point is POINT(Lon Lat) but we have
	--the incoming pairs as (Lat Lon).  These APPLY operators flip longitude and latitude for us.
	OUTER APPLY
	(
		SELECT REPLACE(REPLACE(REPLACE(p.[LOCATION], ',', ''), '(', ''), ')', '') AS latlonpair
	) loc
	OUTER APPLY
	(
		SELECT CHARINDEX(' ', loc.latlonpair, 1) AS firstspace
	) latlon
	OUTER APPLY
	(
		SELECT
			SUBSTRING(loc.latlonpair, 1, latlon.firstspace - 1) AS Latitude,
			SUBSTRING(loc.latlonpair, latlon.firstspace + 1, LEN(loc.latlonpair)) AS Longitude
		WHERE
			latlon.firstspace > 0
	) coord;
GO
