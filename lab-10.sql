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

-- =============================================
-- Zadanie 6
-- =============================================

-- utworzenie tabeli ProductInventory

create table SalesLT.ProductInventory
(
    ProductID    int      not null primary key references SalesLT.Product (ProductID),
    Quantity     int      not null default 0,
    ModifiedDate datetime not null default getdate()
);

go;

create or alter procedure SalesLT.usp_AddNewProduct @Name nvarchar(50),
                                                    @ProductCategoryID int,
                                                    @ListPrice money,
                                                    @Quantity int
as
begin
    set nocount on;

    -- walidacja danych wejściowych
    if
        @ListPrice <= 0
        throw 50010, N'Cena musi być większa od zera', 1;

    if
        @Quantity < 0
        throw 50011, N'Ilość w magazynie nie może być ujemna', 1;

    if
        not exists (select 1 from SalesLT.ProductCategory where ProductCategoryID = @ProductCategoryID)
        throw 50012, N'Podana kategoria nie istnieje', 1;

    begin tran;

    begin try
        declare @ProductID int;

        insert into SalesLT.Product (Name, ProductNumber, StandardCost, ListPrice,
                                     ProductCategoryID, SellStartDate)
        values (@Name,
                'NEW-' + convert(nvarchar(8), crypt_gen_random(16), 2),
                @ListPrice * 0.5,
                @ListPrice,
                @ProductCategoryID,
                getdate());

        set
            @ProductID = scope_identity();

        insert into SalesLT.ProductInventory (ProductID, Quantity)
        values (@ProductID, @Quantity);

        commit tran;
    end try
    begin catch
        rollback tran;
        throw;
    end catch
end;

go;

-- test: dodanie nowego produktu
exec SalesLT.usp_AddNewProduct
     @Name = 'Testowy Produkt',
     @ProductCategoryID = 5,
     @ListPrice = 99.99,
     @Quantity = 50;

go;

-- walidacja
select p.ProductID, p.Name, p.ListPrice, p.ProductCategoryID, i.Quantity
from SalesLT.Product p
         join SalesLT.ProductInventory i on p.ProductID = i.ProductID
where p.Name = 'Testowy Produkt';

go;

-- =============================================
-- Zadanie 7
-- =============================================

-- 1. Utworzenie tabeli tymczasowej TopProducts (copy-paste z Lab 9, Zad 2.)
select top 25 ProductID,
              ListPrice
into #TopProducts
from SalesLT.Product
order by ListPrice / Weight;  -- najlepsze produkty to te z najniższą ceną za kilogram 🤷🏻‍♂️

go;

-- 2. utworzenie procedury
create or alter procedure Student_9.usp_CalcAdjustedPrices
as
begin
    set nocount on;

    -- sprawdzenie czy #TopProduct została utworzona
    if object_id('tempdb..#TopProducts') is null
        throw 50013, N'Najpierw utwórz #TopProducts', 1;

    select ProductID,
           ListPrice,
           ListPrice - (ListPrice * 0.09) as AdjustedPrice
    from #TopProducts;
end;

go;

-- 3. Zapisanie wyniku do @Summary
declare @Summary table
                 (
                     ProductID     int,
                     ListPrice     money,
                     AdjustedPrice money
                 )

insert into @Summary
    exec Student_9.usp_CalcAdjustedPrices;

select * from @Summary;


go;
