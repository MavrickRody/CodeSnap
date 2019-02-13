SET ANSI_WARNINGS OFF

DECLARE @query AS NVARCHAR(MAX)
DECLARE @CurrentYearStartDate AS VARCHAR(10)
DECLARE @AsOfDate AS VARCHAR(10)
DECLARE @TableNamePrefix AS VARCHAR(10)
DECLARE @TableName AS VARCHAR(20)
DECLARE @TableNameAccrual AS VARCHAR(20)
DECLARE @TableNameCash AS VARCHAR(20)
DECLARE @JEType AS VARCHAR(20)
DECLARE @DBName AS VARCHAR(100) -- TB Data Table Data File


SET @DBName = 'ISTrialBalances'

SET @AsOfDate = '01/31/2019'
--201901---

SET @CurrentYearStartDate = '01/01/' + CAST(YEAR(@AsOfDate) AS NVARCHAR(MAX))

--change if required
SET @JEType = 'Monthly'
SET @TableNamePrefix = 'BQTB'


--do not make any changes from here
IF @JEType = 'Monthly'
	SET @TableName = @TableNamePrefix + CAST(YEAR(@AsOfDate) AS NVARCHAR(4)) + STUFF(CAST(MONTH(@AsOfDate) AS NVARCHAR(2)), 1, 0, REPLICATE('0', 2 - LEN(CAST(MONTH(@AsOfDate) AS NVARCHAR(2)))))
ELSE --yearly
	SET @TableName = @TableNamePrefix + CAST(YEAR(@AsOfDate) AS NVARCHAR(4))
SET @TableNameAccrual = @TableName + 'A'
SET @TableNameCash = @TableName + 'C'
SET @query = '
IF OBJECT_ID (''' + @DBName + '.dbo.' + @TableNameAccrual + ''',''U'') IS NOT NULL
   DROP TABLE ' + @DBName + '.dbo.' + @TableNameAccrual

EXEC (@query)

SET @query = '
IF OBJECT_ID (''' + @DBName + '.dbo.' + @TableNameCash + ''',''U'') IS NOT NULL
   DROP TABLE ' + @DBName + '.dbo.' + @TableNameCash

EXEC (@query)


--YTD TB Accrual
SET @query = '
 SELECT AccountList_DF.AccountID,  --Account ID
		SUM(ISNULL(TransactionSummary.DebitAmount,0)) AS DebitAmount, SUM(ISNULL(TransactionSummary.CreditAmount,0)) AS CreditAmount,
		SUM(ISNULL(TransactionSummary.DebitAmount,0)) - SUM(ISNULL(TransactionSummary.CreditAmount,0)) AS Balance -- Balance
 INTO ' + @DBName + '.dbo.' + @TableNameAccrual + '
 FROM   (dbo.AccountList AccountList_DF INNER JOIN dbo.TransactionSummary TransactionSummary ON AccountList_DF.AccountID=TransactionSummary.ThisAccountID) INNER JOIN 
 dbo.AccountTypeList AccountTypeList_DF ON AccountList_DF.AccountTypeID=AccountTypeList_DF.AccountTypeID 
 WHERE  (TransactionSummary.TransactionDate>=''01/01/1970''
 AND TransactionSummary.TransactionDate<=''' + @AsOfDate + ''') 
 AND TransactionSummary.MasterTransactionType<>46
 AND AccountTypeList_DF.AccountTypeID NOT IN (8,6,15,14,3)
 GROUP BY AccountList_DF.AccountID

 UNION ALL

 SELECT AccountList_DF.AccountID,  --Account ID
		SUM(ISNULL(TransactionSummary.DebitAmount,0)) AS DebitAmount, SUM(ISNULL(TransactionSummary.CreditAmount,0)) AS CreditAmount,
		SUM(ISNULL(TransactionSummary.DebitAmount,0)) - SUM(ISNULL(TransactionSummary.CreditAmount,0)) AS Balance -- Balance
 FROM   (dbo.AccountList AccountList_DF INNER JOIN dbo.TransactionSummary TransactionSummary ON AccountList_DF.AccountID=TransactionSummary.ThisAccountID) INNER JOIN 
 dbo.AccountTypeList AccountTypeList_DF ON AccountList_DF.AccountTypeID=AccountTypeList_DF.AccountTypeID 
 WHERE  (TransactionSummary.TransactionDate>=''' + @CurrentYearStartDate + '''
 AND TransactionSummary.TransactionDate<=''' + @AsOfDate + ''') 
 AND TransactionSummary.MasterTransactionType<>46
 AND AccountTypeList_DF.AccountTypeID IN (8,6,15,14,3)
 GROUP BY AccountList_DF.AccountID
 '
EXEC (@query)

SET @query = '
 IF NOT Exists(SELECT * FROM ' + @DBName + '.dbo.' + @TableNameAccrual + ' a WHERE AccountID=''3900'' )
 BEGIN
 Insert into ' + @DBName + '.dbo.' + @TableNameAccrual + ' 
 SELECT ''3900'',0,0,0
 END
 '
EXEC (@query)


SET @query = '
 UPDATE a SET Balance=a.Balance-(SELECT SUM(Balance) FROM ' + @DBName + '.dbo.' + @TableNameAccrual + ')  FROM ' + @DBName + '.dbo.' + @TableNameAccrual + ' a WHERE AccountID=''3900''
 '
EXEC (@query)

SET @query = '
 SELECT SUM(Balance) FROM ' + @DBName + '.dbo.' + @TableNameAccrual

EXEC (@query)
--------------




--YTD TB Cash

SET @query = '
SELECT AccountList_DF.AccountID,  --Account ID
  --SUM(ISNULL(TransactionDetailCash.DebitAmount,0)) AS DebitAmount, 
  --SUM(ISNULL(TransactionDetailCash.CreditAmount,0)) AS CreditAmount,
  SUM(ISNULL(TransactionDetailCash.DebitAmount,0)) - SUM(ISNULL(TransactionDetailCash.CreditAmount,0)) AS Balance
INTO ' + @DBName + '.dbo.' + @TableNameCash + '
FROM   (dbo.TransactionDetailCash TransactionDetailCash INNER JOIN dbo.AccountList AccountList_DF ON TransactionDetailCash.AccountID=AccountList_DF.AccountID) INNER JOIN 
dbo.AccountTypeList AccountTypeList_DF ON AccountList_DF.AccountTypeID=AccountTypeList_DF.AccountTypeID 
WHERE  (TransactionDetailCash.Date>=''01/01/1970'' AND TransactionDetailCash.Date<=''' + @AsOfDate + ''')
 AND AccountTypeList_DF.AccountTypeID NOT IN (8,6,15,14,3)
GROUP BY AccountList_DF.AccountID

UNION ALL

SELECT AccountList_DF.AccountID,  --Account ID
  --SUM(ISNULL(TransactionDetailCash.DebitAmount,0)) AS DebitAmount, 
  --SUM(ISNULL(TransactionDetailCash.CreditAmount,0)) AS CreditAmount,
  SUM(ISNULL(TransactionDetailCash.DebitAmount,0)) - SUM(ISNULL(TransactionDetailCash.CreditAmount,0)) AS Balance
FROM   (dbo.TransactionDetailCash TransactionDetailCash INNER JOIN dbo.AccountList AccountList_DF ON TransactionDetailCash.AccountID=AccountList_DF.AccountID) INNER JOIN 
dbo.AccountTypeList AccountTypeList_DF ON AccountList_DF.AccountTypeID=AccountTypeList_DF.AccountTypeID 
WHERE  (TransactionDetailCash.Date>=''' + @CurrentYearStartDate + ''' AND TransactionDetailCash.Date<=''' + @AsOfDate + ''')
 AND AccountTypeList_DF.AccountTypeID IN (8,6,15,14,3)
GROUP BY AccountList_DF.AccountID
'

EXEC (@query)

SET @query = '
 IF NOT Exists(SELECT * FROM ' + @DBName + '.dbo.' + @TableNameCash + ' a WHERE AccountID=''3900'' )
 BEGIN
 Insert into ' + @DBName + '.dbo.' + @TableNameCash + ' 
 SELECT ''3900'',0
 END
'
EXEC (@query)

SET @query = '
UPDATE a SET Balance=a.Balance-(SELECT SUM(Balance) FROM ' + @DBName + '.dbo.' + @TableNameCash + ')  FROM ' + @DBName + '.dbo.' + @TableNameCash + ' a WHERE AccountID=''3900''
'
EXEC (@query)

SET @query = '
 SELECT SUM(Balance) FROM ' + @DBName + '.dbo.' + @TableNameCash

EXEC (@query)
------------------------

IF COL_LENGTH('ISTrialBalances.dbo.QBTB201901A', 'Accountid') IS NOT NULL
BEGIN
	PRINT 'Already'
END
ELSE
BEGIN
	ALTER TABLE ISTrialBalances.dbo.QBTB201901A
	ADD Accountid VARCHAR(MAX)
END
GO

IF COL_LENGTH('ISTrialBalances.dbo.QBTB201901A', 'qblinkid') IS NOT NULL
BEGIN
	PRINT 'Already'
END

ELSE
BEGIN
	ALTER TABLE ISTrialBalances.dbo.QBTB201901A
	ADD qblinkid VARCHAR(MAX)
END
GO

DELETE FROM ISTrialBalances.dbo.QBTB201901A
WHERE F2 IS NULL

DELETE FROM ISTrialBalances.dbo.QBTB201901C
WHERE F2 IS NULL

UPDATE ISTrialBalances.dbo.QBTB201901A
SET qblinkid = NULL

UPDATE ISTrialBalances.dbo.QBTB201901A
SET Accountid = NULL

UPDATE a
SET a.qblinkid = aa.ListID
FROM ISTrialBalances.dbo.QBTB201901A a
JOIN ISQuickBooksTables.dbo.Account aa
	ON LTRIM(RTRIM(SUBSTRING(f2, CHARINDEX('·', f2) + 1, LEN(f2)))) = aa.FullName
---184

UPDATE a
SET a.Accountid = aa.AccountID
FROM ISTrialBalances.dbo.QBTB201901A a
JOIN ISArchiBillQuick.dbo.AccountList aa
	ON a.qblinkid = aa.QBLinkID
---184


IF COL_LENGTH('ISTrialBalances.dbo.QBTB201901C', 'Accountid') IS NOT NULL
BEGIN
	PRINT 'Already'
END

ELSE
BEGIN
	ALTER TABLE ISTrialBalances.dbo.QBTB201901C
	ADD Accountid VARCHAR(MAX)
END
GO

IF COL_LENGTH('ISTrialBalances.dbo.QBTB201901C', 'qblinkid') IS NOT NULL
BEGIN
	PRINT 'Already'
END

ELSE
BEGIN
	ALTER TABLE ISTrialBalances.dbo.QBTB201901C
	ADD qblinkid VARCHAR(MAX)
END
GO

UPDATE ISTrialBalances.dbo.QBTB201901C
SET qblinkid = NULL

UPDATE ISTrialBalances.dbo.QBTB201901C
SET Accountid = NULL


UPDATE a
SET a.qblinkid = aa.ListID
FROM ISTrialBalances.dbo.QBTB201901C a
JOIN ISQuickBooksTables.dbo.Account aa
	ON LTRIM(RTRIM(SUBSTRING(f2, CHARINDEX('·', f2) + 1, LEN(f2)))) = aa.FullName
---184

UPDATE a
SET a.Accountid = aa.AccountID
FROM ISTrialBalances.dbo.QBTB201901C a
JOIN ISArchiBillQuick.dbo.AccountList aa
	ON a.qblinkid = aa.QBLinkID
---184
SELECT
	*
FROM ISTrialBalances.dbo.QBTB201901A
WHERE Accountid IS NULL
SELECT
	*
FROM ISTrialBalances.dbo.QBTB201901C
WHERE Accountid IS NULL
SELECT
	SUM(credit),
	SUM(debit)
FROM ISTrialBalances.dbo.QBTB201901A
SELECT
	SUM(credit),
	SUM(debit)
FROM ISTrialBalances.dbo.QBTB201901C

------------------------------------------------------

-------------------------------------------------------------Accrual Cleanup
IF COL_LENGTH('ISTrialBalances.dbo.QBTB201901A', 'Balance') IS NOT NULL
BEGIN
	PRINT 'Already'
END

ELSE
BEGIN
	ALTER TABLE ISTrialBalances.dbo.QBTB201901A
	ADD Balance MONEY
END
GO

UPDATE ISTrialBalances.dbo.QBTB201901A
SET Balance = 0

UPDATE ISTrialBalances.dbo.QBTB201901A
SET Balance = ISNULL(CASE
	WHEN Debit <> 0 THEN Debit
	WHEN credit <> 0 THEN Credit * -1
END, 0)
--92

IF COL_LENGTH('ISTrialBalances.dbo.QBTB201901A', 'FinalBalance') IS NOT NULL
BEGIN
	PRINT 'Already'
END

ELSE
BEGIN
	ALTER TABLE ISTrialBalances.dbo.QBTB201901A
	ADD FinalBalance MONEY
END

GO

UPDATE ISTrialBalances.dbo.QBTB201901A
SET FinalBalance = 0


UPDATE a
SET FinalBalance = a.Balance
FROM ISTrialBalances.dbo.QBTB201901A a
WHERE a.AccountID NOT IN (SELECT
	[AccountID]
FROM ISTrialBalances.dbo.BQTB201901A
WHERE [AccountID] IS NOT NULL)
AND a.AccountID IS NOT NULL
--76

UPDATE a
SET a.FinalBalance = a.Balance - aa.balance
FROM ISTrialBalances.dbo.QBTB201901A a
INNER JOIN ISTrialBalances.dbo.BQTB201901A aa
	ON a.AccountID = aa.[AccountID]
--3

DELETE FROM ISTrialBalances.dbo.QBTB201901A
WHERE F2 IS NULL

INSERT INTO ISTrialBalances.dbo.QBTB201901A (AccountID, FinalBalance)
	SELECT
		[AccountID],
		balance * -1
	FROM ISTrialBalances.dbo.BQTB201901A
	WHERE [AccountID] NOT IN (SELECT
		AccountID
	FROM ISTrialBalances.dbo.QBTB201901A
	WHERE AccountID IS NOT NULL)
	AND [AccountID] IS NOT NULL
	AND balance <> 0
--3
SELECT
	*
FROM ISTrialBalances.dbo.QBTB201901A
WHERE AccountID IS NULL
-------------------------------------------------------------Cash Cleanup
SELECT
	AccountID
FROM ISTrialBalances.dbo.QBTB201901C
GROUP BY AccountID
HAVING COUNT(*) > 1

IF COL_LENGTH('ISTrialBalances.dbo.QBTB201901C', 'Balance') IS NOT NULL
BEGIN
	PRINT 'Already'
END

ELSE
BEGIN
	ALTER TABLE ISTrialBalances.dbo.QBTB201901C
	ADD Balance MONEY
END
GO
UPDATE ISTrialBalances.dbo.QBTB201901C
SET Balance = 0
UPDATE ISTrialBalances.dbo.QBTB201901C
SET Balance = ISNULL(CASE
	WHEN Debit <> 0 THEN Debit
	WHEN credit <> 0 THEN Credit * -1
END, 0)
--92

IF COL_LENGTH('ISTrialBalances.dbo.QBTB201901C', 'FinalBalance') IS NOT NULL
BEGIN
	PRINT 'Already'
END

ELSE
BEGIN
	ALTER TABLE ISTrialBalances.dbo.QBTB201901C
	ADD FinalBalance MONEY
END
GO

UPDATE ISTrialBalances.dbo.QBTB201901C
SET FinalBalance = 0
UPDATE a
SET FinalBalance = a.Balance
FROM ISTrialBalances.dbo.QBTB201901C a
WHERE a.AccountID NOT IN (SELECT
	[AccountID]
FROM ISTrialBalances.dbo.BQTB201901C
WHERE [AccountID] IS NOT NULL)
AND a.AccountID IS NOT NULL
--76
UPDATE a
SET a.FinalBalance = a.Balance - aa.balance
FROM ISTrialBalances.dbo.QBTB201901C a
INNER JOIN ISTrialBalances.dbo.BQTB201901C aa
	ON a.AccountID = aa.[AccountID]
--3
DELETE FROM ISTrialBalances.dbo.QBTB201901C
WHERE F2 IS NULL

INSERT INTO ISTrialBalances.dbo.QBTB201901C (AccountID, FinalBalance)
	SELECT
		[AccountID],
		balance * -1
	FROM ISTrialBalances.dbo.BQTB201901C
	WHERE [AccountID] NOT IN (SELECT
		AccountID
	FROM ISTrialBalances.dbo.QBTB201901C
	WHERE AccountID IS NOT NULL)
	AND [AccountID] IS NOT NULL
	AND balance <> 0
--3
IF COL_LENGTH('ISTrialBalances.dbo.QBTB201901A', 'JournalType') IS NOT NULL
BEGIN
	PRINT 'Already'
END
ELSE
BEGIN
	ALTER TABLE ISTrialBalances.dbo.QBTB201901A
	ADD JournalType VARCHAR(MAX)
END

GO

IF COL_LENGTH('ISTrialBalances.dbo.QBTB201901C', 'JournalType') IS NOT NULL
BEGIN
	PRINT 'Already'
END
ELSE
BEGIN
	ALTER TABLE ISTrialBalances.dbo.QBTB201901C
	ADD JournalType VARCHAR(MAX)

END

GO
UPDATE ISTrialBalances.dbo.QBTB201901C
SET JournalType = NULL
UPDATE ISTrialBalances.dbo.QBTB201901A
SET JournalType = NULL
UPDATE T
SET t.JournalType = 'Hybrid'
FROM ISTrialBalances.dbo.QBTB201901C t
INNER JOIN ISTrialBalances.dbo.QBTB201901A tt
	ON t.AccountID = tt.AccountID
	AND tt.FinalBalance = t.FinalBalance
	AND t.FinalBalance <> 0
--64
UPDATE tt
SET tt.JournalType = 'Hybrid'
FROM ISTrialBalances.dbo.QBTB201901C t
INNER JOIN ISTrialBalances.dbo.QBTB201901A tt
	ON t.AccountID = tt.AccountID
	AND tt.FinalBalance = t.FinalBalance
	AND t.FinalBalance <> 0
--64
SELECT
	SUM(Debit),
	SUM(Credit)
FROM ISTrialBalances.dbo.QBTB201901C
SELECT
	SUM(Debit),
	SUM(Credit)
FROM ISTrialBalances.dbo.QBTB201901A
SELECT
	SUM(FinalBalance)
FROM ISTrialBalances.dbo.QBTB201901C
SELECT
	SUM(FinalBalance)
FROM ISTrialBalances.dbo.QBTB201901A
SELECT
	*
FROM ISTrialBalances.dbo.QBTB201901C
WHERE AccountID IS NULL
SELECT
	*
FROM ISTrialBalances.dbo.QBTB201901C
WHERE QBLinkID = AccountID
SELECT
	AccountID
FROM ISTrialBalances.dbo.QBTB201901A
GROUP BY AccountID
HAVING COUNT(*) > 1
SELECT
	AccountID
FROM ISTrialBalances.dbo.QBTB201901C
GROUP BY AccountID
HAVING COUNT(*) > 1
-----------------------
/*Logic for Hybrid Entry*/
/*Revised by : Waseem*/
/*4-6-2018*/
---201901---
---01/31/2019--
SET ANSI_WARNINGS OFF
GO
DELETE FROM APTransactionDetails
WHERE LastUpdatedBy = 'CJ201901HYB';
DELETE FROM APTransactiontable
WHERE LastUpdatedBy = 'CJ201901HYB';
/*Parent Entry*/
IF EXISTS (SELECT
		COUNT(*)
	FROM ISTrialBalances.dbo.QBTB201901C qa
	WHERE qa.FinalBalance IS NOT NULL
	AND FinalBalance <> 0
	AND JournalType = 'Hybrid'
	AND qa.FinalBalance < 0
	HAVING SUM(qa.FinalBalance * -1) IS NOT NULL)

BEGIN

	INSERT INTO APTransactionTable (APTransactionID, TransactionType, TransactionDate, CreatedOn, LastUpdated, TransactionAmount, parentaccountid, lastupdatedby)
		SELECT
			NEWID(),
			5,
			'01/31/2019',
			'01/31/2019',
			GETUTCDATE(),
			SUM(qa.FinalBalance * -1),
			MAX(LTRIM(RTRIM(Accountid))),
			'CJ201901HYB'
		FROM ISTrialBalances.dbo.QBTB201901C qa
		WHERE qa.FinalBalance IS NOT NULL
		AND FinalBalance <> 0
		AND JournalType = 'Hybrid'
		AND qa.FinalBalance < 0
		HAVING SUM(qa.FinalBalance * -1) IS NOT NULL;

END

ELSE

BEGIN

	IF EXISTS (SELECT
			COUNT(*)
		FROM ISTrialBalances.dbo.QBTB201901C qa
		WHERE qa.FinalBalance IS NOT NULL
		AND FinalBalance <> 0
		AND JournalType = 'Hybrid'
		AND qa.FinalBalance > 0
		HAVING SUM(qa.FinalBalance * -1) IS NOT NULL)
	BEGIN

		INSERT INTO APTransactionTable (APTransactionID, TransactionType, TransactionDate, CreatedOn, LastUpdated, TransactionAmount, parentaccountid, lastupdatedby)
			SELECT
				NEWID(),
				5,
				'01/31/2019',
				'01/31/2019',
				GETUTCDATE(),
				SUM(qa.FinalBalance * -1),
				MAX(LTRIM(RTRIM(Accountid))),
				'CJ201901HYB'
			FROM ISTrialBalances.dbo.QBTB201901C qa
			WHERE qa.FinalBalance IS NOT NULL
			AND FinalBalance <> 0
			AND JournalType = 'Hybrid'
			AND qa.FinalBalance > 0
			HAVING SUM(qa.FinalBalance * -1) IS NOT NULL;
	END
	ELSE
	BEGIN
		GOTO Branch_One
	END
END
/*End Parent Entry*/

/*Credit Side*/
IF EXISTS (SELECT
		*
	FROM ISTrialBalances.dbo.QBTB201901C t
	WHERE t.FinalBalance IS NOT NULL
	AND t.FinalBalance <> 0
	AND t.FinalBalance < 0
	AND t.JournalType = 'Hybrid')
BEGIN

	INSERT INTO APTransactionDetails (APTransDetailID, ApTransactionID, TransactionType, TransactionDate, CreditAccountID, CreditAmount, LastUpdated, CreatedOn, ThisAccountID, LastUpdatedBy)
		SELECT
			NEWID(),
			(SELECT
				APTransactionID
			FROM APTransactionTable
			WHERE LastUpdatedBy = 'CJ201901HYB'),
			20,
			'01/31/2019',
			LTRIM(RTRIM(Accountid)),
			(t.FinalBalance * -1),
			GETUTCDATE(),
			'01/31/2019',
			LTRIM(RTRIM(Accountid)),
			'CJ201901HYB'
		FROM ISTrialBalances.dbo.QBTB201901C t
		WHERE t.FinalBalance IS NOT NULL
		AND t.FinalBalance <> 0
		AND t.FinalBalance < 0
		AND t.JournalType = 'Hybrid';
END
ELSE

BEGIN
	PRINT 'Nothing'
END
/*End Credit Side*/

/*Debit Side*/

IF EXISTS (SELECT
		*
	FROM ISTrialBalances.dbo.QBTB201901C t
	WHERE t.FinalBalance IS NOT NULL
	AND t.FinalBalance <> 0
	AND t.FinalBalance > 0
	AND t.JournalType = 'Hybrid')
BEGIN
	INSERT INTO dbo.APTransactionDetails (APTransDetailID, ApTransactionID, TransactionType, TransactionDate, DebitAccountID, DebitAmount, LastUpdated, CreatedOn, ThisAccountID, LastUpdatedBy)
		SELECT
			NEWID(),
			(SELECT
				APTransactionID
			FROM APTransactionTable
			WHERE LastUpdatedBy = 'CJ201901HYB'),
			5,
			'01/31/2019',
			LTRIM(RTRIM(Accountid)),
			(t.FinalBalance),
			GETUTCDATE(),
			'01/31/2019',
			LTRIM(RTRIM(Accountid)),
			'CJ201901HYB'
		FROM ISTrialBalances.dbo.QBTB201901C t
		WHERE t.FinalBalance IS NOT NULL
		AND t.FinalBalance <> 0
		AND t.FinalBalance > 0
		AND t.JournalType = 'Hybrid';

END
ELSE
BEGIN
	----For debit ZERO
	INSERT INTO dbo.APTransactionDetails (APTransDetailID,
	ApTransactionID,
	TransactionType,
	TransactionDate,
	DebitAccountID,
	DebitAmount,
	LastUpdated,
	CreatedOn,
	ThisAccountID,
	LastUpdatedBy)
		SELECT
			NEWID(),
			(SELECT
				APTransactionID
			FROM APTransactionTable
			WHERE LastUpdatedBy = 'CJ201901HYB'),
			5,
			'01/31/2019',
			'BQ101',
			0,
			GETUTCDATE(),
			'01/31/2019',
			'BQ101',
			'CJ201901HYB';
END;

/*End Debit Side*/

---Adjustment
INSERT INTO APTransactionDetails (APTransDetailID,
ApTransactionID,
TransactionType,
TransactionDate,
CreditAccountID,
CreditAmount,
LastUpdated,
CreatedOn,
ThisAccountID,
LastUpdatedBy)
	SELECT
		NEWID(),
		(SELECT
			APTransactionID
		FROM APTransactionTable
		WHERE LastUpdatedBy = 'CJ201901HYB'),
		20,
		'01/31/2019',
		'BQ101',
		(SUM(ISNULL(CreditAmount, 0)) - SUM(ISNULL(DebitAmount, 0))) * -1,
		GETUTCDATE(),
		'01/31/2019',
		'BQ101',
		'CJ201901HYB'
	FROM APTransactionDetails
	WHERE LastUpdatedBy = 'CJ201901HYB'
	HAVING (SUM(ISNULL(CreditAmount, 0)) - SUM(ISNULL(DebitAmount, 0))) * -1 <> 0;
UPDATE APTransactionTable
SET TransactionAmount = (SELECT
	SUM(CreditAmount)
FROM APTransactionDetails
WHERE LastUpdatedBy = 'CJ201901HYB')
WHERE APTransactionID = (SELECT
	APTransactionID
FROM APTransactionTable
WHERE LastUpdatedBy = 'CJ201901HYB')

UPDATE a
SET a.TransactionType = '5'
FROM APTransactionDetails a
JOIN APTransactionTable aa
	ON a.ApTransactionID = aa.APTransactionID
WHERE aa.ParentAccountID <> a.ThisAccountID
AND a.LastUpdatedBy = 'CJ201901HYB'

/*Test cases*/
DECLARE @Sql NVARCHAR(MAX),
		@sql1 NVARCHAR(MAX),
		@sql2 NVARCHAR(MAX),
		@sql3 NVARCHAR(MAX)

SET @SQl = (SELECT
	COUNT(*)
FROM APTransactionDetails
WHERE LastUpdatedBy = 'CJ201901HYB'
AND TransactionType = '20')
IF @sql = 1
	PRINT 'Pass Test Case 1'
IF EXISTS (SELECT
		COUNT(*)
	FROM APTransactionDetails
	WHERE TransactionType = '20'
	GROUP BY ApTransactionID,
			 TransactionType
	HAVING COUNT(*) > 1)
BEGIN
	PRINT 'Failed=Test Case 2'
	SELECT
		ApTransactionID,
		TransactionType
	FROM APTransactionDetails
	WHERE TransactionType = '20'
	GROUP BY ApTransactionID,
			 TransactionType
	HAVING COUNT(*) > 1
END
ELSE
BEGIN
	PRINT 'Pass Test Case 2'
END
SET @sql2 = (SELECT
	SUM(DebitAmount) - SUM(CreditAmount)
FROM APTransactionDetails)

IF (@sql2 = 0.00)
BEGIN
	PRINT 'Pass Test Case 3'
END
ELSE
BEGIN
	PRINT 'Failed Test Case 3'
END

IF EXISTS (SELECT
		*
	FROM APTransactionDetails
	GROUP BY ApTransactionID
	HAVING SUM(DebitAmount) <> SUM(CreditAmount))
BEGIN
	PRINT 'Failed=Test Case 4'
	SELECT
		SUM(DebitAmount),
		SUM(CreditAmount),
		ApTransactionID
	FROM APTransactionDetails
	GROUP BY ApTransactionID
	HAVING SUM(DebitAmount) <> SUM(CreditAmount)
END
ELSE
BEGIN
	PRINT 'Pass Test Case 4'
END

IF EXISTS (SELECT
		*
	FROM APTransactionTable a
	INNER JOIN (SELECT
		SUM(DebitAmount) AS amt,
		ApTransactionID AS id
	FROM APTransactionDetails
	GROUP BY ApTransactionID) aa
		ON a.APTransactionID = aa.id
	WHERE a.TransactionAmount <> aa.amt
	AND a.TransactionType <> '4')
BEGIN
	PRINT 'Failed=Test Case 5'
	SELECT
		*
	FROM APTransactionTable a
	INNER JOIN (SELECT
		SUM(CreditAmount) AS amt,
		ApTransactionID AS id
	FROM APTransactionDetails
	GROUP BY ApTransactionID) aa
		ON a.APTransactionID = aa.id
	WHERE a.TransactionAmount <> aa.amt
	AND a.TransactionType <> '4';
END
ELSE
BEGIN
	PRINT 'Pass Test Case 5'
END

IF EXISTS (SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID IS NULL)
BEGIN
	PRINT 'Failed=Test Case 6'
	SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID IS NULL
END
ELSE
BEGIN
	PRINT 'Pass Test Case 6'
END


IF EXISTS (SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID <> CreditAccountID
	AND CreditAccountID IS NOT NULL)
BEGIN
	PRINT 'Failed=Test Case 7'
	SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID <> CreditAccountID
	AND CreditAccountID IS NOT NULL
END
ELSE
BEGIN
	PRINT 'Pass Test Case 7'
END


IF EXISTS (SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID <> DebitAccountID
	AND DebitAccountID IS NOT NULL)
BEGIN
	PRINT 'Failed=Test Case 8'
	SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID <> DebitAccountID
	AND DebitAccountID IS NOT NULL
END
ELSE
BEGIN
	PRINT 'Pass Test Case 8'
END

IF EXISTS (SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID NOT IN (SELECT
		AccountID
	FROM AccountList))
BEGIN
	PRINT 'Failed=Test Case 9'
	SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID NOT IN (SELECT
		AccountID
	FROM AccountList)
END
ELSE
BEGIN
	PRINT 'Pass Test Case 9'
END

IF EXISTS (SELECT
		*
	FROM APTransactionTable
	WHERE ParentAccountID IS NULL)
BEGIN
	PRINT 'Failed=Test Case 10'
	SELECT
		*
	FROM APTransactionTable
	WHERE ParentAccountID IS NULL
END
ELSE
BEGIN
	PRINT 'Pass Test Case 10'
END


IF EXISTS (SELECT
		*
	FROM APTransactionTable
	WHERE ParentAccountID NOT IN (SELECT
		AccountID
	FROM AccountList))
BEGIN
	PRINT 'Failed=Test Case 11'
	SELECT
		*
	FROM APTransactionTable
	WHERE ParentAccountID NOT IN (SELECT
		AccountID
	FROM AccountList)
END
ELSE
BEGIN
	PRINT 'Pass Test Case 11'
END

/*End Test Cases*/

-----------------------------AS of 201901 ACCRUAL--
Branch_One:
DELETE FROM APTransactionDetails
WHERE LastUpdatedBy = 'CJ201901A'
GO
DELETE FROM APTransactiontable
WHERE LastUpdatedBy = 'CJ201901A'
GO

DECLARE @flag NVARCHAR(MAX);

IF EXISTS (SELECT
		COUNT(*)
	FROM ISTrialBalances.dbo.QBTB201901A qa
	WHERE qa.FinalBalance IS NOT NULL
	AND FinalBalance <> 0
	AND JournalType IS NULL
	AND qa.FinalBalance > 0
	HAVING SUM(qa.FinalBalance * -1) IS NOT NULL)
BEGIN

	INSERT INTO APTransactionTable (APTransactionID,
	TransactionType,
	TransactionDate,
	CreatedOn,
	LastUpdated,
	TransactionAmount,
	parentaccountid,
	lastupdatedby)
		SELECT
			NEWID(),
			45,
			'01/31/2019',
			'01/31/2019',
			GETUTCDATE(),
			SUM(qa.FinalBalance * -1),
			MAX(LTRIM(RTRIM(Accountid))),
			'CJ201901A'
		FROM ISTrialBalances.dbo.QBTB201901A qa
		WHERE qa.FinalBalance IS NOT NULL
		AND FinalBalance <> 0
		AND JournalType IS NULL
		AND qa.FinalBalance > 0
		HAVING SUM(qa.FinalBalance * -1) IS NOT NULL;

	SET @flag = 'DebitSideParent';

END;

ELSE
BEGIN

	IF EXISTS (SELECT
			*
		FROM ISTrialBalances.dbo.QBTB201901A qa
		WHERE qa.FinalBalance IS NOT NULL
		AND FinalBalance <> 0
		AND JournalType IS NULL
		AND qa.FinalBalance < 0
		HAVING SUM(qa.FinalBalance * -1) IS NOT NULL)
	BEGIN

		INSERT INTO APTransactionTable (APTransactionID,
		TransactionType,
		TransactionDate,
		CreatedOn,
		LastUpdated,
		TransactionAmount,
		parentaccountid,
		lastupdatedby)
			SELECT
				NEWID(),
				45,
				'01/31/2019',
				'01/31/2019',
				GETUTCDATE(),
				SUM(qa.FinalBalance * -1),
				MAX(LTRIM(RTRIM(Accountid))),
				'CJ201901A'
			FROM ISTrialBalances.dbo.QBTB201901A qa
			WHERE qa.FinalBalance IS NOT NULL
			AND FinalBalance <> 0
			AND JournalType IS NULL
			AND qa.FinalBalance < 0
			HAVING SUM(qa.FinalBalance * -1) IS NOT NULL;

		SET @flag = 'CreditSideParent';
	END
	ELSE
	BEGIN

		GOTO Branch_Cash
	END

END;

----------Credit SIDE----------------------------

IF EXISTS (SELECT
		*
	FROM ISTrialBalances.dbo.QBTB201901A t
	WHERE t.FinalBalance IS NOT NULL
	AND t.FinalBalance <> 0
	AND t.FinalBalance < 0
	AND t.JournalType IS NULL)
BEGIN

	---credit Side
	INSERT INTO APTransactionDetails (APTransDetailID,
	ApTransactionID,
	TransactionType,
	TransactionDate,
	CreditAccountID,
	CreditAmount,
	LastUpdated,
	CreatedOn,
	ThisAccountID,
	LastUpdatedBy)
		SELECT
			NEWID(),
			(SELECT
				APTransactionID
			FROM APTransactionTable
			WHERE LastUpdatedBy = 'CJ201901A'),
			CASE
				WHEN @flag = 'CreditSideParent' THEN 20
				ELSE 45
			END,
			'01/31/2019',
			LTRIM(RTRIM(Accountid)),
			(t.FinalBalance * -1),
			GETUTCDATE(),
			'01/31/2019',
			LTRIM(RTRIM(Accountid)),
			'CJ201901A'
		FROM ISTrialBalances.dbo.QBTB201901A t
		WHERE t.FinalBalance IS NOT NULL
		AND t.FinalBalance <> 0
		AND t.FinalBalance < 0
		AND t.JournalType IS NULL;
END;

ELSE
BEGIN
	---when Credit is ZERO
	INSERT INTO dbo.APTransactionDetails (APTransDetailID,
	ApTransactionID,
	TransactionType,
	TransactionDate,
	CreditAccountID,
	CreditAmount,
	LastUpdated,
	CreatedOn,
	ThisAccountID,
	LastUpdatedBy)
		SELECT
			NEWID(),
			(SELECT
				APTransactionID
			FROM APTransactionTable
			WHERE LastUpdatedBy = 'CJ201901A'),
			CASE
				WHEN @flag = 'CreditSideParent' THEN 20
				ELSE 45
			END,
			'01/31/2019',
			'BQ101',
			0,
			GETUTCDATE(),
			'01/31/2019',
			'BQ101',
			'CJ201901A';

END;

/****************Debit*/
IF EXISTS (SELECT
		*
	FROM ISTrialBalances.dbo.QBTB201901A t
	WHERE t.FinalBalance IS NOT NULL
	AND t.FinalBalance <> 0
	AND t.FinalBalance > 0
	AND t.JournalType IS NULL)
BEGIN
	----Debit Side

	INSERT INTO dbo.APTransactionDetails (APTransDetailID,
	ApTransactionID,
	TransactionType,
	TransactionDate,
	DebitAccountID,
	DebitAmount,
	LastUpdated,
	CreatedOn,
	ThisAccountID,
	LastUpdatedBy)
		SELECT
			NEWID(),
			(SELECT
				APTransactionID
			FROM APTransactionTable
			WHERE LastUpdatedBy = 'CJ201901A'),
			CASE
				WHEN @flag = 'CreditSideParent' THEN 45
				ELSE 20
			END,
			'01/31/2019',
			LTRIM(RTRIM(Accountid)),
			(t.FinalBalance),
			GETUTCDATE(),
			'01/31/2019',
			LTRIM(RTRIM(Accountid)),
			'CJ201901A'
		FROM ISTrialBalances.dbo.QBTB201901A t
		WHERE t.FinalBalance IS NOT NULL
		AND t.FinalBalance <> 0
		AND t.FinalBalance > 0
		AND t.JournalType IS NULL;
---25
----5

END;

ELSE
BEGIN
	---where Debit is not Zero
	INSERT INTO dbo.APTransactionDetails (APTransDetailID,
	ApTransactionID,
	TransactionType,
	TransactionDate,
	DebitAccountID,
	DebitAmount,
	LastUpdated,
	CreatedOn,
	ThisAccountID,
	LastUpdatedBy)
		SELECT
			NEWID(),
			(SELECT
				APTransactionID
			FROM APTransactionTable
			WHERE LastUpdatedBy = 'CJ201901A'),
			CASE
				WHEN @flag = 'CreditSideParent' THEN 45
				ELSE 20
			END,
			'01/31/2019',
			LTRIM(RTRIM(Accountid)),
			(t.FinalBalance),
			GETUTCDATE(),
			'01/31/2019',
			LTRIM(RTRIM(Accountid)),
			'CJ201901A'
		FROM ISTrialBalances.dbo.QBTB201901A t
		WHERE t.FinalBalance IS NOT NULL
		AND t.FinalBalance <> 0
		AND t.FinalBalance > 0
		AND t.JournalType IS NULL;
---25

END;

---Adjustment
INSERT INTO APTransactionDetails (APTransDetailID,
ApTransactionID,
TransactionType,
TransactionDate,
CreditAccountID,
CreditAmount,
LastUpdated,
CreatedOn,
ThisAccountID,
LastUpdatedBy)
	SELECT
		NEWID(),
		(SELECT
			APTransactionID
		FROM APTransactionTable
		WHERE LastUpdatedBy = 'CJ201901A'),
		CASE
			WHEN @flag = 'CreditSideParent' THEN 20
			ELSE 45
		END,
		'01/31/2019',
		'BQ101',
		(SUM(ISNULL(CreditAmount, 0)) - SUM(ISNULL(DebitAmount, 0))) * -1,
		GETUTCDATE(),
		'01/31/2019',
		'BQ101',
		'CJ201901A'
	FROM APTransactionDetails
	WHERE LastUpdatedBy = 'CJ201901A'
	HAVING (SUM(ISNULL(CreditAmount, 0)) - SUM(ISNULL(DebitAmount, 0))) * -1 <> 0;

UPDATE APTransactionTable
SET TransactionAmount = (SELECT
	SUM(CreditAmount)
FROM APTransactionDetails
WHERE LastUpdatedBy = 'CJ201901A')
WHERE APTransactionID = (SELECT
	APTransactionID
FROM APTransactionTable
WHERE LastUpdatedBy = 'CJ201901A');

UPDATE a
SET a.TransactionType = '45'
FROM APTransactionDetails a
JOIN APTransactionTable aa
	ON a.ApTransactionID = aa.APTransactionID
WHERE aa.ParentAccountID <> a.ThisAccountID
AND a.LastUpdatedBy = 'CJ201901A';

/*Test cases*/
DECLARE @Sql NVARCHAR(MAX),
		@sql1 NVARCHAR(MAX),
		@sql2 NVARCHAR(MAX),
		@sql3 NVARCHAR(MAX)

SET @SQl = (SELECT
	COUNT(*)
FROM APTransactionDetails
WHERE LastUpdatedBy = 'CJ201901A'
AND TransactionType = '20')
IF @sql = 1
	PRINT 'Pass Test Case 1'
IF EXISTS (SELECT
		*
	FROM APTransactionDetails
	WHERE TransactionType = '20'
	GROUP BY ApTransactionID,
			 TransactionType
	HAVING COUNT(*) > 1)
BEGIN
	PRINT 'Failed=Test Case 2'
	SELECT
		ApTransactionID,
		TransactionType
	FROM APTransactionDetails
	WHERE TransactionType = '20'
	GROUP BY ApTransactionID,
			 TransactionType
	HAVING COUNT(*) > 1
--select * from APTransactionDetails where ApTransactionID='DE042728-ACD7-45A9-AA96-479E458ED272'
END
ELSE
BEGIN
	PRINT 'Pass Test Case 2'
END
SET @sql2 = (SELECT
	SUM(DebitAmount) - SUM(CreditAmount)
FROM APTransactionDetails)

IF (@sql2 = 0.00)
BEGIN
	PRINT 'Pass Test Case 3'
END
ELSE
BEGIN
	PRINT 'Failed Test Case 3'
END

IF EXISTS (SELECT
		*
	FROM APTransactionDetails
	GROUP BY ApTransactionID
	HAVING SUM(DebitAmount) <> SUM(CreditAmount))
BEGIN
	PRINT 'Failed=Test Case 4'
	SELECT
		SUM(DebitAmount),
		SUM(CreditAmount),
		ApTransactionID
	FROM APTransactionDetails
	GROUP BY ApTransactionID
	HAVING SUM(DebitAmount) <> SUM(CreditAmount)
END
ELSE
BEGIN
	PRINT 'Pass Test Case 4'
END

IF EXISTS (SELECT
		*
	FROM APTransactionTable a
	INNER JOIN (SELECT
		SUM(DebitAmount) AS amt,
		ApTransactionID AS id
	FROM APTransactionDetails
	GROUP BY ApTransactionID) aa
		ON a.APTransactionID = aa.id
	WHERE a.TransactionAmount <> aa.amt
	AND a.TransactionType <> '4')
BEGIN
	PRINT 'Failed=Test Case 5'
	SELECT
		*
	FROM APTransactionTable a
	INNER JOIN (SELECT
		SUM(CreditAmount) AS amt,
		ApTransactionID AS id
	FROM APTransactionDetails
	GROUP BY ApTransactionID) aa
		ON a.APTransactionID = aa.id
	WHERE a.TransactionAmount <> aa.amt
	AND a.TransactionType <> '4';
END
ELSE
BEGIN
	PRINT 'Pass Test Case 5'
END

IF EXISTS (SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID IS NULL)
BEGIN
	PRINT 'Failed=Test Case 6'
	SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID IS NULL
END
ELSE
BEGIN
	PRINT 'Pass Test Case 6'
END


IF EXISTS (SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID <> CreditAccountID
	AND CreditAccountID IS NOT NULL)
BEGIN
	PRINT 'Failed=Test Case 7'
	SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID <> CreditAccountID
	AND CreditAccountID IS NOT NULL
END
ELSE
BEGIN
	PRINT 'Pass Test Case 7'
END


IF EXISTS (SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID <> DebitAccountID
	AND DebitAccountID IS NOT NULL)
BEGIN
	PRINT 'Failed=Test Case 8'
	SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID <> DebitAccountID
	AND DebitAccountID IS NOT NULL
END
ELSE
BEGIN
	PRINT 'Pass Test Case 8'
END

IF EXISTS (SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID NOT IN (SELECT
		AccountID
	FROM AccountList))
BEGIN
	PRINT 'Failed=Test Case 9'
	SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID NOT IN (SELECT
		AccountID
	FROM AccountList)
END
ELSE
BEGIN
	PRINT 'Pass Test Case 9'
END

IF EXISTS (SELECT
		*
	FROM APTransactionTable
	WHERE ParentAccountID IS NULL)
BEGIN
	PRINT 'Failed=Test Case 10'
	SELECT
		*
	FROM APTransactionTable
	WHERE ParentAccountID IS NULL
END
ELSE
BEGIN
	PRINT 'Pass Test Case 10'
END


IF EXISTS (SELECT
		*
	FROM APTransactionTable
	WHERE ParentAccountID NOT IN (SELECT
		AccountID
	FROM AccountList))
BEGIN
	PRINT 'Failed=Test Case 11'
	SELECT
		*
	FROM APTransactionTable
	WHERE ParentAccountID NOT IN (SELECT
		AccountID
	FROM AccountList)
END
ELSE
BEGIN
	PRINT 'Pass Test Case 11'
END

/*End Test Cases*/
------AS of 201901 cash--

Branch_Cash:
DELETE FROM APTransactionDetails
WHERE LastUpdatedBy = 'CJ201901C'
GO
DELETE FROM APTransactiontable
WHERE LastUpdatedBy = 'CJ201901C'
GO
DECLARE @flag1 NVARCHAR(MAX);
IF EXISTS (SELECT
		COUNT(*)
	FROM ISTrialBalances.dbo.QBTB201901C qa
	WHERE qa.FinalBalance IS NOT NULL
	AND FinalBalance <> 0
	AND JournalType IS NULL
	AND qa.FinalBalance > 0
	HAVING SUM(qa.FinalBalance * -1) IS NOT NULL)
BEGIN
	INSERT INTO APTransactionTable (APTransactionID, TransactionType, TransactionDate, CreatedOn, LastUpdated, TransactionAmount, parentaccountid, lastupdatedby)
		SELECT
			NEWID(),
			46,
			'01/31/2019',
			'01/31/2019',
			GETUTCDATE(),
			SUM(qa.FinalBalance),
			MAX(LTRIM(RTRIM(Accountid))),
			'CJ201901C'
		FROM ISTrialBalances.dbo.QBTB201901C qa
		WHERE qa.FinalBalance IS NOT NULL
		AND FinalBalance <> 0
		AND JournalType IS NULL
		AND qa.FinalBalance > 0
		HAVING SUM(qa.FinalBalance * -1) IS NOT NULL

	SET @flag1 = 'DebitSideParent';
END;
ELSE
BEGIN
	IF EXISTS (SELECT
			COUNT(*)
		FROM ISTrialBalances.dbo.QBTB201901C qa
		WHERE qa.FinalBalance IS NOT NULL
		AND FinalBalance <> 0
		AND JournalType IS NULL
		AND qa.FinalBalance < 0
		HAVING SUM(qa.FinalBalance * -1) IS NOT NULL)
	BEGIN
		INSERT INTO APTransactionTable (APTransactionID, TransactionType, TransactionDate, CreatedOn, LastUpdated, TransactionAmount, parentaccountid, lastupdatedby)
			SELECT
				NEWID(),
				46,
				'01/31/2019',
				'01/31/2019',
				GETUTCDATE(),
				SUM(qa.FinalBalance) * -1,
				MAX(LTRIM(RTRIM(Accountid))),
				'CJ201901C'
			FROM ISTrialBalances.dbo.QBTB201901C qa
			WHERE qa.FinalBalance IS NOT NULL
			AND FinalBalance <> 0
			AND JournalType IS NULL
			AND qa.FinalBalance < 0
			HAVING SUM(qa.FinalBalance * -1) IS NOT NULL;
		SET @flag1 = 'CreditSideParent';
	END
	ELSE
	BEGIN
		GOTO LEnd
	END

END;
---Credit side------
IF EXISTS (SELECT
		*
	FROM ISTrialBalances.dbo.QBTB201901C t
	WHERE t.FinalBalance IS NOT NULL
	AND t.FinalBalance <> 0
	AND t.FinalBalance < 0
	AND t.JournalType IS NULL)
BEGIN
	---credit Side
	INSERT INTO APTransactionDetails (APTransDetailID,
	ApTransactionID,
	TransactionType,
	TransactionDate,
	CreditAccountID,
	CreditAmount,
	LastUpdated,
	CreatedOn,
	ThisAccountID,
	LastUpdatedBy)
		SELECT
			NEWID(),
			(SELECT
				APTransactionID
			FROM APTransactionTable
			WHERE LastUpdatedBy = 'CJ201901C'),
			CASE
				WHEN @flag1 = 'CreditSideParent' THEN 20
				ELSE 46
			END,
			'01/31/2019',
			LTRIM(RTRIM(Accountid)),
			(t.FinalBalance * -1),
			GETUTCDATE(),
			'01/31/2019',
			LTRIM(RTRIM(Accountid)),
			'CJ201901C'
		FROM ISTrialBalances.dbo.QBTB201901C t
		WHERE t.FinalBalance IS NOT NULL
		AND t.FinalBalance <> 0
		AND t.FinalBalance < 0
		AND t.JournalType IS NULL;
----4 
END;
ELSE
BEGIN
	---when credit is ZERO
	INSERT INTO dbo.APTransactionDetails (APTransDetailID,
	ApTransactionID,
	TransactionType,
	TransactionDate,
	CreditAccountID,
	CreditAmount,
	LastUpdated,
	CreatedOn,
	ThisAccountID,
	LastUpdatedBy)
		SELECT
			NEWID(),
			(SELECT
				APTransactionID
			FROM APTransactionTable
			WHERE LastUpdatedBy = 'CJ201901C'),
			CASE
				WHEN @flag1 = 'CreditSideParent' THEN 20
				ELSE 46
			END,
			'01/31/2019',
			'BQ101',
			0,
			GETUTCDATE(),
			'01/31/2019',
			'BQ101',
			'CJ201901C';

END;
---Debit----
IF EXISTS (SELECT
		*
	FROM ISTrialBalances.dbo.QBTB201901A t
	WHERE t.FinalBalance IS NOT NULL
	AND t.FinalBalance <> 0
	AND t.FinalBalance > 0
	AND t.JournalType IS NULL)
BEGIN
	----Debit Side
	INSERT INTO dbo.APTransactionDetails (APTransDetailID,
	ApTransactionID,
	TransactionType,
	TransactionDate,
	DebitAccountID,
	DebitAmount,
	LastUpdated,
	CreatedOn,
	ThisAccountID,
	LastUpdatedBy)
		SELECT
			NEWID(),
			(SELECT
				APTransactionID
			FROM APTransactionTable
			WHERE LastUpdatedBy = 'CJ201901C'),
			20,
			'01/31/2019',
			LTRIM(RTRIM(Accountid)),
			(t.FinalBalance),
			GETUTCDATE(),
			'01/31/2019',
			LTRIM(RTRIM(Accountid)),
			'CJ201901C'
		FROM ISTrialBalances.dbo.QBTB201901C t
		WHERE t.FinalBalance IS NOT NULL
		AND t.FinalBalance <> 0
		AND t.FinalBalance > 0
		AND t.JournalType IS NULL;
---23

END;

ELSE
BEGIN
	---where Debit is  Zero
	INSERT INTO dbo.APTransactionDetails (APTransDetailID,
	ApTransactionID,
	TransactionType,
	TransactionDate,
	DebitAccountID,
	DebitAmount,
	LastUpdated,
	CreatedOn,
	ThisAccountID,
	LastUpdatedBy)
		SELECT
			NEWID(),
			(SELECT
				APTransactionID
			FROM APTransactionTable
			WHERE LastUpdatedBy = 'CJ201901C'),
			CASE
				WHEN @flag1 = 'CreditSideParent' THEN 46
				ELSE 20
			END,
			'01/31/2019',
			LTRIM(RTRIM(Accountid)),
			(t.FinalBalance),
			GETUTCDATE(),
			'01/31/2019',
			LTRIM(RTRIM(Accountid)),
			'CJ201901C'
		FROM ISTrialBalances.dbo.QBTB201901C t
		WHERE t.FinalBalance IS NOT NULL
		AND t.FinalBalance <> 0
		AND t.FinalBalance > 0
		AND t.JournalType IS NULL;
---25

END;
---Adjustment
INSERT INTO APTransactionDetails (APTransDetailID,
ApTransactionID,
TransactionType,
TransactionDate,
CreditAccountID,
CreditAmount,
LastUpdated,
CreatedOn,
ThisAccountID,
LastUpdatedBy)
	SELECT
		NEWID(),
		(SELECT
			APTransactionID
		FROM APTransactionTable
		WHERE LastUpdatedBy = 'CJ201901C'),
		CASE
			WHEN @flag1 = 'CreditSideParent' THEN 20
			ELSE 46
		END,
		'01/31/2019',
		'BQ101',
		(SUM(ISNULL(CreditAmount, 0)) - SUM(ISNULL(DebitAmount, 0))) * -1,
		GETUTCDATE(),
		'01/31/2019',
		'BQ101',
		'CJ201901C'
	FROM APTransactionDetails
	WHERE LastUpdatedBy = 'CJ201901C'
	HAVING (SUM(ISNULL(CreditAmount, 0)) - SUM(ISNULL(DebitAmount, 0))) * -1 <> 0;

UPDATE APTransactionTable
SET TransactionAmount = (SELECT
	SUM(CreditAmount)
FROM APTransactionDetails
WHERE LastUpdatedBy = 'CJ201901C')
WHERE APTransactionID = (SELECT
	APTransactionID
FROM APTransactionTable
WHERE LastUpdatedBy = 'CJ201901C');


UPDATE a
SET a.TransactionType = '46'
FROM APTransactionDetails a
JOIN APTransactionTable aa
	ON a.ApTransactionID = aa.APTransactionID
WHERE aa.ParentAccountID <> a.ThisAccountID
AND a.LastUpdatedBy = 'CJ201901C';

/*Test cases*/
DECLARE @Sql NVARCHAR(MAX),
		@sql1 NVARCHAR(MAX),
		@sql2 NVARCHAR(MAX),
		@sql3 NVARCHAR(MAX)

SET @SQl = (SELECT
	COUNT(*)
FROM APTransactionDetails
WHERE LastUpdatedBy = 'CJ201901C'
AND TransactionType = '20')
IF @sql = 1
	PRINT 'Pass Test Case 1'
IF EXISTS (SELECT
		*
	FROM APTransactionDetails
	WHERE TransactionType = '20'
	GROUP BY ApTransactionID,
			 TransactionType
	HAVING COUNT(*) > 1)
BEGIN
	PRINT 'Failed=Test Case 2'
	SELECT
		ApTransactionID,
		TransactionType
	FROM APTransactionDetails
	WHERE TransactionType = '20'
	GROUP BY ApTransactionID,
			 TransactionType
	HAVING COUNT(*) > 1

END
ELSE
BEGIN
	PRINT 'Pass Test Case 2'
END
SET @sql2 = (SELECT
	SUM(ISNULL(DebitAmount, 0)) - SUM(ISNULL(CreditAmount, 0))
FROM APTransactionDetails)

IF (@sql2 = 0.00)
BEGIN
	PRINT 'Pass Test Case 3'
END
ELSE
BEGIN
	PRINT 'Failed Test Case 3'
END

IF EXISTS (SELECT
		*
	FROM APTransactionDetails
	GROUP BY ApTransactionID
	HAVING SUM(DebitAmount) <> SUM(CreditAmount))
BEGIN
	PRINT 'Failed=Test Case 4'
	SELECT
		SUM(DebitAmount),
		SUM(CreditAmount),
		ApTransactionID
	FROM APTransactionDetails
	GROUP BY ApTransactionID
	HAVING SUM(DebitAmount) <> SUM(CreditAmount)
END
ELSE
BEGIN
	PRINT 'Pass Test Case 4'
END

IF EXISTS (SELECT
		*
	FROM APTransactionTable a
	INNER JOIN (SELECT
		SUM(DebitAmount) AS amt,
		ApTransactionID AS id
	FROM APTransactionDetails
	GROUP BY ApTransactionID) aa
		ON a.APTransactionID = aa.id
	WHERE a.TransactionAmount <> aa.amt
	AND a.TransactionType <> '4')
BEGIN
	PRINT 'Failed=Test Case 5'
	SELECT
		*
	FROM APTransactionTable a
	INNER JOIN (SELECT
		SUM(CreditAmount) AS amt,
		ApTransactionID AS id
	FROM APTransactionDetails
	GROUP BY ApTransactionID) aa
		ON a.APTransactionID = aa.id
	WHERE a.TransactionAmount <> aa.amt
	AND a.TransactionType <> '4';
END
ELSE
BEGIN
	PRINT 'Pass Test Case 5'
END

IF EXISTS (SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID IS NULL)
BEGIN
	PRINT 'Failed=Test Case 6'
	SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID IS NULL
END
ELSE
BEGIN
	PRINT 'Pass Test Case 6'
END


IF EXISTS (SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID <> CreditAccountID
	AND CreditAccountID IS NOT NULL)
BEGIN
	PRINT 'Failed=Test Case 7'
	SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID <> CreditAccountID
	AND CreditAccountID IS NOT NULL
END
ELSE
BEGIN
	PRINT 'Pass Test Case 7'
END


IF EXISTS (SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID <> DebitAccountID
	AND DebitAccountID IS NOT NULL)
BEGIN
	PRINT 'Failed=Test Case 8'
	SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID <> DebitAccountID
	AND DebitAccountID IS NOT NULL
END
ELSE
BEGIN
	PRINT 'Pass Test Case 8'
END

IF EXISTS (SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID NOT IN (SELECT
		AccountID
	FROM AccountList))
BEGIN
	PRINT 'Failed=Test Case 9'
	SELECT
		*
	FROM APTransactionDetails
	WHERE ThisAccountID NOT IN (SELECT
		AccountID
	FROM AccountList)
END
ELSE
BEGIN
	PRINT 'Pass Test Case 9'
END

IF EXISTS (SELECT
		*
	FROM APTransactionTable
	WHERE ParentAccountID IS NULL)
BEGIN
	PRINT 'Failed=Test Case 10'
	SELECT
		*
	FROM APTransactionTable
	WHERE ParentAccountID IS NULL
END
ELSE
BEGIN
	PRINT 'Pass Test Case 10'
END


IF EXISTS (SELECT
		*
	FROM APTransactionTable
	WHERE ParentAccountID NOT IN (SELECT
		AccountID
	FROM AccountList))
BEGIN
	PRINT 'Failed=Test Case 11'
	SELECT
		*
	FROM APTransactionTable
	WHERE ParentAccountID NOT IN (SELECT
		AccountID
	FROM AccountList)
END
ELSE
BEGIN
	PRINT 'Pass Test Case 11'
END

/*End Test Cases*/

LEnd:
PRINT 'done'

SET ANSI_WARNINGS ON
GO
-------------------VAL----------------------------
DECLARE @query AS NVARCHAR(MAX)
DECLARE @CurrentYearStartDate AS VARCHAR(10)
DECLARE @AsOfDate AS VARCHAR(10)
DECLARE @TableNamePrefix AS VARCHAR(10)
DECLARE @TableName AS VARCHAR(20)
DECLARE @TableNameAccrual AS VARCHAR(20)
DECLARE @TableNameCash AS VARCHAR(20)
DECLARE @JEType AS VARCHAR(20)
DECLARE @DBName AS VARCHAR(100) -- TB Data Table Data File


SET @DBName = 'VAL'

SET @AsOfDate = '01/31/2019'
--201901---


SET @CurrentYearStartDate = '01/01/' + CAST(YEAR(@AsOfDate) AS NVARCHAR(MAX))


--change if required
SET @JEType = 'Monthly'
SET @TableNamePrefix = 'BQTB'


--do not make any changes from here
IF @JEType = 'Monthly'
	SET @TableName = @TableNamePrefix + CAST(YEAR(@AsOfDate) AS NVARCHAR(4)) + STUFF(CAST(MONTH(@AsOfDate) AS NVARCHAR(2)), 1, 0, REPLICATE('0', 2 - LEN(CAST(MONTH(@AsOfDate) AS NVARCHAR(2)))))
ELSE --yearly
	SET @TableName = @TableNamePrefix + CAST(YEAR(@AsOfDate) AS NVARCHAR(4))
SET @TableNameAccrual = @TableName + 'A'
SET @TableNameCash = @TableName + 'C'



SET @query = '
IF OBJECT_ID (''' + @DBName + '.dbo.' + @TableNameAccrual + ''',''U'') IS NOT NULL
   DROP TABLE ' + @DBName + '.dbo.' + @TableNameAccrual

EXEC (@query)

SET @query = '
IF OBJECT_ID (''' + @DBName + '.dbo.' + @TableNameCash + ''',''U'') IS NOT NULL
   DROP TABLE ' + @DBName + '.dbo.' + @TableNameCash

EXEC (@query)


--YTD TB Accrual
SET @query = '
 SELECT AccountList_DF.AccountID,  --Account ID
		SUM(ISNULL(TransactionSummary.DebitAmount,0)) AS DebitAmount, SUM(ISNULL(TransactionSummary.CreditAmount,0)) AS CreditAmount,
		SUM(ISNULL(TransactionSummary.DebitAmount,0)) - SUM(ISNULL(TransactionSummary.CreditAmount,0)) AS Balance -- Balance
 INTO ' + @DBName + '.dbo.' + @TableNameAccrual + '
 FROM   (dbo.AccountList AccountList_DF INNER JOIN dbo.TransactionSummary TransactionSummary ON AccountList_DF.AccountID=TransactionSummary.ThisAccountID) INNER JOIN 
 dbo.AccountTypeList AccountTypeList_DF ON AccountList_DF.AccountTypeID=AccountTypeList_DF.AccountTypeID 
 WHERE  (TransactionSummary.TransactionDate>=''01/01/1970''
 AND TransactionSummary.TransactionDate<=''' + @AsOfDate + ''') 
 AND TransactionSummary.MasterTransactionType<>46
 AND AccountTypeList_DF.AccountTypeID NOT IN (8,6,15,14,3)
 GROUP BY AccountList_DF.AccountID

 UNION ALL

 SELECT AccountList_DF.AccountID,  --Account ID
		SUM(ISNULL(TransactionSummary.DebitAmount,0)) AS DebitAmount, SUM(ISNULL(TransactionSummary.CreditAmount,0)) AS CreditAmount,
		SUM(ISNULL(TransactionSummary.DebitAmount,0)) - SUM(ISNULL(TransactionSummary.CreditAmount,0)) AS Balance -- Balance
 FROM   (dbo.AccountList AccountList_DF INNER JOIN dbo.TransactionSummary TransactionSummary ON AccountList_DF.AccountID=TransactionSummary.ThisAccountID) INNER JOIN 
 dbo.AccountTypeList AccountTypeList_DF ON AccountList_DF.AccountTypeID=AccountTypeList_DF.AccountTypeID 
 WHERE  (TransactionSummary.TransactionDate>=''' + @CurrentYearStartDate + '''
 AND TransactionSummary.TransactionDate<=''' + @AsOfDate + ''') 
 AND TransactionSummary.MasterTransactionType<>46
 AND AccountTypeList_DF.AccountTypeID IN (8,6,15,14,3)
 GROUP BY AccountList_DF.AccountID
 '
EXEC (@query)

SET @query = '
 IF NOT Exists(SELECT * FROM ' + @DBName + '.dbo.' + @TableNameAccrual + ' a WHERE AccountID=''3900'' )
 BEGIN
 Insert into ' + @DBName + '.dbo.' + @TableNameAccrual + ' 
 SELECT ''3900'',0,0,0
 END
 '
EXEC (@query)


SET @query = '
 UPDATE a SET Balance=a.Balance-(SELECT SUM(Balance) FROM ' + @DBName + '.dbo.' + @TableNameAccrual + ')  FROM ' + @DBName + '.dbo.' + @TableNameAccrual + ' a WHERE AccountID=''3900''
 '
EXEC (@query)

SET @query = '
 SELECT SUM(Balance) FROM ' + @DBName + '.dbo.' + @TableNameAccrual

EXEC (@query)
--------------




--YTD TB Cash

SET @query = '
SELECT AccountList_DF.AccountID,  --Account ID
  --SUM(ISNULL(TransactionDetailCash.DebitAmount,0)) AS DebitAmount, 
  --SUM(ISNULL(TransactionDetailCash.CreditAmount,0)) AS CreditAmount,
  SUM(ISNULL(TransactionDetailCash.DebitAmount,0)) - SUM(ISNULL(TransactionDetailCash.CreditAmount,0)) AS Balance
INTO ' + @DBName + '.dbo.' + @TableNameCash + '
FROM   (dbo.TransactionDetailCash TransactionDetailCash INNER JOIN dbo.AccountList AccountList_DF ON TransactionDetailCash.AccountID=AccountList_DF.AccountID) INNER JOIN 
dbo.AccountTypeList AccountTypeList_DF ON AccountList_DF.AccountTypeID=AccountTypeList_DF.AccountTypeID 
WHERE  (TransactionDetailCash.Date>=''01/01/1970'' AND TransactionDetailCash.Date<=''' + @AsOfDate + ''')
 AND AccountTypeList_DF.AccountTypeID NOT IN (8,6,15,14,3)
GROUP BY AccountList_DF.AccountID

UNION ALL

SELECT AccountList_DF.AccountID,  --Account ID
  --SUM(ISNULL(TransactionDetailCash.DebitAmount,0)) AS DebitAmount, 
  --SUM(ISNULL(TransactionDetailCash.CreditAmount,0)) AS CreditAmount,
  SUM(ISNULL(TransactionDetailCash.DebitAmount,0)) - SUM(ISNULL(TransactionDetailCash.CreditAmount,0)) AS Balance
FROM   (dbo.TransactionDetailCash TransactionDetailCash INNER JOIN dbo.AccountList AccountList_DF ON TransactionDetailCash.AccountID=AccountList_DF.AccountID) INNER JOIN 
dbo.AccountTypeList AccountTypeList_DF ON AccountList_DF.AccountTypeID=AccountTypeList_DF.AccountTypeID 
WHERE  (TransactionDetailCash.Date>=''' + @CurrentYearStartDate + ''' AND TransactionDetailCash.Date<=''' + @AsOfDate + ''')
 AND AccountTypeList_DF.AccountTypeID IN (8,6,15,14,3)
GROUP BY AccountList_DF.AccountID
'

EXEC (@query)

SET @query = '
 IF NOT Exists(SELECT * FROM ' + @DBName + '.dbo.' + @TableNameCash + ' a WHERE AccountID=''3900'' )
 BEGIN
 Insert into ' + @DBName + '.dbo.' + @TableNameCash + ' 
 SELECT ''3900'',0
 END
'
EXEC (@query)

SET @query = '
UPDATE a SET Balance=a.Balance-(SELECT SUM(Balance) FROM ' + @DBName + '.dbo.' + @TableNameCash + ')  FROM ' + @DBName + '.dbo.' + @TableNameCash + ' a WHERE AccountID=''3900''
'
EXEC (@query)

SET @query = '
 SELECT SUM(Balance) FROM ' + @DBName + '.dbo.' + @TableNameCash

EXEC (@query)
------------------------Checker-------------------------
SELECT
	*
FROM ISTrialBalances.dbo.QBTB201901A a
JOIN VAL.dbo.BQTB201901A aa
	ON a.AccountID = aa.AccountID
WHERE CAST(a.Balance AS MONEY) <> CAST(aa.Balance AS MONEY)
AND a.accountid IS NOT NULL

SELECT
	*
FROM ISTrialBalances.dbo.QBTB201901A
WHERE LTRIM(RTRIM(AccountID)) NOT IN (SELECT
	LTRIM(RTRIM(AccountID))
FROM VAL.dbo.BQTB201901A
WHERE AccountID IS NOT NULL)
AND AccountID IS NOT NULL
AND Balance <> 0

SELECT
	AccountID,
	*
FROM VAL.dbo.BQTB201901A
WHERE AccountID IS NOT NULL
AND AccountID NOT IN (SELECT
	AccountID
FROM ISTrialBalances.dbo.QBTB201901A
WHERE AccountID IS NOT NULL)
AND Balance <> 0

SELECT
	AccountID,
	*
FROM VAL.dbo.BQTB201901A
WHERE AccountID IS NOT NULL
AND AccountID
NOT IN (SELECT
	AccountID
FROM ISTrialBalances.dbo.QBTB201901A
WHERE AccountID IS NOT NULL)
AND Balance <> 0

---CASH

SELECT
	*
FROM ISTrialBalances.dbo.QBTB201901C a
JOIN VAL.dbo.BQTB201901C aa
	ON a.AccountID = aa.AccountID
WHERE CAST(a.Balance AS MONEY) <> CAST(aa.Balance AS MONEY)
AND a.accountid IS NOT NULL

SELECT
	*
FROM ISTrialBalances.dbo.QBTB201901C
WHERE LTRIM(RTRIM(AccountID)) NOT IN (SELECT
	LTRIM(RTRIM(AccountID))
FROM VAL.dbo.BQTB201901C
WHERE AccountID IS NOT NULL)
AND AccountID IS NOT NULL
AND Balance <> 0

SELECT
	AccountID,
	*
FROM VAL.dbo.BQTB201901C
WHERE AccountID IS NOT NULL
AND AccountID NOT IN (SELECT
	AccountID
FROM ISTrialBalances.dbo.QBTB201901C
WHERE AccountID IS NOT NULL)
AND Balance <> 0

SELECT
	SUM(DebitAmount) - SUM(CreditAmount),
	ApTransactionID
FROM dbo.APTransactionDetails
GROUP BY ApTransactionID
HAVING SUM(DebitAmount) - SUM(CreditAmount) <> 0
