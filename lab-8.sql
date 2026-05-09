-- =============================================
-- Krzysztof
-- Durbajło
-- 239869
-- =============================================

-- =============================================
-- Zadanie 1
-- =============================================
create table SalesLT.ProductPriceHistory (
    ProductPriceChangeID int identity(1,1) primary key,
    ProductID int not null,
    ListPriceOld money,
    ListPriceNew money
);

go;

create trigger SalesLT.trg_Product_Price_History
    on SalesLT.Product
    after update
    as
    begin
        set nocount on;

        if exists(
           select 1 from deleted d join inserted i on d.ProductID = i.ProductId
           where d.ListPrice <> i.ListPrice
       )

        begin
           insert into SalesLT.ProductPriceHistory (ProductID, ListPriceOld, ListPriceNew)
           select d.ProductID, d.ListPrice, i.ListPrice
           from deleted d
           join inserted i on d.ProductID = i.ProductID
           where d.ListPrice <> i.ListPrice
        end

    end;

go;

-- =============================================
-- Zadanie 2
-- =============================================
create table SalesLT.DeletedCustomersLog (
    CustomerDeletionID int identity(1,1) primary key,
    CustomerID int,
    Title nvarchar(6),
    FirstName nvarchar(50),
    MiddleName nvarchar(50),
    LastName nvarchar(50),
    DeletedAt datetime default getdate()
);

go;

/*
 Trigger musi obsługiwać operacje, które usuwają >1 rekord, np:

    delete from SalesLT.Customer
    where CustomerID in (
        1,      <- klient bez zamówienia, zostaje usunięty
        29485   <- klient z zamówieniem, trafia do DeletedCustomersLog
    );
 */

create trigger SalesLT.trg_Log_Deleted_Customers
    on SalesLT.Customer
    instead of delete
    as
    begin
        set nocount on;

        insert into SalesLT.DeletedCustomersLog (CustomerID, Title, FirstName, MiddleName, LastName)
        select d.CustomerID, d.Title, d.FirstName, d.MiddleName, d.LastName
        from deleted d
        where exists(
            select 1
            from SalesLT.SalesOrderHeader o
            where o.CustomerID = d.CustomerID
        );

        delete c from SalesLT.Customer c
        join deleted d on c.CustomerID = d.CustomerID
        where not exists(
            select 1
            from SalesLT.SalesOrderHeader o
            where o.CustomerID = d.CustomerID
        );
    end;

go;

-- =============================================
-- Zadanie 3
-- =============================================
/*
 Wygląda na to, że drzewko kategorii jest płytsze niż w opisie zadania i ma tylko 2 poziomy.
 Zmodyfikowałem dane, żeby wygenerować ścieżkę jak w opisie.
 */

-- Żeby udowodnić, że rekurencja działa zmieniamy parenta dla Road Frames:
update SalesLT.ProductCategory
    set ParentProductCategoryID = 6 -- Road Bikes
    where Name = 'Road Frames';

go;

-- Oczekiwany wynik w wierszu 17
with categories as (
    -- anchor: parents
    select
        ProductCategoryID,
        cast(Name as nvarchar(200)) as Name
    from SalesLT.ProductCategory
    where ParentProductCategoryID is null

    union all
    -- recursive: podkategorie
    select
        pc.ProductCategoryID,
        cast(concat(c.Name, N' → ', pc.Name) as nvarchar(200)) as Name
    from SalesLT.ProductCategory pc
    join categories c
        on pc.ParentProductCategoryID = c.ProductCategoryID
)

select Name from categories order by Name;

go;


