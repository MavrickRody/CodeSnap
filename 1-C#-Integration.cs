/*--This code was used to integrate with QuickBooks Accounting--*/
public static class QB
    {
        public static void SyncEmployees()
        {
            using (var connection = new QBConnection())
            {
                connection.Open();
                var employeeQueryRq = connection.Request.AppendEmployeeQueryRq();
                employeeQueryRq.ORListQuery.ListFilter.ActiveStatus.SetValue(ENActiveStatus.asAll);
                
                //Send the request and get the response from QuickBooks
                connection.GetResponse();

                var employeeList = (IEmployeeRetList)connection.Response.Detail;

                if (employeeList != null)
                {
                    for (var i = 0; i < employeeList.Count; i++)
                    {
                        IEmployeeRet employee = (IEmployeeRet) employeeList.GetAt(i);
                        Employee e = new Employee
                        {
                            EmployeeID = BQ.CleanId(employee.Name?.GetValue()),
                            EmpFName = employee.FirstName?.GetValue(),
                            EmpLName = employee.LastName?.GetValue(),
                            EmpCostRate = 1,
                            EmpBillRate = 1,
                            QBLinkID = employee.ListID?.GetValue(),
                            EmpEmail = employee.Email?.GetValue(),
                            EmpHFax =  BQ.CleanPhone(employee.Fax?.GetValue()),
                            EmpDateHired = employee.HiredDate?.GetValue(),
                            Status = employee.IsActive?.GetValue() == true ? "Active" : "Inactive",
                            MobileNumber = BQ.CleanPhone(employee.Mobile?.GetValue()),
                            EmpTitle = employee.JobTitle?.GetValue(),
                            EmpSalt = employee.Salutation?.GetValue(),
                            EmpMemo = employee.Notes?.GetValue(),
                            EmpMI = employee.MiddleName?.GetValue().Substring(0,1),
                            EmpContactPhone = BQ.CleanPhone(employee.AltPhone?.GetValue()),
                            EmpSSN = employee.SSN?.GetValue(),
                            EmpStreet =  (employee.EmployeeAddress?.Addr1?.GetValue() ?? "" + " " + employee.EmployeeAddress?.Addr2?.GetValue() ?? "").Trim(),
                            EmpStreet2 = (employee.EmployeeAddress?.Addr3?.GetValue() ?? "" + " " + employee.EmployeeAddress?.Addr4?.GetValue() ?? "").Trim(),
                            EmpCity = employee.EmployeeAddress?.City?.GetValue(),
                            EmpCountry = employee.EmployeeAddress?.Country?.GetValue(),
                            EmpState = employee.EmployeeAddress?.State?.GetValue(),
                            EmpZip = employee.EmployeeAddress?.PostalCode?.GetValue(),
                            EmpHPhone = BQ.CleanPhone(employee.Phone?.GetValue()),
                            IsSub = 0,
                            EmpDateReleased = employee.ReleasedDate?.GetValue(),
                            EmpOther1 = BQ.CleanId(employee.Name?.GetValue()),
                            EmpOther2 = employee.EmployeeType?.GetAsString(),
                            EmpOther3 = employee.Gender?.GetAsString(),
                            EmpOther4 = employee?.BirthDate?.GetValue().ToString("MM/dd/yyyy"),
                            EmpDepartment = employee?.Department?.GetValue(),
                            DefaultGroupID = "ALL",
                            
                            
                        };
                        BQ.Save<Employee>(e,HandleDuplicates.Yes, "EmpOther1","EmployeeID",65);
                    }
                }

            }
        }
        public static void SyncVendors()
        {
            using (var connection = new QBConnection())
            {
                connection.Open();
                var vendorQueryRq = connection.Request.AppendVendorQueryRq();
                vendorQueryRq.ORVendorListQuery.VendorListFilter.ActiveStatus.SetValue(ENActiveStatus.asAll);
                
                //Send the request and get the response from QuickBooks
                connection.GetResponse();

                var vendorList = (IVendorRetList)connection.Response.Detail;

                if (vendorList != null)
                {
                    for (var i = 0; i < vendorList.Count; i++)
                    {
                        IVendorRet vendor = (IVendorRet)vendorList.GetAt(i);
                        Employee e = new Employee
                        {
                            EmployeeID = BQ.CleanId(vendor.Name?.GetValue()),
                            EmpCompany = vendor.CompanyName?.GetValue(),
                            EmpLName = vendor.LastName?.GetValue(),
                            EmpFName = vendor.FirstName?.GetValue(),
                            QBLinkID = vendor.ListID?.GetValue(),
                            EmpEmail = vendor.Email?.GetValue(),
                            EmpHFax = BQ.CleanPhone(vendor.Fax?.GetValue()),
                            Status = vendor.IsActive?.GetValue() == true ? "Active" : "Inactive",
                            MobileNumber = BQ.CleanPhone(vendor.Mobile?.GetValue()),
                            EmpTitle = vendor.JobTitle?.GetValue(),
                            EmpSalt = vendor.Salutation?.GetValue(),
                            EmpMemo = vendor.Notes?.GetValue(),
                            EmpMI = vendor.MiddleName?.GetValue().Substring(0, 1),
                            EmpContactPhone = BQ.CleanPhone(vendor.AltPhone?.GetValue()),
                            EmpStreet = (vendor.VendorAddress?.Addr1?.GetValue() ?? "" + " " + vendor.VendorAddress?.Addr2?.GetValue() ?? "").Trim(),
                            EmpStreet2 = (vendor.VendorAddress?.Addr3?.GetValue() ?? "" + " " + vendor.VendorAddress?.Addr4?.GetValue() ?? "").Trim(),
                            EmpCity = vendor.VendorAddress?.City?.GetValue(),
                            EmpCountry = vendor.VendorAddress?.Country?.GetValue(),
                            EmpState = vendor.VendorAddress?.State?.GetValue(),
                            EmpZip = vendor.VendorAddress?.PostalCode?.GetValue(),
                            EmpHPhone = BQ.CleanPhone(vendor.Phone?.GetValue()),
                            IsSub = -1,
                            EmpOther1 = BQ.CleanId(vendor.Name?.GetValue()),
                            EmpOther2 = vendor.VendorTypeRef?.FullName?.GetValue(),
                            DefaultGroupID = "All Vendors"

                        };
                        BQ.Save<Employee>(e,HandleDuplicates.Yes, "EmpOther1","EmployeeID",65);
                    }
                }

            }
        }
        public static void SyncAccounts()
        {
            using (var connection = new QBConnection())
            {
                connection.Open();
                var accountQueryRq = connection.Request.AppendAccountQueryRq();
                accountQueryRq.ORAccountListQuery.AccountListFilter.ActiveStatus.SetValue(ENActiveStatus.asAll);
                
                //Send the request and get the response from QuickBooks
                connection.GetResponse();

                var accountList = (IAccountRetList)connection.Response.Detail;

                if (accountList != null)
                {
                    for (var i = 0; i < accountList.Count; i++)
                    {
                        IAccountRet account = (IAccountRet)accountList.GetAt(i);
                        AccountList al = new AccountList
                        {
                            AccountID = BQ.CleanId(account?.AccountNumber?.GetValue() ?? account?.Name?.GetValue()),
                            AccountName = account?.FullName?.GetValue(),
                            AccountDesc = account?.Desc?.GetValue(),
                            IsInActive = (short?) (account?.IsActive?.GetValue() == true ? 0 : -1),
                            QBLinkID = account?.ListID?.GetValue(),
                            ParentAccountID = account?.ParentRef?.ListID?.GetValue()
                            
                        };
                        al.CardNumber = al.AccountID;

                        #region Account Type
                        switch (account?.AccountType?.GetValue())
                        {
                                case  ENAccountType.atAccountsPayable:
                                al.AccountTypeID = (short?) AccountType.AccountsPayable;
                                break;

                                case ENAccountType.atAccountsReceivable:
                                al.AccountTypeID = (short?)AccountType.AccountsReceivable;
                                break;

                                case ENAccountType.atBank:
                                al.AccountTypeID = (short?)AccountType.Bank;
                                break;

                                case ENAccountType.atCostOfGoodsSold:
                                al.AccountTypeID = (short?)AccountType.CostofGoodsSold;
                                break;

                                case ENAccountType.atCreditCard:
                                al.AccountTypeID = (short?)AccountType.CreditCard;
                                break;

                                case ENAccountType.atEquity:
                                al.AccountTypeID = (short?)AccountType.Equity;
                                break;

                                case ENAccountType.atExpense:
                                al.AccountTypeID = (short?)AccountType.Expense;
                                break;

                                case ENAccountType.atFixedAsset:
                                al.AccountTypeID = (short?)AccountType.FixedAsset;
                                break;

                                case ENAccountType.atIncome:
                                al.AccountTypeID = (short?)AccountType.Income;
                                break;

                                case ENAccountType.atLongTermLiability:
                                al.AccountTypeID = (short?)AccountType.LongTermLiability;
                                break;

                                case ENAccountType.atNonPosting:
                                al.AccountTypeID = (short?)AccountType.NonPosting;
                                break;

                                case ENAccountType.atOtherAsset:
                                al.AccountTypeID = (short?)AccountType.OtherAsset;
                                break;

                                case ENAccountType.atOtherCurrentLiability:
                                al.AccountTypeID = (short?)AccountType.OtherCurrentLiability;
                                break;

                                case ENAccountType.atOtherExpense:
                                al.AccountTypeID = (short?)AccountType.OtherExpense;
                                break;

                                case ENAccountType.atOtherCurrentAsset:
                                al.AccountTypeID = (short?)AccountType.OtherCurrentAsset;
                                break;

                                case ENAccountType.atOtherIncome:
                                al.AccountTypeID = (short?)AccountType.OtherIncome;
                                break;

                        }

                        #endregion
                        BQ.Save<AccountList>(al, HandleDuplicates.Yes,"CardNumber","AccountID",50);
                       
                    }
                    BQ.UpdateAccounts();
                }

            }
        }
        public static void SyncActivities()
        {
            using (var connection = new QBConnection())
            {
                connection.Open();
                var activityQueryRq = connection.Request.AppendItemServiceQueryRq();
                
                //Send the request and get the response from QuickBooks
                connection.GetResponse();

                var activityList = (IItemServiceRetList)connection.Response.Detail;

                if (activityList != null)
                {
                    for (var i = 0; i < activityList.Count; i++)
                    {
                        IItemServiceRet activity = (IItemServiceRet)activityList.GetAt(i);
                        Activity a = new Activity
                        {
                            ActivityDescription = activity?.ORSalesPurchase?.SalesAndPurchase?.SalesDesc?.GetValue()?? activity?.ORSalesPurchase?.SalesOrPurchase?.Desc?.GetValue(),
                            IsInActive = (short) (activity?.IsActive?.GetValue() == true ? 0 : -1),
                            ActivityBillable = -1,
                            QBLinkID = activity?.ListID?.GetValue(),
                            QBAccountID1 = activity?.ORSalesPurchase?.SalesOrPurchase?.AccountRef?.ListID?.GetValue() ?? activity?.ORSalesPurchase?.SalesAndPurchase?.IncomeAccountRef?.ListID.GetValue(),
                            AC_CostRate = (decimal?) (activity?.ORSalesPurchase?.SalesOrPurchase?.ORPrice?.Price?.GetValue() ?? 0),
                            DefaultGroupID = "ALL",
                            LastUpdated = DateTime.UtcNow
                        };

                        if (a.AC_CostRate == 0)
                            a.AC_CostRate = (decimal?) (activity?.ORSalesPurchase?.SalesAndPurchase?.SalesPrice?.GetValue() ?? 0);
                        if (activity?.Sublevel?.GetValue() == 0)
                        {
                            a.ActivityID = activity?.FullName?.GetValue();
                            if (a.ActivityID?.Length > 30)
                                a.ActivityID = BQ.CleanId(a.ActivityID.Substring(0, 30));
                            a.ActivityID += ":";
                        }
                        else
                        {
                            a.ActivityID = activity?.FullName?.GetValue();
                            if (a.ActivityID?.Length > 30)
                                a.ActivityID = BQ.CleanId(a.ActivityID.Substring(0, 30));
                        }
                        a.ActivityID = a.ActivityID;
                        a.Other6 = a.ActivityID;
                        a.AC_BillRate = a.AC_CostRate;
                        a.IncomeAccountID = a.QBAccountID1;
                        a.ActivityCode =
                            (activity?.Sublevel?.GetValue() == 1)
                                ? a.ActivityID.Substring(0, a.ActivityID.IndexOf(":", StringComparison.Ordinal))
                                : BQ.CleanId(activity?.FullName?.GetValue());
                        a.ActivitySub =
                            BQ.CleanId((activity?.Sublevel?.GetValue() == 1) ? activity?.Name?.GetValue() + ":" : "");
                        if (a.ActivityDescription == null || a.ActivityDescription?.Trim().Length == 0)
                            a.ActivityDescription = (a.ActivityCode + " " + a.ActivitySub).Trim();
                        BQ.Save<Activity>(a, HandleDuplicates.Yes,"Other6","ActivityID",30);
                    }
                    BQ.UpdateActivities();
                }

            }
        }
        public static void SyncExpenses()
        {
            using (var connection = new QBConnection())
            {
                connection.Open();
                var expenseQueryRq = connection.Request.AppendItemOtherChargeQueryRq();

                //Send the request and get the response from QuickBooks
                connection.GetResponse();

                var expenseList = (IItemOtherChargeRetList)connection.Response.Detail;

                if (expenseList != null)
                {
                    for (var i = 0; i < expenseList.Count; i++)
                    {
                        IItemOtherChargeRet expense = (IItemOtherChargeRet)expenseList.GetAt(i);
                        Expense e = new Expense
                        {
                            ExpDescription = expense?.ORSalesPurchase?.SalesAndPurchase?.SalesDesc?.GetValue() ?? expense?.ORSalesPurchase?.SalesOrPurchase?.Desc?.GetValue(),
                            IsInActive = (short)(expense?.IsActive?.GetValue() == true ? 0 : -1),
                            ExpBillable = -1,
                            QBLinkID = expense?.ListID?.GetValue(),
                            QBAccountID1 = expense?.ORSalesPurchase?.SalesOrPurchase?.AccountRef?.ListID?.GetValue() ?? expense?.ORSalesPurchase?.SalesAndPurchase?.IncomeAccountRef?.ListID.GetValue(),
                            ExpCost = (decimal?)(expense?.ORSalesPurchase?.SalesOrPurchase?.ORPrice?.Price?.GetValue() ?? 0),
                            DefaultGroupID = "ALL",
                            LastUpdated = DateTime.UtcNow
                                                        
                        };

                        if (e.ExpCost == 0)
                            e.ExpCost = (decimal?) (expense?.ORSalesPurchase?.SalesAndPurchase?.SalesPrice?.GetValue() ?? 0);
                        if (expense?.Sublevel?.GetValue() == 0)
                        {
                            e.ExpID = expense?.FullName?.GetValue();
                            if (e.ExpID?.Length > 30)
                                e.ExpID = BQ.CleanId(e.ExpID.Substring(0, 30));
                            e.ExpID += ":";
                        }
                        else
                        {
                            e.ExpID = expense?.FullName?.GetValue();
                            if (e.ExpID?.Length > 30)
                                e.ExpID = BQ.CleanId(e.ExpID.Substring(0, 30));
                        }
                        e.ExpID = e.ExpID;
                        e.Other6 = e.ExpID;
                        e.IncomeAccountID = e.QBAccountID1;
                        e.ExpCode =
                            BQ.CleanId((expense?.Sublevel?.GetValue() == 1)
                                ? e.ExpID.Substring(0, e.ExpID.IndexOf(":", StringComparison.Ordinal))
                                : BQ.CleanId(expense?.FullName?.GetValue()));
                        e.ExpSub =
                            BQ.CleanId((expense?.Sublevel?.GetValue() == 1) ? expense?.Name?.GetValue() + ":" : "");
                        if (e.ExpDescription == null || e.ExpDescription?.Trim().Length == 0)
                            e.ExpDescription = (e.ExpCode + " " + e.ExpSub).Trim();
                        BQ.Save<Expense>(e, HandleDuplicates.Yes, "Other6", "ExpID", 30);
                    }
                    BQ.UpdateExpenses();
                }

            }
        }
        public static void SyncClients()
        {
            using (var connection = new QBConnection())
            {
                connection.Open();
                var clientQueryRq = connection.Request.AppendCustomerQueryRq();
                clientQueryRq.ORCustomerListQuery.CustomerListFilter.ActiveStatus.SetValue(ENActiveStatus.asAll);
                
                //Send the request and get the response from QuickBooks
                connection.GetResponse();

                var clientList = (ICustomerRetList)connection.Response.Detail;

                if (clientList != null)
                {
                    for (var i = 0; i < clientList.Count; i++)
                    {
                        ICustomerRet client = (ICustomerRet)clientList.GetAt(i);
                        if (client?.ParentRef?.ListID?.GetValue() != null)
                            continue;





                        Client c = new Client
                        {
                            ClientID = BQ.CleanId(client?.Name?.GetValue()),
                            ClientCompany = client?.CompanyName?.GetValue(),
                            Status = (client?.IsActive?.GetValue() == true)? "Active" : "Inactive",
                            ClientMainSalt = client?.Salutation?.GetValue(),
                            ClientFName = client?.FirstName?.GetValue(),
                            ClientLName = client?.LastName?.GetValue(),
                            ClientMI = client?.MiddleName?.GetValue(),
                            ClientStreet = client?.BillAddress?.Addr2?.GetValue(),
                            ClientStreet2 = (client?.BillAddress?.Addr3?.GetValue() + " " + client?.BillAddress?.Addr4?.GetValue()).Trim(),
                            ClientCity = client?.BillAddress?.City?.GetValue(),
                            ClientState = client?.BillAddress?.State?.GetValue(),
                            ClientZip = client?.BillAddress?.PostalCode?.GetValue(),
                            ClientCountry = client?.BillAddress?.Country?.GetValue(),
                            ClientPhone = BQ.CleanPhone(client?.Phone?.GetValue()),
                            ClientMainPhone = BQ.CleanPhone(client?.AltPhone?.GetValue()),
                            ClientFax = BQ.CleanPhone(client?.Fax?.GetValue()),
                            ClientEmail =  client?.Email?.GetValue(),
                            ClientOther1 = client?.CustomerTypeRef?.FullName?.GetValue(),
                            ClientOther2 = client?.SalesRepRef?.FullName?.GetValue(),
                            ClientOther3 = client?.AccountNumber?.GetValue(),
                            ClientOther5 = BQ.CleanId(client?.Name?.GetValue()),
                            ClientSince = client?.TimeCreated?.GetValue(),
                            ClientMemo = client?.Notes?.GetValue(),
                            QBLinkID = client?.ListID?.GetValue(),
                            LastUpdated = DateTime.UtcNow,
                            ClientOther4 = client?.TermsRef?.FullName?.GetValue()

                        };
                     
                        BQ.Save<Client>(c, HandleDuplicates.Yes, "ClientOther5", "ClientID", 65);
                        if (client?.Contact?.IsSet() == true)
                            AddClientContact(client,c.ClientID);
                    }
                    BQ.UpdateClients();
                }

            }
        }
        private static void AddClientContact(ICustomerRet client, string clientid)
        {
            ClientContact cc = new ClientContact
            {
                ClientID = clientid,
                CliConID = client?.Contact?.GetValue(),
                CliConSalt = client?.Salutation?.GetValue(),
                CliConFName = client?.FirstName?.GetValue(),
                CliConLName = client?.LastName?.GetValue(),
                CliConMI = client?.MiddleName?.GetValue(),
                CliConStreet = client?.BillAddress?.Addr1?.GetValue(),
                CliConStreet2 = client?.BillAddress?.Addr2?.GetValue(),
                CliConCity = client?.BillAddress?.City?.GetValue(),
                CliConState = client?.BillAddress?.State?.GetValue(),
                CliConZip = client?.BillAddress?.PostalCode?.GetValue(),
                CliConCountry = client?.BillAddress?.Country?.GetValue(),
                CliConHPhone = BQ.CleanPhone(client?.Phone?.GetValue()),
                CliConWPhone = BQ.CleanPhone(client?.AltPhone?.GetValue()),
                MobileNumber = BQ.CleanPhone(client?.Mobile?.GetValue()),
                CliConHFax = BQ.CleanPhone(client?.Fax?.GetValue()),
                LastUpdated = client?.TimeModified?.GetValue() ?? DateTime.UtcNow,
                CliConMain = -1,
                CliConMemo = client?.Notes?.GetValue(),
                QBLinkID = client?.ListID?.GetValue()
            };
            BQ.Save<ClientContact>(cc, HandleDuplicates.Yes, "CliConID", "CliConID", 15);
        }
    }