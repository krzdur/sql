-- =============================================
-- Krzysztof
-- Durbajło
-- 239869
-- =============================================

-- =============================================
-- Zadanie 1
-- =============================================
create or alter procedure SalesLT.usp_AddNewCustomer @FirstName Name,
                                                     @LastName K9_surname,
                                                     @CompanyName nvarchar(128),
                                                     @SalesPerson nvarchar(256) = 'adventure-works\krzysztof1',
                                                     @EmailAddress nvarchar(50)
as
begin
    set nocount on;

    begin tran;

    insert into [239869].Customer (FirstName, LastName, CompanyName, SalesPerson, EmailAddress,
                                   PasswordHash, PasswordSalt)
    values (@FirstName, @LastName, @CompanyName,
            @SalesPerson, @EmailAddress, crypt_gen_random(16),
            crypt_gen_random(4));

    commit tran;
end;

go;

-- test
exec SalesLT.usp_AddNewCustomer
     @FirstName = 'Test',
     @LastName = 'Procedury',
     @CompanyName = 'Proceduralna S.A.',
    -- zostawiamy wartość domyślną dla @SalesPerson
     @EmailAddress = 'test@procedury.com';

go;

select *
from [239869].Customer
where EmailAddress = 'test@procedury.com'

go;

-- =============================================
-- Zadanie 2
-- =============================================
create or alter procedure SalesLT.usp_SearchCustomers @CustomerID int = null,
                                                      @FirstName Name = null,
                                                      @LastName K9_surname = null,
                                                      @EmailAddress nvarchar(50) = null
as
begin
    set nocount on;

    select CustomerID,
           FirstName,
           LastName,
           EmailAddress,
           CompanyName
    from [239869].Customer
    where (@CustomerID is null or CustomerID = @CustomerID)
      and (@FirstName is null or FirstName like @FirstName)
      and (@LastName is null or LastName like @LastName)
      and (@EmailAddress is null or EmailAddress like @EmailAddress);
end;

go;

-- test:
exec SalesLT.usp_SearchCustomers @LastName = 'Adams'; -- wyszukuje po nazwisku
exec SalesLT.usp_SearchCustomers @EmailAddress = '%adventure-works.com'; -- wyszukuje po fragmencie maila
exec SalesLT.usp_SearchCustomers @FirstName = 'Kim', @LastName = 'Adams'; -- nie znaleziono

go;