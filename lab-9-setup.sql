-- Setup tabel i danych do Zadania 6 w Lab 9


-- schemat
create schema CityBikes;

go;

-- tabele
create table CityBikes.BikeStations
(
    StationID int primary key,
    Name      nvarchar(50) not null,
    District  nvarchar(50) not null,
    Capacity  int          not null,
);


create table CityBikes.Bikes
(
    BikeID         int primary key,
    Model          nvarchar(50) not null,
    ProductionYear int          not null,
    Status         nvarchar(15) not null -- active / maintenance / retired
);

create table CityBikes.Rides
(
    RideID         int primary key,
    BikeID         int           not null references CityBikes.Bikes (BikeID),
    StartStationID int           not null references CityBikes.BikeStations (StationID),
    EndStationID   int           not null references CityBikes.BikeStations (StationID),
    StartTime      datetime      not null,
    EndTime        datetime      not null,
    DistanceKm     decimal(5, 2) not null
);

create table CityBikes.MaintenanceLogs
(
    LogID        int primary key,
    BikeID       int          not null references CityBikes.Bikes (BikeID),
    ReportedDate datetime     not null,
    ResolvedDate datetime,
    IssueType    nvarchar(20) not null -- tire / brake / chain
);

go;


-- dane
insert into CityBikes.BikeStations (StationID, Name, District, Capacity)
values (1, 'Rynek', 'Stare Miasto', 8),
       (2, 'Dworzec PKP', 'Stare Miasto', 10),
       (3, 'Park Jordana', 'Krowodrza', 8),
       (4, 'Kampus UEK', 'Rakowice', 8),
       (5, 'Galeria Bonarka', N'Podgórze', 5);

insert into CityBikes.Bikes (BikeID, Model, ProductionYear, Status)
values (1, 'Kross 3.0', 2022, 'active'),
       (2, 'Kross 3.0', 2022, 'active'),
       (3, 'Kross 2.0', 2021, 'maintenance'),
       (4, 'Giant X1', 2023, 'active'),
       (5, 'Giant X1', 2023, 'active'),
       (6, 'Kross 2.0', 2020, 'retired'),
       (7, 'Specialized X1', 2023, 'active'),
       (8, 'Kross 3.0', 2022, 'active');

insert into CityBikes.Rides (RideID, BikeID, StartStationID, EndStationID, StartTime, EndTime, DistanceKm)
values (1, 1, 1, 2, '2026-05-01 08:00', '2026-05-01 08:15', 2.10),
       (2, 2, 2, 4, '2026-05-01 09:00', '2026-05-01 09:35', 4.80),
       (3, 4, 3, 1, '2026-05-01 10:00', '2026-05-01 10:50', 6.20),
       (4, 1, 2, 3, '2026-05-01 12:00', '2026-05-01 12:22', 3.50),
       (5, 5, 4, 5, '2026-05-01 14:00', '2026-05-01 14:10', 1.80),
       (6, 7, 1, 4, '2026-05-02 07:30', '2026-05-02 08:05', 5.10),
       (7, 2, 4, 1, '2026-05-02 09:00', '2026-05-02 09:18', 2.90),
       (8, 4, 1, 5, '2026-05-02 11:00', '2026-05-02 11:45', 5.60),
       (9, 8, 2, 3, '2026-05-02 13:00', '2026-05-02 13:12', 2.00),
       (10, 1, 3, 2, '2026-05-02 15:00', '2026-05-02 15:40', 4.40);


insert into CityBikes.MaintenanceLogs (LogID, BikeID, ReportedDate, ResolvedDate, IssueType)
values (1, 3, '2026-04-10', '2026-04-12', 'tire'),
       (2, 3, '2026-04-20', '2026-04-25', 'brake'),
       (3, 6, '2026-03-15', '2026-03-18', 'chain'),
       (4, 6, '2026-04-01', null, 'tire'),
       (5, 1, '2026-05-01', '2026-05-01', 'tire'),
       (6, 3, '2026-05-02', null, 'chain'),
       (7, 2, '2026-04-28', '2026-04-29', 'brake'),
       (8, 7, '2026-05-03', '2026-05-04', 'tire'),
       (9, 4, '2026-05-02', '2026-05-03', 'chain'),
       (10, 6, '2026-04-15', '2026-04-17', 'tire');

go;
