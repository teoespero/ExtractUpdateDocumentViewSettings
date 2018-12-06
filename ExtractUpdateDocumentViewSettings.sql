-- extract
-- lets create our temp table that will
-- hold our district names
CREATE TABLE #tmpDatabases (
  ID int IDENTITY (1, 1) PRIMARY KEY,
  NAME nvarchar(100),
  SERVERNAME nvarchar(100),
  [READONLY] bit
);
  
-- fill it in with the dbNames
-- avoiding global and system related dbs
INSERT INTO #tmpDatabases (NAME, SERVERNAME, [READONLY])
  SELECT
    DatabaseName,
    ServerName,
    [ReadOnly]
  FROM DS_Admin..ADMIN_Districts
  WHERE (
  DatabaseName NOT LIKE '%demo%'
  AND DatabaseName NOT LIKE '%temp%'
  AND DatabaseName NOT LIKE '%ext%'
  AND DatabaseName NOT LIKE '%staff%'
  AND DatabaseName NOT LIKE '%test%'
  AND DatabaseName NOT LIKE '%dev%'
  AND DatabaseName LIKE 'ds%'
  )
  AND ServerName LIKE '%' + @@SERVERNAME + '%'
  AND ISNULL([ReadOnly], 0) = 0
  
------------------------------------------------------------------------------------------------------------------------------------------
-- begin the check process
-- Declare SQLString as nvarchar(4000)
-- for instances where we are connecting to a SQL Server 2000 instance,
-- we cannot use varchar(max) because this is a feature
-- introduced on SQL Server 2005
DECLARE @SQLString AS nvarchar(4000)
DECLARE @DS AS nvarchar(100)
DECLARE @DistrictCount int
DECLARE @Looper int
  
SET @Looper = 1
  
-- get the number of sites
SELECT
  @DistrictCount = COUNT(*)
FROM #tmpDatabases;
  
  
-- this part creates our temp table
-- that will hold our list
CREATE TABLE #myList (
  ID int IDENTITY (1, 1) PRIMARY KEY,
  DistrictID int,
  DistrictAbbrev nvarchar(300),
  DistrictTitle nvarchar(300),
  SecurityGroupNum int,
  GroupName nvarchar(300),
  DocumentAccessLevelOneView int,
  DocumentAccessLevelTwoView int,
  DocumentAccessLevelThreeView int,
  DocumentAccessLevelFourView int,
  DocumentAccessLevelFiveView int
);
  
-- crawl process
-- this part is where SQL is made to crawl the
-- different sites base on the entries
-- of #tmpDatabases
WHILE (@looper <= @DistrictCount)
BEGIN
  -- only do the check if tblSecurityGroup exist
  -- could be redundant since we are already
  -- screening out non district replated dbs
  IF (
    EXISTS (SELECT
      *
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_NAME = 'tblSecurityGroup')
    )
  BEGIN
    -- process each district
    SELECT
      @DS = NAME
    FROM #tmpDatabases
    WHERE ID = @looper
  
    SET @SQLString = '
                    insert into #myList
                    (
                        DistrictID,
                        DistrictAbbrev,
                        DistrictTitle,
                        SecurityGroupNum,
                        GroupName,
                        DocumentAccessLevelOneView,
                        DocumentAccessLevelTwoView,
                        DocumentAccessLevelThreeView,
                        DocumentAccessLevelFourView,
                        DocumentAccessLevelFiveView
                    )                  
                    SELECT
                        distinct
                        (SELECT DistrictID  FROM '+ @DS + '..tblDistrict) AS DistrictID ,
                        (SELECT DistrictAbbrev FROM '+ @DS + '..tblDistrict) AS DistrictAbbrev,
                        (SELECT DistrictTitle FROM '+ @DS + '..tblDistrict) AS DistrictTitle,
                        SecurityGroupNum,
                        GroupName,
                        isnull(DocumentAccessLevelOneView, 0) as DocumentAccessLevelOneView,
                        isnull(DocumentAccessLevelTwoView, 0) as DocumentAccessLevelTwoView,
                        isnull(DocumentAccessLevelThreeView, 0) as DocumentAccessLevelThreeView,
                        isnull(DocumentAccessLevelFourView, 0) as DocumentAccessLevelFourView,
                        isnull(DocumentAccessLevelFiveView, 0) as DocumentAccessLevelFiveView
                    FROM '+ @DS + '..tblSecurityGroup
                    WHERE
                        SecurityGroupNum IN (2000,1000,100)';
  
    -- run our string as an SQL
    EXECUTE sp_executesql @SQLString
  END
  
  
  SET @looper = @looper + 1
END
  
-- get our list
SELECT
  *
FROM #myList
ORDER BY
DistrictTitle ASC,
SecurityGroupNum ASC
  
-- housekeeping
DROP TABLE #tmpDatabases
DROP TABLE #myList
 
 
-- Update
UPDATE tblSecurityGroup
    SET
        DocumentAccessLevelOneView = 1,
        DocumentAccessLevelTwoView = 1,
        DocumentAccessLevelThreeView = 1,
        DocumentAccessLevelFourView = 1,
        DocumentAccessLevelFiveView = 1
WHERE
    SecurityGroupNum IN (2000,1000,100)
 
SELECT
    DistrictID,
    DistrictAbbrev,
    DistrictTitle
FROM tblDistrict
 
SELECT
    SecurityGroupNum,
    GroupName,
    DocumentAccessLevelOneView,
    DocumentAccessLevelTwoView,
    DocumentAccessLevelThreeView,
    DocumentAccessLevelFourView,
    DocumentAccessLevelFiveView
FROM tblSecurityGroup
WHERE
    SecurityGroupNum IN (2000,1000,100