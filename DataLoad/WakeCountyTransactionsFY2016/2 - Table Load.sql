USE [OutlierDetection]
GO
select * from dbo.WakeCountyTransactionsFY2016

--For purposes of normalization, we're going to set WIA Administration to WIOA Administration.
--The WIOA superceded the WIA, so for our purposes, we can treat them the same.  This also means that
--Division now has a functional dependency on DivCode.
UPDATE dbo.WakeCountyTransactionsFY2016
SET Division = 'WIOA Administration'
WHERE Division = 'WIA Administration';

CREATE TABLE Wake.Fund
(
	FundCode VARCHAR(5) NOT NULL,
	FundName VARCHAR(50) NOT NULL
);
ALTER TABLE Wake.Fund
	ADD CONSTRAINT [PK_Wake_Fund]
	PRIMARY KEY CLUSTERED(FundCode);

CREATE TABLE Wake.Department
(
	DepartmentCode VARCHAR(5) NOT NULL,
	DepartmentName VARCHAR(50) NOT NULL
);
ALTER TABLE Wake.Department
	ADD CONSTRAINT [PK_Wake_Department]
	PRIMARY KEY CLUSTERED(DepartmentCode);

CREATE TABLE Wake.Division
(
	DivisionCode VARCHAR(5) NOT NULL,
	DepartmentCode VARCHAR(5) NOT NULL,
	DivisionName VARCHAR(50) NOT NULL
);
ALTER TABLE Wake.Division
	ADD CONSTRAINT [PK_Wake_Division]
	PRIMARY KEY CLUSTERED(DivisionCode);
ALTER TABLE Wake.Division
	ADD CONSTRAINT [FK_Division_Department]
	FOREIGN KEY(DepartmentCode)
	REFERENCES Wake.Department(DepartmentCode);

CREATE TABLE Wake.ExpenditureType
(
	ExpenditureTypeCode VARCHAR(5) NOT NULL,
	ExpenditureTypeName VARCHAR(50) NOT NULL
);
ALTER TABLE Wake.ExpenditureType
	ADD CONSTRAINT [PK_Wake_ExpenditureType]
	PRIMARY KEY CLUSTERED(ExpenditureTypeCode);

CREATE TABLE Wake.ExpenditureCategory
(
	ExpenditureCategoryCode VARCHAR(5) NOT NULL,
	ExpenditureTypeCode VARCHAR(5) NOT NULL,
	ExpenditureCategoryName VARCHAR(50) NOT NULL
);
ALTER TABLE Wake.ExpenditureCategory
	ADD CONSTRAINT [PK_Wake_ExpenditureCategory]
	PRIMARY KEY CLUSTERED(ExpenditureCategoryCode);
ALTER TABLE Wake.ExpenditureType
	ADD CONSTRAINT [FK_ExpenditureCategory_ExpenditureType]
	FOREIGN KEY(ExpenditureTypeCode)
	REFERENCES Wake.ExpenditureType(ExpenditureTypeCode);

CREATE TABLE Wake.ExpenditureClass
(
	ExpenditureClassCode VARCHAR(5) NOT NULL,
	ExpenditureCategoryCode VARCHAR(5) NOT NULL,
	ExpenditureClassName VARCHAR(50) NOT NULL
);
ALTER TABLE Wake.ExpenditureClass
	ADD CONSTRAINT [PK_Wake_ExpenditureClass]
	PRIMARY KEY CLUSTERED(ExpenditureClassCode);
ALTER TABLE Wake.ExpenditureClass
	ADD CONSTRAINT [FK_ExpenditureClass_ExpenditureCategory]
	FOREIGN KEY(ExpenditureCategoryCode)
	REFERENCES Wake.ExpenditureCategory(ExpenditureCategoryCode);

CREATE TABLE Wake.ExpenditureLineItem
(
	ExpenditureLineItemCode VARCHAR(5) NOT NULL,
	ExpenditureCategoryCode VARCHAR(5) NOT NULL,
	ExpenditureLineItemName VARCHAR(150) NOT NULL
);
ALTER TABLE Wake.ExpenditureLineItem
	ADD CONSTRAINT [PK_Wake_ExpenditureLineItem]
	PRIMARY KEY CLUSTERED(ExpenditureLineItemCode);
ALTER TABLE Wake.ExpenditureLineItem
	ADD CONSTRAINT [FK_ExpenditureLineItem_ExpenditureCategory]
	FOREIGN KEY(ExpenditureCategoryCode)
	REFERENCES Wake.ExpenditureCategory(ExpenditureCategoryCode);

CREATE TABLE Wake.WakeTransaction
(
	WakeTransactionID INT IDENTITY(1,1) NOT NULL,
	BudgetedFiscalYear INT NOT NULL,
	FiscalYear INT NULL,
	FundCode INT NOT NULL,
	DivisionCode VARCHAR(5) NOT NULL,
	UnitCode VARCHAR(5) NULL,
	CostCenter VARCHAR(60) NOT NULL,
	ExpenditureClassCode VARCHAR(5) NOT NULL,
	ExpenditureLineItemCode VARCHAR(5) NOT NULL,
	RecordDate DATE NOT NULL,
	VendorName VARCHAR(128) NOT NULL,
	CheckNumber VARCHAR(20) NULL,
	DocumentID VARCHAR(50) NULL,
	BudgetedAmount DECIMAL(15,2) NULL,
	ActualAmount DECIMAL(15,2) NULL
);
ALTER TABLE Wake.WakeTransaction
	ADD CONSTRAINT [PK_WakeTransaction]
	PRIMARY KEY CLUSTERED(WakeTransactionID)
	WITH(DATA_COMPRESSION = PAGE);
GO

--Start loading reference data.
INSERT INTO Wake.Fund
(
	FundCode,
	FundName
)
SELECT DISTINCT
	FundCode,
	FundName
FROM dbo.WakeCountyTransactionsFY2016;

INSERT INTO Wake.Department
(
	DepartmentCode,
	DepartmentName
)
SELECT DISTINCT
	DeptCode,
	Department
FROM dbo.WakeCountyTransactionsFY2016;

INSERT INTO Wake.Division
(
	DivisionCode,
	DepartmentCode,
	DivisionName
)
SELECT DISTINCT
	DivCode,
	DeptCode,
	Division
FROM dbo.WakeCountyTransactionsFY2016;

INSERT INTO Wake.ExpenditureType
(
	ExpenditureTypeCode,
	ExpenditureTypeName
)
SELECT DISTINCT
	ObjTypeCode,
	ObjTypeName
FROM dbo.WakeCountyTransactionsFY2016;

INSERT INTO Wake.ExpenditureCategory
(
	ExpenditureCategoryCode,
	ExpenditureTypeCode,
	ExpenditureCategoryName
)
SELECT DISTINCT
	ObjCatCode,
	ObjTypeCode,
	ExpenditureCategory
FROM dbo.WakeCountyTransactionsFY2016;

INSERT INTO Wake.ExpenditureClass
(
	ExpenditureClassCode,
	ExpenditureCategoryCode,
	ExpenditureClassName
)
SELECT DISTINCT
	ObjClassCode,
	ObjCatCode,
	ObjClassName
FROM dbo.WakeCountyTransactionsFY2016;

--There are a few expenditure line item codes with two line item names.
--In each case, these appear to be roughly the same thing, so we'll treat them the same.
WITH records AS
(
	SELECT
		ObjCode,
		ObjCatCode,
		ExpenditureLineItem,
		ROW_NUMBER() OVER (PARTITION BY ObjCode ORDER BY ExpenditureLineItem ASC) AS rownum
	FROM dbo.WakeCountyTransactionsFY2016
)
INSERT INTO Wake.ExpenditureLineItem
(
	ExpenditureLineItemCode,
	ExpenditureCategoryCode,
	ExpenditureLineItemName
)
SELECT
	ObjCode,
	ObjCatCode,
	ExpenditureLineItem
FROM records
WHERE rownum = 1;

--Now load the main table
INSERT INTO Wake.WakeTransaction
(
	BudgetedFiscalYear,
	FiscalYear,
	FundCode,
	DivisionCode,
	UnitCode,
	CostCenter,
	ExpenditureClassCode,
	ExpenditureLineItemCode,
	RecordDate,
	VendorName,
	CheckNumber,
	DocumentID,
	BudgetedAmount,
	ActualAmount
)
SELECT
	BFY,
	FY,
	FundCode,
	DivCode,
	UnitCode,
	CostCenter,
	ObjClassCode,
	ObjCode,
	--Some of the dates came in as date-looking strings; others came in
	--as strings containing the integer value of the datetime
	COALESCE(TRY_PARSE(RecordDate AS DATE USING 'en-us'), TRY_CAST(TRY_CAST(RecordDate AS INT) AS DATETIME)),
	VendorName,
	CheckNumber,
	DocumentID,
	BudgetedAmount,
	ActualAmount
FROM dbo.WakeCountyTransactionsFY2016;
GO
