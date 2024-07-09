SELECT *
FROM PortfolioProject.dbo.Covid_Vaccine;

--SELECT * FROM PortfolioProject.dbo.covidDeath;

--selecting required data

SELECT location,date,ROUND((total_cases_per_million*population)/1000000,2) AS total_cases, new_cases,total_deaths,population
FROM PortfolioProject.dbo.covidDeath
Order by 1,2;

--total cases VS total deaths
SELECT location,date,ROUND((total_cases_per_million*population)/1000000,2) AS total_cases, new_cases,total_deaths,(total_deaths/ROUND((total_cases_per_million*population)/1000000,2)*100) AS deathpercentage
FROM PortfolioProject.dbo.covidDeath
WHERE location like '%state%'
Order by 1,2;

--total cases vs population
-- what percent of people got covid
SELECT location,date,ROUND((total_cases_per_million*population)/1000000,2) AS total_cases, population, new_cases,total_deaths,((((total_cases_per_million*population)/1000000)/population)*100) AS infectedpopulationpercent
FROM PortfolioProject.dbo.covidDeath
--WHERE location like '%state%'
Order by 1,2;

--countries with highest infection rate compared to population
Select Location, Population, MAX(((total_cases_per_million*population)/1000000)) as HighestInfectionCount,  Max((((total_cases_per_million*population)/1000000)/population))*100 as PercentPopulationInfected
From PortfolioProject.dbo.covidDeath
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

--countries with highest death count per population
Select location
 , MAX(cast( new_deaths as int)) as TotalDeathCount
From PortfolioProject.dbo.covidDeath
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(new_deaths as int)) as TotalDeathCount
From PortfolioProject.dbo.covidDeath
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc;

-- changing the datatype of the col
ALTER table PortfolioProject.dbo.covidDeath
Alter column new_cases int;

-- changing the datatype of the col
ALTER table PortfolioProject.dbo.Covid_Vaccine
Alter column new_vaccinations int;

-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject.dbo.covidDeath
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations
 ,SUM(CAST(vac.new_vaccinations as int)) OVER (Partition BY dea.location ORDER BY dea.location,
 dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.covidDeath dea
Join PortfolioProject.dbo.Covid_Vaccine vac
 ON dea.location = vac.location
 AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- altering new vac col

ALTER Table PortfolioProject.dbo.Covid_Vaccine
Alter Column new_vaccinations int;

 -- USE CTE

 WITH POPvsVAC (Continent, Location, Date, Population, New_vaccination ,RollingPeopleVaccinated)
 AS
 (
 SELECT dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations
 ,SUM(vac.new_vaccinations) OVER (Partition BY dea.location ORDER BY dea.location,
 dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.covidDeath dea
Join PortfolioProject.dbo.Covid_Vaccine vac
 ON dea.location = vac.location
 AND dea.date = vac.date
WHERE dea.continent is not null
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From POPvsVAC

-- TEMP Table
DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population bigint,
New_vaccinations BIGINT,
RollingPeopleVaccinated BIGINT
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM 
    PortfolioProject.dbo.covidDeath dea
JOIN 
    PortfolioProject.dbo.Covid_Vaccine vac
    ON dea.location = vac.location
    AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
-- order by 2,3
Select *, (CAST(RollingPeopleVaccinated AS FLOAT)/ CAST(Population AS FLOAT))*100
From #PercentPopulationVaccinated

-- creating view for storing data for visualization
USE PortfolioProject
GO
CREATE VIEW PercentPopulationVaccinated as
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM 
    PortfolioProject.dbo.covidDeath dea
JOIN 
    PortfolioProject.dbo.Covid_Vaccine vac
    ON dea.location = vac.location
    AND dea.date = vac.date
	WHERE dea.continent is not null


SELECT *
  FROM [PortfolioProject].[dbo].[PercentPopulationVaccinated]
