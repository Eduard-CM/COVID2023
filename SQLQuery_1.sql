/*
Covid 19 Data Exploration - updated on 6th June 2023 from public data

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From ProjectCovid.dbo.CovidDeath
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From ProjectCovid.dbo.CovidDeath
Where continent is not null 
order by 1,2



select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From ProjectCovid.dbo.CovidDeath
where location like '%states'
order by 1, 2

-- Looking at total Cases vs Population
-- Shows what percentage of population got Covid

select location, date, total_cases, population, (total_cases/population)*100 as InfectedPopulation
From ProjectCovid.dbo.CovidDeath
where location like '%romania'
order by 1, 2

-- Looking at Countries with Highest Infection Rate vs Population

select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PopulationInfected
From ProjectCovid.dbo.CovidDeath
-- where location like '%romania'
group by location, population
order by PopulationInfected DESC

-- Showing Countries with the Highest Deathcount per Population

select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From ProjectCovid.dbo.CovidDeath
where continent is not NULL
group by location
order by TotalDeathCount DESC

-- Break per continet

select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From ProjectCovid.dbo.CovidDeath
where continent is not NULL and location not like '%income'
group by continent
order by TotalDeathCount DESC

-- Showing the continents with the highest death count per population

select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From ProjectCovid.dbo.CovidDeath
where continent is not NULL and location not like '%income'
group by continent
order by TotalDeathCount DESC

-- Global Numbers

SELECT 
       SUM(new_cases) AS total_cases,
       SUM(new_deaths) AS total_deaths,
       CASE WHEN SUM(CAST(new_cases AS INT)) = 0
            THEN 0
            ELSE (SUM(CAST(new_deaths AS INT)) * 100.0) / NULLIF(SUM(CAST(new_cases AS INT)), 0)
       END AS DeathPercentage
FROM ProjectCovid.dbo.CovidDeath
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

-- total population vs vaccination

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated, 
--(RollingPeopleVaccinated/population)*100
from ProjectCovid.dbo.CovidVac vac 
JOIN ProjectCovid.dbo.CovidDeath dea
ON dea.LOCATION = vac.LOCATION
and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- USE CTE

With PoPvsVac (Continent, location, date, population, New_Vaccinations, RollingPeopleVaccinated)
as 
(select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated 
--, (RollingPeopleVaccinated/population)*100
from ProjectCovid.dbo.CovidDeath dea
JOIN ProjectCovid.dbo.CovidVac vac
ON dea.LOCATION = vac.LOCATION
and dea.date = vac.date
where dea.continent is not null)
select *, (RollingPeopleVaccinated/population)*100
from PoPvsVac
order by 2,3

-- temp table

drop table if EXISTS #PercentPopulationVaccinated 
create table #PercentPopulationVaccinated 
(
    Continent nvarchar(255),
    location nvarchar(255),
    date datetime,
    population numeric,
    new_vaccinations numeric,
    RollingPeopleVaccinated numeric)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated 
--, (RollingPeopleVaccinated/population)*100
from ProjectCovid.dbo.CovidDeath dea
JOIN ProjectCovid.dbo.CovidVac vac
ON dea.LOCATION = vac.LOCATION
and dea.date = vac.date
where dea.continent is not null

select *,(RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated
order by 2, 3

-- Creating View to store data for later visualitations

Create View PercentPopulationVaccinated AS
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated 
--, (RollingPeopleVaccinated/population)*100
from ProjectCovid.dbo.CovidDeath dea
JOIN ProjectCovid.dbo.CovidVac vac
ON dea.LOCATION = vac.LOCATION
and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select *
from PercentPopulationVaccinated