SELECT *
FROM PortfolioProject..CovidDeaths$
-- WHERE continent is not null
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations$
--ORDER BY 3,4

-- Select Data that we are going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths$
ORDER BY 1,2 

-- Looking at Total Cases vs Total Deaths

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercantage
FROM PortfolioProject..CovidDeaths$
WHERE Location like '%kingdom%'
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows what percantage of population got Covid

SELECT Location, date, total_cases, population, (total_cases/population) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
WHERE continent is not null
-- WHERE Location like '%kingdom%'
ORDER BY 1,2

-- Looking at Countries with Highest Infection Rate compared to population

SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
WHERE continent is not null
-- WHERE Location like '%kingdom%'
GROUP BY Location, population
ORDER BY PercentPopulationInfected DESC

-- Showing Countries with Highest Death Count per Population

SELECT Location, max(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths$
WHERE continent is not null
-- WHERE Location like '%kingdom%'
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- Let's Break Things Down by Contintent

SELECT location, max(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths$
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Showing continents with the highest death count per population

SELECT continent, max(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths$
WHERE continent is null
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- Global numbers

SELECT sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, sum(cast(new_deaths as int)) / sum(new_Cases)*100 as DeathPercantage
FROM PortfolioProject..CovidDeaths$
-- WHERE Location like '%kingdom%' 
WHERE continent is not null
-- GROUP BY date
ORDER BY 1,2


-- Looking at total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint, vac.new_vaccinations)) over (Partition by dea.location Order By dea.location, dea.date) as RollingPeopleVaccinated

FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- USE CTE

WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint, vac.new_vaccinations)) over (Partition by dea.location Order By dea.location, dea.date) as RollingPeopleVaccinated

FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopVsVac


-- TEMP TABLE

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	rollingpeoplevaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint, vac.new_vaccinations)) over (Partition by dea.location Order By dea.location, dea.date) as RollingPeopleVaccinated

FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated


CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint, vac.new_vaccinations)) over (Partition by dea.location Order By dea.location, dea.date) as RollingPeopleVaccinated

FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT *
FROM PercentPopulationVaccinated