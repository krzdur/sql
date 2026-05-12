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