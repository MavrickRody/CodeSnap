--Stored Procedure for Account Payable Aging Report for Crystal Reports and Power Bi Segments---
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE BQEAPAgingCredits @AgingAsOfDate AS DATETIME = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SELECT
		VendorBillID,
		APAccount,
		al.AccountName,
		PayeeID,
		e.EmpFName,
		e.EmpMI,
		e.EmpLName,
		e.EmpCompany,
		e.IsSub,
		BillDate,
		BillDueDate,
		BillNumber,
		Billed,
		Paid,
		CreditUsed,
		totalPaid,
		Balance,
		CASE
			WHEN (DATEDIFF(d, BillDate, GETDATE()) < 0 OR
				DATEDIFF(d, BillDate, GETDATE()) <= 30) AND
				BillNumber <> 'Vendor Credit' AND
				BillNumber <> 'GeneralJournalBalance' THEN Balance
			ELSE 0
		END [current],
		CASE
			WHEN DATEDIFF(d, BillDate, GETDATE()) BETWEEN 31 AND 60 AND
				BillNumber <> 'Vendor Credit' AND
				BillNumber <> 'GeneralJournalBalance' THEN Balance
			ELSE 0
		END [31-60],
		CASE
			WHEN DATEDIFF(d, BillDate, GETDATE()) BETWEEN 61 AND 90 AND
				BillNumber <> 'Vendor Credit' AND
				BillNumber <> 'GeneralJournalBalance' THEN Balance
			ELSE 0
		END [61-90],
		CASE
			WHEN DATEDIFF(d, BillDate, GETDATE()) > 90 AND
				BillNumber <> 'Vendor Credit' AND
				BillNumber <> 'GeneralJournalBalance' THEN Balance
			ELSE 0
		END [>90]
	FROM (SELECT
		BillBalance.VendorBillID,
		BillBalance.APAccount,
		BillBalance.PayeeID,
		BillBalance.BillDate,
		BillBalance.BillDueDate,
		BillBalance.BillNumber,
		BillBalance.Billed,
		BillBalance.Paid AS Paid,
		COALESCE(creditBalance.creditused, 0.00) AS CreditUsed,
		BillBalance.Paid + COALESCE(creditBalance.creditused, 0.00) totalPaid,
		BillBalance.Billed - BillBalance.Paid - COALESCE(creditBalance.creditused, 0.00) AS Balance
	FROM (SELECT
		VendorBillID,
		MAX(APAccount) AS APAccount,
		MAX(PayeeID) AS PayeeID,
		MAX(BillDate) AS BillDate,
		MAX(BillDueDate) AS BillDueDate,
		MAX(b.BillNumber) AS BillNumber,
		SUM(COALESCE(Billed, 0)) AS Billed,
		SUM(Paid) AS paid
	FROM (SELECT
		v.VendorBillID,
		CASE
			WHEN APAccountID IS NULL THEN (SELECT
					CreditAccountID
				FROM APTransactionDetails
				WHERE TransactionType = 20
				AND VendorBillID = v.VendorBillID)
			ELSE v.APAccountID
		END AS APAccount,
		v.VendorID AS PayeeID,
		BillDate,
		BillDueDate,
		BillNumber,
		SUM(te.CreditAmount) AS Billed,
		0.00 AS paid
	FROM VendorBill v
	INNER JOIN (SELECT
		*
	FROM APTransactionDetails
	WHERE TransactionType = 20) te
		ON v.VendorBillID = te.VendorBillID
	WHERE v.BillDate <= COALESCE(@AgingAsOfDate, GETDATE())
	GROUP BY v.VendorBillID,
			 APAccountID,
			 v.VendorID,
			 BillDate,
			 BillDueDate,
			 BillNumber

	UNION ALL

	SELECT
		pay.VendorBillID,
		NULL AS APAccount,
		MAX(pay.PayeeID) AS PayeeID,
		NULL,
		NULL,
		NULL,
		0.00 AS Billed,
		SUM(pay.Paid) AS paid

	FROM (SELECT
		vb.VendorBillID,
		vb.VendorID AS PayeeID,
		vb.BillNumber,
		0.00 AS Billed,
		CASE
			WHEN (aptd.TransactionType = -4 AND
				COALESCE(aptd.DebitAmount, 0) <> 0) THEN COALESCE(aptd.DebitAmount, 0)
			WHEN (aptd.TransactionType = 4 AND
				COALESCE(aptd.DebitAmount, 0) <> 0) THEN COALESCE(aptd.DebitAmount, 0)
			ELSE 0
		END AS Paid
	FROM employee e

	INNER JOIN VendorBill vb
		ON e.EmployeeID = vb.VendorID
	INNER JOIN APTransactionDetails aptd
		ON aptd.VendorBillID = vb.VendorBillID
	INNER JOIN dbo.APTransactionTable ap
		ON aptd.ApTransactionID = ap.APTransactionID
	LEFT JOIN (SELECT
		*
	FROM CheckDetails
	WHERE CheckDate <= COALESCE(@AgingAsOfDate, GETDATE())) cd
		ON aptd.ApTransactionID = cd.APTransactionID

	WHERE (aptd.TransactionType = -4
	OR aptd.TransactionType = 4)
	AND Aptd.TransactionDate <= COALESCE(@AgingAsOfDate, GETDATE())) pay
	GROUP BY pay.VendorBillID
	UNION ALL---Discounts
	SELECT
		dis.VendorBillID,
		NULL AS APAccount,
		MAX(dis.PayeeID) AS PayeeID,
		NULL,
		NULL,
		NULL,
		0.00 AS Billed,
		SUM(dis.Paid) AS paid

	FROM (SELECT
		vb.VendorBillID,
		vb.VendorID AS PayeeID,
		vb.BillNumber,
		0.00 AS Billed,
		DebitAmount Paid
	FROM employee e

	INNER JOIN VendorBill vb
		ON e.EmployeeID = vb.VendorID
	INNER JOIN APTransactionDetails aptd
		ON aptd.VendorBillID = vb.VendorBillID
	INNER JOIN dbo.APTransactionTable ap
		ON aptd.ApTransactionID = ap.APTransactionID
	LEFT JOIN (SELECT
		*
	FROM CheckDetails
	WHERE CheckDate <= COALESCE(@AgingAsOfDate, GETDATE())) cd
		ON aptd.ApTransactionID = cd.APTransactionID
	WHERE (aptd.TransactionType = 11)
	AND aptd.DebitAccountID IS NOT NULL
	AND Aptd.TransactionDate <= COALESCE(@AgingAsOfDate, GETDATE())
	----discounts

	) dis
	GROUP BY dis.VendorBillID) b
	GROUP BY VendorBillID) BillBalance

	LEFT JOIN (

	---Credit Usage

	SELECT
		b.VendorBillID,
		b.PayeeID,
		MAX(b.TransactionDate) AS TransactionDate,
		MAX(b.Ref) AS Ref,
		SUM(b.VendorCreditAmount) AS VendorCreditAmount,
		SUM(b.creditused) AS creditused,
		'CreditBalance' AS TYPE,
		SUM(b.creditBalance) AS CreditBalance
	FROM (SELECT
		cu.VendorBillID,
		header.PayeeID,
		child.TransactionDate,
		child.Ref,
		header.TransactionAmount AS VendorCreditAmount,
		cu.Amount AS creditused,
		'CreditBalance' AS Type,
		header.TransactionAmount - COALESCE(cu.Amount, 0.00) AS creditBalance
	FROM (SELECT
		*
	FROM APTransactionTable
	WHERE TransactionType = 7) header
	INNER JOIN (SELECT
		*
	FROM APTransactionDetails
	WHERE TransactionType = 20
	AND TransactionDate <= COALESCE(@AgingAsOfDate, GETDATE())) child
		ON header.ApTransactionID = child.APTransactionID

	LEFT JOIN (SELECT
		*
	FROM APCreditUsed
	WHERE TransactionDate <= COALESCE(@AgingAsOfDate, GETDATE())) cu
		ON cu.BillCreditTransactionID = header.APTransactionID) b
	GROUP BY b.VendorBillID,
			 b.PayeeID) creditBalance
		ON creditBalance.PayeeID = BillBalance.PayeeID
		AND creditBalance.VendorBillID = BillBalance.VendorBillID

	UNION ALL
	--credit balance

	SELECT
		NULL VendorBillID,
		MAX(ParentAccountID) AS APAccount,
		MAX(b.PayeeID),
		MAX(b.TransactionDate),
		NULL,
		'Vendor Credit',
		0.00 AS creditreceived,
		0.00,
		0.00,
		0.00,
		(COALESCE(SUM(COALESCE(b.TotalCredit, 0.00)), 0.00) - COALESCE(SUM(b.CreditUsed), 0.00)) * -1
	FROM (SELECT
		NULL VendorBillID,
		header.ParentAccountID,
		header.PayeeID,
		header.TransactionDate,
		header.TransactionAmount AS TotalCredit,
		0.00 AS CreditUsed
	FROM (SELECT
		*
	FROM APTransactionTable
	WHERE TransactionType = 7) header
	WHERE header.TransactionDate <= COALESCE(@AgingAsOfDate, GETDATE())

	UNION ALL

	SELECT
		NULL VendorBillID,
		header.ParentAccountID AS ParentAccountID,
		header.PayeeID,
		NULL TransactionDate,
		0.00 AS TransactionAmount,
		COALESCE(SUM(cu.Amount), 0.00) AS Creditused
	FROM (SELECT
		*
	FROM APTransactionTable
	WHERE TransactionType = 7) header
	INNER JOIN (SELECT
		*
	FROM APTransactionDetails
	WHERE TransactionType = 20) child
		ON header.ApTransactionID = child.APTransactionID

	INNER JOIN (SELECT
		*
	FROM APCreditUsed
	WHERE TransactionDate <= COALESCE(@AgingAsOfDate, GETDATE())) cu
		ON cu.BillCreditTransactionID = header.APTransactionID
	GROUP BY header.PayeeID,
			 header.ParentAccountID) b
	GROUP BY b.PayeeID,
			 b.ParentAccountID
	--Journal entries
	UNION ALL

	SELECT
		NULL VendorBillID,
		aptd.ThisAccountID AS ApAccount,
		COALESCE(aptd.AccountLineID, 'ZZZZ') PayeeID,
		NULL,
		NULL,
		'GeneralJournalBalance',
		0.00,
		0.00,
		0.00,
		0.00,
		SUM(COALESCE(aptd.CreditAmount, 0.00)) - SUM(COALESCE(aptd.DebitAmount, 0.00)) AS APBalance
	FROM dbo.APTransactionTable ap
	INNER JOIN (SELECT
		*
	FROM dbo.APTransactionDetails
	WHERE ThisAccountID IN (SELECT
		AccountID
	FROM dbo.AccountList
	WHERE AccountTypeID = 0)) aptd
		ON ap.APTransactionID = aptd.ApTransactionID
	WHERE ap.TransactionType IN (5, 0, 45)
	AND ap.TransactionDate <= COALESCE(@AgingAsOfDate, GETDATE())
	GROUP BY aptd.ThisAccountID,
			 COALESCE(aptd.AccountLineID, 'ZZZZ')) ApAging
	LEFT JOIN Employee e
		ON APAging.PayeeID = e.EmployeeID
	LEFT JOIN AccountList al
		ON al.AccountID = ApAging.APAccount
	WHERE (Balance <> 0)
	ORDER BY PayeeID, VendorBillID, BillDate
END
	GO
