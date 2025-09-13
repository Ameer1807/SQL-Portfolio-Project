CREATE TABLE CovidVaccine (
    col1 NVARCHAR(MAX),
    col2 NVARCHAR(MAX),
    Location NVARCHAR(MAX),
    Date NVARCHAR(MAX),
    col5 NVARCHAR(MAX),
    col6 NVARCHAR(MAX),
    col7 NVARCHAR(MAX),
    col8 NVARCHAR(MAX),
    col9 NVARCHAR(MAX),
    col10 NVARCHAR(MAX),
    col11 NVARCHAR(MAX),
    col12 NVARCHAR(MAX),
    col13 NVARCHAR(MAX),
    col14 NVARCHAR(MAX),
    col15 NVARCHAR(MAX),
    col16 NVARCHAR(MAX),
    col17 NVARCHAR(MAX),
    col18 NVARCHAR(MAX),
    col19 NVARCHAR(MAX),
    col20 NVARCHAR(MAX),
    col21 NVARCHAR(MAX),
    col22 NVARCHAR(MAX),
    col23 NVARCHAR(MAX),
    col24 NVARCHAR(MAX),
    col25 NVARCHAR(MAX),
    col26 NVARCHAR(MAX),
    col27 NVARCHAR(MAX),
    col28 NVARCHAR(MAX),
    col29 NVARCHAR(MAX),
    col30 NVARCHAR(MAX),
    col31 NVARCHAR(MAX),
    col32 NVARCHAR(MAX),
    col33 NVARCHAR(MAX),
    col34 NVARCHAR(MAX),
    col35 NVARCHAR(MAX),
    col36 NVARCHAR(MAX),
    col37 NVARCHAR(MAX)
);

BULK INSERT CovidVaccine
FROM 'C:\Users\Syed Ameer Jan\Downloads\Covid Vaccine.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',  
    ROWTERMINATOR = '0x0d0a',
    TABLOCK,
    CODEPAGE = '65001',
    DATAFILETYPE = 'char',
    MAXERRORS = 10000
);

select *
FROM [Portfolio Project]..CovidVaccine
order by 3,4

select *
FROM [Portfolio Project]..CovidDeaths
where continent is not null
order by 3,4

Select Location, date, total_cases, new_cases, total_deaths, population
From [Portfolio Project]..CovidDeaths
Where continent is not null 
order by 1,2

--- Total cases vs Total deaths--
select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From [Portfolio Project]..CovidDeaths
where Location like '%states%' and continent is not null
order by 1,2 

-- Total Cases vs Population--
-- Shows what percentage of population infected with Covid--
select Location, date, total_cases, total_deaths, (total_cases/population)*100 as PercentPopulationInfected
from [Portfolio Project]..CovidDeaths
where continent is not null
order by 1,2

--- Countries with Highest Infection Rate compared to Population---
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From [Portfolio Project]..CovidDeaths
where continent is not null
Group by Location, Population
order by PercentPopulationInfected desc

--- Countries with Highest Death Count per Population--- 

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From [Portfolio Project]..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc

-- Showing contintents with the highest death count per population--

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From [Portfolio Project]..CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS--

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From [Portfolio Project]..CovidDeaths
where continent is not null 
order by 1,2

--GLOBAL---

Select *
from [Portfolio Project]..CovidDeaths dea
join [Portfolio Project]..CovidVaccine vac
    On dea.location =  vac.col3
    and dea.date = vac.col4

-- Total Population vs Vaccinations--

Select dea.continent, dea.location, dea.date, dea.population, vac.col17 as new_vaccinations
, SUM(CONVERT(int,vac.col17)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVaccine vac
	On dea.location = vac.col3
	and dea.date = vac.col4
where dea.continent is not null 
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query--

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.col17 as new_vaccinations
, SUM(CONVERT(int,vac.col17)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVaccine vac
	On dea.location = vac.col3
	and dea.date = vac.col4
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

--Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    RollingPeopleVaccinated numeric
);

INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    TRY_CONVERT(datetime, dea.date, 120) as Date,
    dea.population, 
    TRY_CONVERT(numeric, vac.col17) as New_vaccinations,
    SUM(TRY_CONVERT(int, vac.col17)) 
        OVER (PARTITION BY dea.Location ORDER BY dea.location, TRY_CONVERT(datetime, dea.date, 120)) as RollingPeopleVaccinated
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccine vac
    ON dea.location = vac.col3
    AND TRY_CONVERT(datetime, dea.date, 120) = TRY_CONVERT(datetime, vac.col4, 120)
WHERE dea.continent IS NOT NULL;

-- Final select with %
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS VaccinationPercentage
FROM #PercentPopulationVaccinated


-- Creating View to store data for later visualizations
DROP VIEW IF EXISTS PercentPopulationVaccinated;
GO 
CREATE VIEW PercentPopulationVaccinated AS
Select dea.continent, dea.location, dea.date, dea.population, vac.col17 as new_vaccinations
, SUM(CONVERT(int,vac.col17)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVaccine vac
	On dea.location = vac.col3
	and dea.date = vac.col4
where dea.continent is not null 
--order by 2,3

SELECT * 
FROM sys.views
WHERE name = 'PercentPopulationVaccinated';

SELECT TOP 10 * 
FROM PercentPopulationVaccinated;
