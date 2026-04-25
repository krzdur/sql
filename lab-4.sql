-- =============================================
-- Krzysztof
-- Durbajło
-- 239869
-- =============================================

-- =============================================
-- Zadanie 1
-- =============================================
declare @Litera char(1) = 'k';
declare @Cyfra int = 9;

select CustomerID, FirstName, LastName
from SalesLT.Customer
where 1 = 1
  and left(lower(LastName), 1) = @Litera
  and CustomerID % 10 = @Cyfra;

go
-- =============================================
-- Zadanie 2
-- =============================================
declare @Produkty table
                  (
                      ProductID int,
                      Name      nvarchar(50),
                      ListPrice money
                  );

insert into @Produkty (ProductID, Name, ListPrice)
select ProductID, Name, ListPrice
from SalesLT.Product
where 1 = 1
  and lower(Name) like '%k%';

select *
from @Produkty;

go
-- =============================================
-- Zadanie 3
-- =============================================
select ca.CustomerID,
       c.FirstName,
       c.LastName,
       a.City
into #KlienciMiasta
from SalesLT.CustomerAddress ca
         join SalesLT.Customer c
              on ca.CustomerID = c.CustomerID
         left join SalesLT.Address a
                   on ca.AddressID = a.AddressID
where lower(a.City) like 'k%';


select *
from #KlienciMiasta;

drop table #KlienciMiasta

go
-- =============================================
-- Zadanie 4
-- =============================================
create schema Student_9;

create table Student_9.ProduktyK
(
    ProductID int,
    Name      nvarchar(100),
    Category  nvarchar(100),
    ListPrice money,
);

insert into Student_9.ProduktyK
select p.ProductID,
       p.Name,
       pc.Name as Category,
       p.ListPrice
from SalesLT.Product p
         join SalesLT.ProductCategory pc
              on p.ProductCategoryID = pc.ProductCategoryID
where 1 = 1
  and lower(pc.Name) like '%k%';

go
-- =============================================
-- Zadanie 5
-- =============================================
declare @Podsumowanie table
                  (
                      Category    nvarchar(100),
                      SredniaOcen money
                  );

insert into @Podsumowanie (Category, SredniaOcen)
select
    pc.ProductCategoryID,
    avg(p.ListPrice)
from SalesLT.ProductCategory pc
left join SalesLT.Product p
    on pc.ProductCategoryID = p.ProductCategoryID
where 1=1
    and p.ProductCategoryID % 10 = 9
group by pc.ProductCategoryID;

select * from @Podsumowanie

go
-- =============================================
-- Zadanie 6
-- =============================================
create schema [239869];

alter schema [239869] transfer SalesLT.Customer;
alter schema [239869] transfer SalesLT.CustomerAddress;

go
