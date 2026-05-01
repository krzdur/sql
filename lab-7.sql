-- =============================================
-- Krzysztof
-- Durbajło
-- 239869
-- =============================================

-- =============================================
-- Zadanie 1
-- =============================================
create type SalesLT.K9_surname from nvarchar(50) not null;

-- tylko jedna tabela zawiera nazwisko
-- select * from INFORMATION_SCHEMA.COLUMNS where lower(COLUMN_NAME) = 'lastname'
alter table [239869].Customer
alter column LastName SalesLT.K9_surname not null;

go
-- =============================================
-- Zadanie 2
-- =============================================

/*
 Jedyne możliwe rozwiązanie to zapisanie danych z JSONa w tabeli pomocniczej. Utworzenie zmiennej, żeby użyć jej
 w widoku wywołuje błąd: 'CREATE VIEW' must be the first statement in a query batch.
 */
declare @ProductInfo nvarchar(max) = N'
    {
      "NewPrices": [
        {"ProductID": "680", "NewPrice": 10},
        {"ProductID": "706", "NewPrice": 20},
        {"ProductID": "707", "NewPrice": 30},
        {"ProductID": "708", "NewPrice": 40},
        {"ProductID": "709", "NewPrice": 50}
      ]
    }
';

-- utworzenie tabeli pomocniczej
create table [239869].ProductInfoTable (
    ProductID int,
    NewPrice money
    );

insert into [239869].ProductInfoTable
select ProductID, NewPrice
from openjson(@ProductInfo, '$.NewPrices')
with (
    ProductID int '$.ProductID',
    NewPrice money '$.NewPrice'
    );
go

create view SalesLT.v_NewProductPrice as
    select
        a.ProductID,
        a.ListPrice,
        b.NewPrice,
        b.NewPrice - a.ListPrice as PriceChange
    from SalesLT.Product a
    join [239869].ProductInfoTable b on a.ProductID = b.ProductID;
go

select * from SalesLT.v_NewProductPrice;

go
-- =============================================
-- Zadanie 3
-- =============================================
create view [239869].[239869_Order] as
    select top 5 * -- TOP X jest wymagane dla sortowanych widoków
    from SalesLT.Product
    order by ListPrice desc;

go
-- =============================================
-- Zadanie 4
-- =============================================
/*
 Analiza rentowności produktów: klasyfikacja produktów według rentowności ((menedżer produktu chce wiedzieć,
 co opłaca się sprzedawać). Widok klasyfikuje produkty do jednego z 4 progów rentowności. Wyklucza produkty bez danych
 kosztowych, żeby uniknąć dzielenia przez zero i fałszywych wyników.
 */
create view Student_9.MyLogicView as
    select
        p.ProductID,
        p.Name as ProductName,
        c.Name as Category,
        p.StandardCost,
        p.ListPrice,
        cast(
            (p.ListPrice - p.StandardCost) / p.ListPrice * 100
            as decimal(5, 2)
        ) as MarginPercentage,
        case
            when (p.ListPrice - p.StandardCost) / p.ListPrice < 0 then 'Strata'
            when (p.ListPrice - p.StandardCost) / p.ListPrice < 0.20 then 'Niska marża'
            when (p.ListPrice - p.StandardCost) / p.ListPrice < 0.50 then 'Standardowa'
            else 'Premium'
        end as MarginTier
    from SalesLT.Product p
    join SalesLT.ProductCategory c on p.ProductCategoryID = c.ProductCategoryID
    where p.StandardCost > 0;

go;
-- =============================================
-- Zadanie 5
-- =============================================
create view Student_9.v_PremiumProducts as
    select
        ProductID,
        ProductName,
        Category,
        ListPrice,
        MarginPercentage
    from Student_9.MyLogicView
    where MarginTier = 'Premium';

go