USE [OutlierDetection]
GO

CREATE TABLE Durham2017.Crime
(
	IncidentID INT NOT NULL,
	DateReported DATETIME NULL,
	DateOccurred DATETIME NULL,
	DateFound DATETIME NULL,
	IncidentReportCategory VARCHAR(15) NULL,
	UCRCode INT NULL,
	ReportedToUCR BIT NULL,
	ChargeDescription VARCHAR(75) NULL,
	CSStatus TINYINT NULL,
	CSStatusDate DATETIME NULL,
	District TINYINT NULL,
	Zone TINYINT NULL,
	IncidentLocation GEOGRAPHY NULL
);
ALTER TABLE Durham2017.Crime
	ADD CONSTRAINT [PK_Crime] PRIMARY KEY CLUSTERED(IncidentID)
	WITH(DATA_COMPRESSION = PAGE);
GO

--There are approximately a dozen duplicates where the GPS coordinates are nearly the same but not exactly.
--Filter these out using ROW_NUMBER.
WITH records AS
(
	SELECT
		p.INCI_ID AS IncidentID,
		TRY_PARSE(p.[DATE_REPT] AS DATETIME USING 'en-us') AS DateReported,
		TRY_PARSE(p.[DATE_OCCU] AS DATETIME USING 'en-us') AS DateOccurred,
		TRY_PARSE(p.[DATE_FND] AS DATETIME USING 'en-us') AS DateFound,
		p.REPORTEDAS AS IncidentReportCategory,
		p.UCR_CODE AS UCRCode,
		TRY_CAST(p.UCR_TYPE_O AS BIT) AS ReportedToUCR,
		p.CHRGDESC AS ChargeDescription,
		p.CSSTATUS AS CSStatus,
		TRY_PARSE(p.[CSSTATUSDT] AS DATETIME USING 'en-us') AS CSStatusDate,
		p.DIST AS District,
		TRY_CAST(SUBSTRING(p.BIG_ZONE, 6, 1) AS TINYINT) AS [Zone],
		CASE
			WHEN NULLIF(p.[Geo Point], '') IS NULL THEN NULL
			ELSE GEOGRAPHY::STPointFromText(CONCAT('POINT(', coord.Longitude, ' ', coord.latitude, ')'), 4326)
		END AS IncidentLocation,
		ROW_NUMBER() OVER (PARTITION BY p.INCI_ID ORDER BY p.[Geo Point]) AS rownum
	FROM Durham2017.DurhamCrime2017 p
		--The definition for GEOGRAPHY::STPointFromText for a point is POINT(Lon Lat) but we have
		--the incoming pairs as (Lat Lon).  These APPLY operators flip longitude and latitude for us.
		OUTER APPLY
		(
			SELECT REPLACE(REPLACE(REPLACE(p.[Geo Point], ',', ''), '(', ''), ')', '') AS latlonpair
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
		) coord
)
INSERT INTO Durham2017.Crime
(
	IncidentID,
	DateReported,
	DateOccurred,
	DateFound,
	IncidentReportCategory,
	UCRCode,
	ReportedToUCR,
	ChargeDescription,
	CSStatus,
	CSStatusDate,
	District,
	Zone,
	IncidentLocation
)
SELECT
	IncidentID,
	DateReported,
	DateOccurred,
	DateFound,
	IncidentReportCategory,
	UCRCode,
	ReportedToUCR,
	ChargeDescription,
	CSStatus,
	CSStatusDate,
	District,
	Zone,
	IncidentLocation
FROM records
WHERE
	rownum = 1;
GO
