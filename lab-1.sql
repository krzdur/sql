-- =============================================
-- Krzysztof
-- Durbajło
-- 239869
-- =============================================

-- =============================================
-- Zadanie 1
-- =============================================
select *
from SalesLT.Customer
where 1=1
  and lower(LastName) like 'k%';

go
-- =============================================
-- Zadanie 2
-- =============================================
select FirstName, LastName, EmailAddress
from SalesLT.Customer
where 1=1
    and CustomerID % 10 = 9;

go
-- =============================================
-- Zadanie 3
-- =============================================
select Name, ListPrice, ProductNumber
from SalesLT.Product
where 1=1
  and lower(Name) like '%k%'
order by ListPrice desc;

go
-- =============================================
-- Zadanie 4
-- =============================================
select avg(ListPrice)
from SalesLT.Product
where 1=1
  and ProductCategoryID % 10 = 9;

go
-- =============================================
-- Zadanie 5
-- =============================================
select distinct a.City
from SalesLT.Customer c
         left join SalesLT.CustomerAddress ca
                   on c.CustomerID = ca.CustomerID
         left join SalesLT.Address a
                   on ca.AddressID = a.AddressID
where 1=1
  and lower(City) like 'k%';

go
-- =============================================
-- Zadanie 6
-- =============================================
insert into SalesLT.Customer (FirstName, LastName, CompanyName, EmailAddress, PasswordHash, PasswordSalt)
values ('Krzysztof',
        'Durbajło',
        'Lab9',
        'krzysztof.durbajlo@lab9.com',
        '0800fc57-7294-c34e-0b28-ad2839435945',
        'ceb20772');

select *
from SalesLT.Customer
where 1=1
  and EmailAddress = 'krzysztof.durbajlo@lab9.com';

go
-- =============================================
-- Zadanie 7
-- =============================================
insert into SalesLT.ProductCategory (Name)
values ('Special-K'),
       ('Extra-9');

go
-- =============================================
-- Zadanie 8
-- =============================================
select p.Name  as ProductName,
       p.ProductNumber,
       pc.Name as ProductCategoryName,
       239869  as OwnerId
into SalesLT.ProductsCategories239869
from SalesLT.Product p
         join SalesLT.ProductCategory pc
              on p.ProductCategoryID = pc.ProductCategoryID
where 1=1
    and (lower(p.Name) like 'k%k' or lower(pc.Name) like '%k%');

go
-- =============================================
-- Zadanie 9
-- =============================================
select ProductCategoryName,
       count(distinct ProductNumber) as ProductCount
from SalesLT.ProductsCategories239869
group by ProductCategoryName;

go