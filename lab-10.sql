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
-- =============================================
-- Zadanie 3
-- =============================================
/*
 Zadanie NIE DA SIĘ WYKONAC, bo procedury składowane nie pozwalają na zmienne tabelaryczne w parametrze OUTPUT.
 Poniżej implementacja rozwiązania "naokoło" znalezionego na stackoverflow.
 */

create or alter procedure SalesLT.usp_GetCustomerOrderHistory @CustomerID int
as
begin
    set nocount on;

    select p.Name                   as Product,
           h.OrderDate,
           d.OrderQty               as Quantity,
           d.OrderQty * d.UnitPrice as TotalPrice
    from SalesLT.SalesOrderHeader h
             join SalesLT.SalesOrderDetail d on h.SalesOrderID = d.SalesOrderID
             join SalesLT.Product p on d.ProductID = p.ProductID
    where h.CustomerID = @CustomerID
    order by h.OrderDate;
end;

go;

-- implementacja: przechwycenie wyniku do zmiennej tabelarycznej
declare @History table
                 (
                     Product    nvarchar(50),
                     OrderDate  datetime,
                     Quantity   int,
                     TotalPrice money
                 );

insert into @History
    exec SalesLT.usp_GetCustomerOrderHistory @CustomerID = 29736;

select *
from @History;

go;

-- =============================================
-- Zadanie 4
-- =============================================

-- funkcja sprawdzająca czy klient już istnieje (mailu i telefonie)
create or alter function SalesLT.ufn_CustomerExists(
    @EmailAddress nvarchar(50),
    @Phone Phone
)
    returns bit
as
begin
    if exists (select 1
               from [239869].Customer
               where EmailAddress = @EmailAddress
                  or Phone = @Phone)
        return 1;

    return 0;
end;

go;

-- podłączenie do procedury z zadania 1
create or alter procedure SalesLT.usp_AddNewCustomer @FirstName Name,
                                                     @LastName K9_surname,
                                                     @CompanyName nvarchar(128),
                                                     @SalesPerson nvarchar(256) = 'adventure-works\krzysztof1',
                                                     @EmailAddress nvarchar(50),
                                                     @Phone dbo.Phone = null
as
begin
    set nocount on;

    if SalesLT.ufn_CustomerExists(@EmailAddress, @Phone) = 1
        throw 50001, N'Klient o podanych danych już istnieje', 1;

    begin tran;

    insert into [239869].Customer (FirstName, LastName, CompanyName, SalesPerson, EmailAddress, Phone,
                                   PasswordHash, PasswordSalt)
    values (@FirstName, @LastName, @CompanyName,
            @SalesPerson, @EmailAddress, @Phone, crypt_gen_random(16),
            crypt_gen_random(4));

    commit tran;
end;

go;

-- test: próba dodania duplikatu (powinien rzucić błąd)
exec SalesLT.usp_AddNewCustomer
     @FirstName = 'Test',
     @LastName = 'Procedury',
     @CompanyName = 'Proceduralna S.A.',
     @EmailAddress = 'test@procedury.com',
     @Phone = '1231231234';

go;

-- =============================================
-- Zadanie 5
-- =============================================
create or alter procedure SalesLT.usp_UpdateCustomer @CustomerID int,
                                                     @FirstName Name = null,
                                                     @LastName K9_surname = null,
                                                     @CompanyName nvarchar(128) = null,
                                                     @SalesPerson nvarchar(256) = null,
                                                     @EmailAddress nvarchar(50) = null,
                                                     @Phone Phone = null
as
begin
    set nocount on;

    if not exists (select 1 from [239869].Customer where CustomerID = @CustomerID)
        throw 50002, N'Klient o podanym ID nie istnieje', 1;

    update [239869].Customer
    set FirstName    = isnull(@FirstName, FirstName),
        LastName     = isnull(@LastName, LastName),
        CompanyName  = isnull(@CompanyName, CompanyName),
        SalesPerson  = isnull(@SalesPerson, SalesPerson),
        EmailAddress = isnull(@EmailAddress, EmailAddress),
        Phone        = isnull(@Phone, Phone),
        ModifiedDate = getdate()
    where CustomerID = @CustomerID;
end;

go;

-- test: aktualizacja istniejącego klienta
exec SalesLT.usp_UpdateCustomer
     @CustomerID = 1,
     @Phone = '111-222-3333';

go;

-- test: próba aktualizacji nieistniejącego klienta (powinien rzucić błąd)
exec SalesLT.usp_UpdateCustomer
     @CustomerID = 999999,
     @FirstName = 'Nie ma';

go;
