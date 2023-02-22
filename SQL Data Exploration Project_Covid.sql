-----------------------------------------------
--- Data Exploration from Covid Death Table ---
-----------------------------------------------

SELECT *
FROM PortfolioProjects.dbo.CovidDeaths
WHERE continent is not null /*In location is included Countries and Continents. 
							Whith this WHERE clause location only shows Countries*/
ORDER BY 3,4

-- Select Data that is going to be used

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProjects.dbo.CovidDeaths
WHERE continent is not null /* location will only shows Contries */
ORDER BY 1, 2


-- Looking at Total Cases vs Total Deaths
---- Shows the likelihood of dying if you contract Covid is United States
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProjects.dbo.CovidDeaths
WHERE location like '%states'
ORDER BY 1, 2


-- Looking at the Total Cases vs Population
---- Shows what percentage of the Population have died from Covid

SELECT location, date, total_cases, population, (total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProjects.dbo.CovidDeaths
--WHERE location like '%states'
WHERE continent is not null
ORDER BY 1, 2


-- Looking at Countries with highest Infection Rate compared to Population

SELECT location, population, Max(total_cases) as HighestInfectionCount, 
Max((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProjects.dbo.CovidDeaths
--WHERE location like '%states'
WHERE continent is not null
GROUP BY  location, population
ORDER BY 4 desc


-- Showing Countries with Highest Death Count per Population

SELECT location, population, Max(cast(total_deaths as int)) as TotalDeathCount, 
Max(cast(total_deaths as int)/population)*100 as HighestDeathsRatePerPopulation
FROM PortfolioProjects.dbo.CovidDeaths
WHERE continent is not null
GROUP BY  location, population
ORDER BY HighestDeathsRatePerPopulation desc


-- Showing Countries with Highest Death Count per Country

SELECT location, Max(cast(total_deaths as int)) as TotalDeathCount 
FROM PortfolioProjects.dbo.CovidDeaths
WHERE continent is not null
GROUP BY  location
ORDER BY TotalDeathCount desc


-- Breaking things down by Continent

/*This query shows North America as continent that only includes United States.
It is important to check how the numbers per Continents are calculated*/
--SELECT continent, Max(cast(total_deaths as int)) as TotalDeathCount 
--FROM PortfolioProjects.dbo.CovidDeaths
--WHERE continent is not null
--GROUP BY  continent
--ORDER BY TotalDeathCount desc

/*This query shows the correct values for the continents but also show other 
locations that are neither Continents or Countries*/
--SELECT location, Max(cast(total_deaths as int)) as TotalDeathCount 
--FROM PortfolioProjects.dbo.CovidDeaths
--WHERE continent is null 
--GROUP BY  location
--ORDER BY TotalDeathCount desc

/*This query shows only results by continent*/
SELECT location, Max(cast(total_deaths as int)) as TotalDeathCount 
FROM PortfolioProjects.dbo.CovidDeaths
WHERE continent is null 
	and location not like '%income' 
	and location not like '%Union' 
	and location not like '%national'
	and location not like 'World'
GROUP BY  location
ORDER BY TotalDeathCount desc


-- Showing Continents with the highest death count per population

SELECT location as Continent, population, Max(cast(total_deaths as int)) as TotalDeathCount, 
Max(cast(total_deaths as int)/population)*100 as HighestDeathsRatePerPopulation
FROM PortfolioProjects.dbo.CovidDeaths
WHERE continent is null 
	and location not like '%income' 
	and location not like '%Union' 
	and location not like '%national'
	and location not like 'World'
GROUP BY  location, population
ORDER BY HighestDeathsRatePerPopulation desc


-- Global Numbers

---- Shows global total cases and total deaths per day
SELECT date, sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths,
sum(cast(new_deaths as int))/sum(new_cases) as DeathPercentage
FROM PortfolioProjects.dbo.CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

---- Shows global total cases and total deaths
SELECT sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths,
sum(cast(new_deaths as int))/sum(new_cases) as DeathPercentage
FROM PortfolioProjects.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 1,2


-----------------------------------------------------------------------------------
--- Data Exploration from Covid Vaccination Table joined with Covid Death Table ---
-----------------------------------------------------------------------------------

-- Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(CONVERT(bigint,vac.new_vaccinations)) OVER 
(Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100 /*this calculation can't be done here. A CTE is needed*/
From PortfolioProjects.dbo.CovidDeaths dea
join PortfolioProjects.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
Order by 2,3

-- Using CTE (number of columns in the CTE and the select table have to be the same

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(CONVERT(bigint,vac.new_vaccinations)) OVER 
(Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProjects.dbo.CovidDeaths dea
join PortfolioProjects.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--Order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Using Temp table

Drop table if exists #PercentPopVac
CREATE TABLE #PercentPopVac
(
Continent nvarchar(255),
Location nvarchar(255),
date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopVac
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(CONVERT(bigint,vac.new_vaccinations)) OVER 
(Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProjects.dbo.CovidDeaths dea
join PortfolioProjects.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--Order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopVac


--- Creating VIEW to store data for later visualizations

CREATE VIEW PercentPoplationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(CONVERT(bigint,vac.new_vaccinations)) OVER 
(Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProjects.dbo.CovidDeaths dea
join PortfolioProjects.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--Order by 2,3

Select *
From PercentPoplationVaccinated