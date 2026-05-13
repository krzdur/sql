-- =============================================
-- Krzysztof
-- Durbajło
-- 239869
-- =============================================

-- =============================================
-- Zadanie 1
-- =============================================

/*
 Znajduje identyfikator najtańszego produktu:
 - w danej kategorii,
 - w danym kolorze,
 - sprzedawanego od podanej daty
 */

create function SalesLT.ufn_BestProduct(
    @CategoryID int = 18,
    @Color nvarchar(15) = 'black',
    @SoldSince datetime = '2005-01-01'
)
    returns int
as
begin
    declare @BestProductID int;

    select top 1 @BestProductID = ProductID
    from SalesLT.Product
    where 1 = 1
      and ProductCategoryID = @CategoryID
      and lower(Color) = lower(@Color)
      and SellStartDate >= @SoldSince
    order by ListPrice;

    return @BestProductID;
end;

go;

select SalesLT.ufn_BestProduct(default, default, default);

go;
-- =============================================
-- Zadanie 2
-- =============================================
/*
 Rozwiązanie bardzo naokoło.

 Nie można używać tabel tymczasowych wewnątrz funkcji (również globalnych) - błąd: Cannot access temporary tables
 from within a function. Jedyne możliwe rozwiązanie to utworzenie nowego table type
 (ze stackoverflow: https://stackoverflow.com/questions/9561626/cannot-access-temporary-tables-from-within-a-function).
 */

-- 1. Nowy typ przechowujący tabelę
create type Student_9.TopProductsType as table
(
    ProductID int,
    ListPrice money
);

-- 2. Deklaracja tabeli tymczasowej jak w poleceniu
select top 25 ProductID,
              ListPrice
into #TopProducts
from SalesLT.Product
order by ListPrice / Weight; -- najlepsze produkty to te z najniższą ceną za kilogram

go;

-- 3. Deklaracja funkcji tabelarycznej
create or alter function Student_9.ufn_CalcAdjustedPrices(
    @InputTable Student_9.TopProductsType readonly
)
    returns @Summary table
                     (
                         ProductID     int,
                         ListPrice     money,
                         AdjustedPrice money
                     )
as
begin
    insert into @Summary
    select ProductID,
           ListPrice,
           ListPrice - (ListPrice * 0.09)
    from @InputTable;

    return;
end;

go;

-- 4. Zapisanie danych z #TopProducts do zmiennej typu `TopProductsType`, żeby mogły być argumentem utworzonej funkcji
declare @TopProductTable Student_9.TopProductsType
insert into @TopProductTable
select *
from #TopProducts

select *
from Student_9.ufn_CalcAdjustedPrices(@TopProductTable);

go;
-- =============================================
-- Zadanie 3
-- =============================================
create or alter function Student_9.ufn_ProductsJsonByCategory(
    @CategoryName nvarchar(50)
)
    returns nvarchar(max)
as
begin
    declare @Result nvarchar(max);

    set @Result = (select p.ProductID         as [Product.ID],
                          p.Name              as [Product.Name],
                          c.Name              as [Category.Name],
                          o.SalesOrderID      as [Order.ID],
                          o.OrderQty          as [Order.Quantity],
                          o.UnitPriceDiscount as [Order.UnitPriceDiscount],
                          o.LineTotal         as [Order.LineTotal]
                   from SalesLT.Product p
                            join SalesLT.ProductCategory c on p.ProductCategoryID = c.ProductCategoryID
                            join SalesLT.SalesOrderDetail o on p.ProductID = o.ProductID
                   where lower(c.Name) = lower(@CategoryName)
                   for json path);

    return @Result;
end;

go;

select Student_9.ufn_ProductsJsonByCategory('Helmets');

go;
-- =============================================
-- Zadanie 4
-- =============================================
create or alter function Student_9.ufn_IsPriceHigherThanCurrent(
    @ProductData nvarchar(max)
)
    returns bit
as
begin
    -- Walidacja poprawności JSONa - early exit, jeśli format nie jest poprawny
    if isjson(@ProductData) = 0
        return cast('@ProductData must be a valid JSON' as int) -- sposób ze stackoverflow na zwrócenie błędu w funkcji
    if json_path_exists(@ProductData, '$.ProductID') = 0
        return cast('@ProductData must have ProductID key' as int)
    if json_path_exists(@ProductData, '$.ListPrice') = 0
        return cast('@ProductData must have ListPrice key' as int)

    declare @ProductID int = json_value(@ProductData, '$.ProductID');
    declare @JsonPrice money = json_value(@ProductData, '$.ListPrice');
    declare @CurrentPrice money;

    select @CurrentPrice = ListPrice
    from SalesLT.Product
    where ProductID = @ProductID;

    return iif(@JsonPrice > @CurrentPrice, 1, 0);
end;

go;
/*
 Poniżej test z poprawnym JSON-em. Zachowanie systemu przy cenie równej zależy od operatora w warunku:
    @JsonPrice > @CurrentPrice
 W tym przypadku równa cena zwróci 0 (false). Zmiana operatora na >= wywołałaby 1 przy równej cenie.
 */
select Student_9.ufn_IsPriceHigherThanCurrent('{"ProductID": 680, "ListPrice": 1436.6}')

-- test walidacji: brak ceny
-- select Student_9.ufn_IsPriceHigherThanCurrent('{"ProductID": 680, "NotListPrice": 1436.6}')

-- test walidacji: brak ID
-- select Student_9.ufn_IsPriceHigherThanCurrent('{"NotProductID": 680, "NotListPrice": 1436.6}')

go;

-- =============================================
-- Zadanie 5
-- =============================================
/*
 Funkcja przyjmująca listę produktów wraz z proponowaną ceną w formacie JSON i dla każdego produktu
 wywołuje ufn_IsPriceHigherThanCurrent.
 */
create function Student_9.ufn_BulkIsPriceHigher(
    @ProductsData nvarchar(max)
)
returns table
as
return
    (select d.ProductID,
            d.ListPrice as JsonPrice,
            p.ListPrice as CurrentPrice,
            Student_9.ufn_IsPriceHigherThanCurrent(
                '{"ProductID":' + cast(d.ProductID as nvarchar) +
                ',"ListPrice":' + cast(d.ListPrice as nvarchar) + '}'
            ) as IsHigher
    from openjson(@ProductsData)
    with (
        ProductID int '$.ProductID',
        ListPrice money '$.ListPrice'
    ) d
    join SalesLT.Product p on p.ProductID = d.ProductID);

go;

select *
from Student_9.ufn_BulkIsPriceHigher(
        '[' ||
                  '{"ProductID": 680, "ListPrice": 1436.6},' ||
                  '{"ProductID": 706, "ListPrice": 1435},' ||
                  '{"ProductID": 707, "ListPrice": 35}' ||
                  ']'
     );

go;

-- =============================================
-- Zadanie 6
-- =============================================

-- TODO

-- =============================================
-- Zadanie 7
-- =============================================
create function dbo.fn_GetCustomerCreditRisk(
    @CustomerID int
)
returns nvarchar(6)
as
    begin
        declare @Orders table
            (
                SalesOrderID int,
                TotalDue money,
                DueDate datetime,
                ShipDate datetime,
                Is3DaysLate int
            )

        insert into @Orders
        select
            SalesOrderID,
            TotalDue,
            DueDate,
            ShipDate,
            iif(datediff(day, DueDate, ShipDate) > 3, 1, 0) as Is3DaysLate
        from SalesLT.SalesOrderHeader
        where CustomerID = @CustomerID

        declare @TotalOrderValue money = (select sum(TotalDue) from @Orders)
        declare @DelayedOrdersCnt int = (select sum(Is3DaysLate) from @Orders)

        if @TotalOrderValue > 100000 and @DelayedOrdersCnt >= 2
            return 'HIGH'
        if @TotalOrderValue > 50000
            return 'MEDIUM'
        return 'LOW'

    end;

go;

-- Brak zamówień z 3-dniowym opóźnieniem = brak klientów HIGH
select dbo.fn_GetCustomerCreditRisk(30089); -- LOW
select dbo.fn_GetCustomerCreditRisk(29736); -- MEDIUM

go;
