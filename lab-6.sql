-- =============================================
-- Krzysztof
-- Durbajło
-- 239869
-- =============================================

-- =============================================
-- Zadanie 1
-- =============================================
begin tran;

select top 1 *
from SalesLT.ProductCategory with (
    tablockx, -- blokada tabeli na wyłączność
    holdlock  -- utrzymanie blokady do końca transakcji
);

waitfor delay '00:00:30';

rollback;

go
-- =============================================
-- Test blokady (w osobnej sesji podczas trwania powyższej transakcji).
-- Insert będzie czekał blokowany aż pierwsza transakcja się skończy

-- begin tran;
--
-- insert into SalesLT.ProductCategory (Name, ParentProductCategoryID, rowguid, ModifiedDate)
-- values ('TestCategory', NULL, NEWID(), GETDATE());
--
-- rollback transaction;
-- =============================================

/*
Pierwsza transakcja blokuje tabelę SalesLT.ProductCategory na 30 sekund, co powoduje, że wprowadzanie do niej danych
staje się niemożliwe. W trakcie trwania tej transakcji niemożliwy staje się też odczyt danych z tej tabeli dla innych
sesji/użytkowników. Pominięcie rollback/commit spowodowałoby zablokowanie tabeli bezterminowo.

W środowisku produkcyjnym, gdzie jedna tabela może być jednocześnie używany przez setki użytkowników,
powoduje to kolejkowanie zapytań, rosnący czas odpowiedzi i potencjalny timeout aplikacji.
 */

-- =============================================
-- Zadanie 2
-- =============================================

-- Sprawdzenie stanu tabel PRZED transakcją
select count(*) as customer_count_before from [239869].Customer;
select count(*) as product_count_before from SalesLT.Product;
select count(*) as produktyk_count_before from Student_9.ProduktyK;
select count(*) as customer_address_count_before from [239869].CustomerAddress;

begin tran;

update [239869].Customer set CompanyName = 'Transakcja SA 1',  ModifiedDate = getdate() where CustomerID = 1;
update [239869].Customer set CompanyName = 'Transakcja SA 2',  ModifiedDate = getdate() where CustomerID = 2;
update [239869].Customer set CompanyName = 'Transakcja SA 3',  ModifiedDate = getdate() where CustomerID = 3;
update [239869].Customer set CompanyName = 'Transakcja SA 4',  ModifiedDate = getdate() where CustomerID = 4;
update [239869].Customer set CompanyName = 'Transakcja SA 5',  ModifiedDate = getdate() where CustomerID = 5;
update [239869].Customer set CompanyName = 'Transakcja SA 6',  ModifiedDate = getdate() where CustomerID = 6;
update [239869].Customer set CompanyName = 'Transakcja SA 7',  ModifiedDate = getdate() where CustomerID = 7;
update [239869].Customer set CompanyName = 'Transakcja SA 8',  ModifiedDate = getdate() where CustomerID = 8;
update [239869].Customer set CompanyName = 'Transakcja SA 9',  ModifiedDate = getdate() where CustomerID = 9;
update [239869].Customer set CompanyName = 'Transakcja SA 10', ModifiedDate = getdate() where CustomerID = 10;

update SalesLT.Product set ListPrice = ListPrice * 2, ModifiedDate = getdate() where ProductID = 680;
update SalesLT.Product set ListPrice = ListPrice * 2, ModifiedDate = getdate() where ProductID = 706;
update SalesLT.Product set ListPrice = ListPrice * 2, ModifiedDate = getdate() where ProductID = 707;
update SalesLT.Product set ListPrice = ListPrice * 2, ModifiedDate = getdate() where ProductID = 708;
update SalesLT.Product set ListPrice = ListPrice * 2, ModifiedDate = getdate() where ProductID = 709;
update SalesLT.Product set ListPrice = ListPrice * 2, ModifiedDate = getdate() where ProductID = 710;
update SalesLT.Product set ListPrice = ListPrice * 2, ModifiedDate = getdate() where ProductID = 711;
update SalesLT.Product set ListPrice = ListPrice * 2, ModifiedDate = getdate() where ProductID = 712;
update SalesLT.Product set ListPrice = ListPrice * 2, ModifiedDate = getdate() where ProductID = 713;
update SalesLT.Product set ListPrice = ListPrice * 2, ModifiedDate = getdate() where ProductID = 714;

insert into Student_9.ProduktyK (ProductID, Name, Category, ListPrice) values
    (9001, 'Produkt Testowy 1',  'KategoriaTEST', 10.00),
    (9002, 'Produkt Testowy 2',  'KategoriaTEST', 20.00),
    (9003, 'Produkt Testowy 3',  'KategoriaTEST', 30.00),
    (9004, 'Produkt Testowy 4',  'KategoriaTEST', 40.00),
    (9005, 'Produkt Testowy 5',  'KategoriaTEST', 50.00),
    (9006, 'Produkt Testowy 6',  'KategoriaTEST', 60.00),
    (9007, 'Produkt Testowy 7',  'KategoriaTEST', 70.00),
    (9008, 'Produkt Testowy 8',  'KategoriaTEST', 80.00),
    (9009, 'Produkt Testowy 9',  'KategoriaTEST', 90.00),
    (9010, 'Produkt Testowy 10', 'KategoriaTEST', 100.00);


truncate table [239869].CustomerAddress;

-- Sprawdzenie stanu tabel WEWNĄTRZ transakcji (po wszystkich operacjach)
select count(*) as customer_count_in_tran  from [239869].Customer;
select top 10 CustomerID, CompanyName from [239869].Customer order by CustomerID;

select count(*) as product_count_in_tran   from SalesLT.Product;
select top 10 ProductID, ListPrice from SalesLT.Product order by ProductID;

select count(*) as produktyk_count_in_tran from Student_9.ProduktyK;
select top 10 Name, Category, ListPrice from Student_9.ProduktyK;

select count(*) as customer_address_count_in_tran from [239869].CustomerAddress;

waitfor delay '00:05:0'

rollback;

-- Sprawdzenie stanu tabel PO transakcji (po rollback)
select count(*) as customer_count_after    from [239869].Customer;
select top 10 CustomerID, CompanyName from [239869].Customer order by CustomerID;

select count(*) as product_count_after     from SalesLT.Product;
select top 10 ProductID, ListPrice from SalesLT.Product order by ProductID;

select count(*) as produktyk_count_after   from Student_9.ProduktyK;

select count(*) as customer_address_count_after from [239869].CustomerAddress;

go
/*
WYNIK I ANALIZA

Operacje select wykonywane są w 3 iteracjach:
- PRZED transakcją
- WEWNĄTRZ transakcji
- PO transakcji

Wewnątrz transakcji (po operacjach, przed rollback):
- Customer: CompanyName zmienione na 'Transakcja SA X'
- Product: ListPrice dla 10 produktów podwojona
- ProduktyK: wstawione 10 testowych wierszy
- CustomerAddress: usunięcie danych w tabeli

Rollback przerywa transakcję i przywraca tabele do stanu sprzed transakcji.

Po rollback:
- CompanyName i ListPrice mają oryginalne wartości.
- ProduktyK ma tyle samo wierszy co przed transakcją
- dane w CustomerAddress zostały przywrócone (truncate table jest operacją transakcyjną i może zostać cofnięta)
*/

-- =============================================
-- Zadanie 3
-- =============================================

-- Tabele modyfikowane przez update/insert
select top 10 CustomerID, CompanyName from [239869].Customer with (nolock);
select top 10 ProductID, ListPrice from SalesLT.Product with (nolock);
select top 10 ProductID, Name, Category, ListPrice from Student_9.ProduktyK with (nolock);

go
/*
Tabela [239869].CustomerAddress jest modyfikowana przez truncate table. To operacja DDL (Data Definition Language),
która zakłada blokadę Schema Modification. NIE MA sposobu odczytania tabeli w trakcie operacji truncate w
niezakończonej transakcji.
*/

-- =============================================
-- Zadanie 4
-- =============================================
begin try
    select cast(ProductNumber as int)
    from SalesLT.Product
end try
begin catch
    select error_message()
end catch;

go
-- =============================================
-- Zadanie 5
-- =============================================

/*
Scenariusz: złożenie nowego zamówienia przez klienta

Operacje:
1. Walidacja danych wejściowych (@Quantity > 0, klient istnieje, produkt istnieje)
2. Pobranie aktualnej ceny jednostkowej produktu
3. Wstawienie zamówienia do SalesLT.SalesOrderHeader
4. Wstawienie pozycji zamówienia do SalesLT.SalesOrderDetail z pobraną ceną
5. Aktualizacja sumy w zamówieniu na podstawie ilości i ceny

Możliwe błędy:
- Quantity <= 0: nieprawidłowe dane wejściowe (własny throw)
- Klient nie istnieje: brak rekordu w SalesLT.Customer (własny throw)
- Produkt nie istnieje: UnitPrice pozostaje NULL po SELECT (własny throw)
- Cena produktu = 0: produkt wycofany ze sprzedaży (własny throw)
- Naruszenie FK lub CHECK: przechwycone przez blok CATCH
- dowolny inny błąd SQL: przechwycone przez blok CATCH
*/

-- deklaracja zmiennych, wartości domyślne przypisane dla testów
declare @CustomerID int = 1;
declare @ProductID int = 680;
declare @Quantity smallint = 1;
declare @Discount money = 0.00;
declare @UnitPrice money;
declare @NewOrderID int;

begin try

    if @Quantity <= 0
        throw 50001, N'Ilość musi być większa od zera.', 1;

    if not exists (select 1 from [239869].Customer where CustomerID = @CustomerID)
        throw 50002, 'Klient o podanym CustomerID nie istnieje.', 1;

    select @UnitPrice = ListPrice
    from SalesLT.Product
    where ProductID = @ProductID;

    if @UnitPrice is null
        throw 50003, 'Produkt o podanym ProductID nie istnieje.', 1;

    if @UnitPrice = 0
        throw 50004, N'Produkt ma cenę 0 i jest wycofany ze sprzedaży.', 1;

    begin tran;

        declare @Inserted table (SalesOrderID int);

        insert into SalesLT.SalesOrderHeader (
            OrderDate, DueDate, Status, OnlineOrderFlag, CustomerID, ShipMethod, SubTotal, TaxAmt, Freight,
            rowguid, ModifiedDate
        )
        -- przechwycenie przydzielonego SalesOrderID
        output inserted.SalesOrderID into @Inserted
        values (
            getdate(), dateadd(day, 13, getdate()), 1, 1,
            @CustomerID, 'CARGO TRANSPORT 5',
            0, 0, 0,
            newid(), getdate()
        );

        set @NewOrderID = (select SalesOrderID from @Inserted);

        insert into SalesLT.SalesOrderDetail (
            SalesOrderID, OrderQty, ProductID, UnitPrice, UnitPriceDiscount, rowguid, ModifiedDate
        )
        values (
            @NewOrderID, @Quantity, @ProductID,
            @UnitPrice, @Discount,
            newid(), getdate()
        );

        update SalesLT.SalesOrderHeader
        set SubTotal = @UnitPrice * @Quantity * (1 - @Discount),
            ModifiedDate = getdate()
        where SalesOrderID = @NewOrderID;

    rollback;

    select
        'Zamówienie pomyślnie złożone' as wynik,
        @NewOrderID as SalesOrderID,
        @CustomerID as CustomerID,
        @ProductID as ProductID,
        @Quantity as Quantity,
        @UnitPrice as UnitPrice,
        @UnitPrice * @Quantity * (1 - @Discount) as SubTotal;

end try
begin catch

    if @@trancount > 0
        rollback;

    select
        error_number()    as ErrorNumber,
        error_severity()  as ErrorSeverity,
        error_state()     as ErrorState,
        error_line()      as ErrorLine,
        error_message()   as ErrorMessage;

end catch;
-- =============================================
-- Zadanie 6
-- =============================================
/*
 Dodano begin tran i rollback w wierszach 220 i 253
 */