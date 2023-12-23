SELECT *
FROM protfolioProject..CovidDeaths
ORDER BY 3,4;

--SELECT *
--FROM protfolioProject..CovidVaccinations
--ORDER BY 3,4;

SELECT location,date,total_cases,new_cases,total_deaths,population
FROM protfolioProject..CovidDeaths
ORDER BY 1,2;

-- coverting total deaths and total cases into float 

--ALTER TABLE dbo.CovidDeaths
--ALTER COLUMN total_cases float;

--ALTER TABLE dbo.CovidDeaths
--ALTER COLUMN total_deaths float;

--Looking at Total cases Vs Total Deaths
-- SHOWS THE LIKELIHOOD OF DYING IF YOU CONTRACT COVID IN MY COUNTRY

SELECT location,date,total_cases,total_deaths,(total_deaths/total_cases)*100  AS deathpercentage
FROM protfolioProject..CovidDeaths
WHERE location = 'India'
ORDER BY 1,2;

--Looking at total cases Vs Population
--shows what percentage of population got cvoid

SELECT location,date,population,total_cases,( total_cases/population)*100 as EffectingPercentage
FROM protfolioProject..CovidDeaths
WHERE location = 'India'
ORDER BY 1,2;

-- looking at countries with highest infection rate Vs population

SELECT location,population, MAX(total_cases) AS Highest_infection_count,MAX(( total_cases/population)*100 )as EffectingPercentage
FROM protfolioProject..CovidDeaths
GROUP BY location,population
ORDER BY EffectingPercentage DESC;

-- Showing countires with highest death count per population

SELECT location,MAX(total_deaths) AS highest_deaths
FROM protfolioProject..CovidDeaths
WHERE continent is NOT null
GROUP BY location
ORDER BY highest_deaths DESC

-- Showing continents with highest death count per population

SELECT continent,MAX(total_deaths) AS highest_deaths
FROM protfolioProject..CovidDeaths
WHERE continent IS not NULL
GROUP BY continent
ORDER BY highest_deaths DESC;
 
--Changing data type of new deaths and new cases

ALTER TABLE dbo.CovidDeaths
ALTER COLUMN new_cases float;

ALTER TABLE dbo.CovidDeaths
ALTER COLUMN new_deaths float;


-- Global Numbers

SELECT  date, SUM(new_cases) AS total_new_Cases, SUM (new_deaths) AS total_new_deaths, (SUM(new_deaths)/SUM(new_cases) )*100 AS Death_Percentage
FROM protfolioProject..CovidDeaths
WHERE continent IS NOT NULL  
GROUP BY date
HAVING SUM(new_cases) > 0 --if there are no cases there will not be any deaths
ORDER BY 1,2;
 
-- Total death percentage of new cases GLOBALLY

SELECT   SUM(new_cases) AS total_new_Cases, SUM (new_deaths) AS total_new_deaths, (SUM(new_deaths)/SUM(new_cases) )*100 AS Death_Percentage
FROM protfolioProject..CovidDeaths
WHERE continent IS NOT NULL  
HAVING SUM(new_cases) > 0 --if there are no cases there will not be any deaths
ORDER BY 1,2;

 
SELECT COUNT(*)
FROM protfolioProject..CovidDeaths;


SELECT *
FROM protfolioProject..CovidVaccinations;

ALTER TABLE protfolioProject..CovidVaccinations
ALTER COLUMN total_vaccinations float;

--total vaccinations in the year 2023
SELECT  MONTH(date) AS months,SUM(total_vaccinations) AS Vaccinations
FROM protfolioProject..CovidVaccinations
WHERE YEAR(date) = 2023
GROUP BY MONTH(date)
HAVING SUM(total_vaccinations) > 0 
ORDER BY months;

--
SELECT D.location,MAX(D.population) AS Population,MAX(total_vaccinations) AS Vaccinations
FROM protfolioProject..CovidDeaths D LEFT JOIN  protfolioProject..CovidVaccinations V ON D.iso_code = V.iso_code
WHERE YEAR(D.date) = 2023 AND D.continent IS NOT NULL
GROUP BY D.location
HAVING SUM(total_vaccinations) > 0 
ORDER BY D.location;

-- Percentage of people full vaccinated in their respective countries 
DROP TABLE IF EXISTS #populationVaccinated
CREATE TABLE #populationVaccinated
( Country VarChar(100),
  CountryPopulation float,
  VaccinatedPopulation float,
  populationVaccinatedPercentage float
 )


INSERT INTO #populationVaccinated
SELECT D.location,MAX(D.population) AS Population,MAX(people_fully_vaccinated) AS PeopleVaccinated, MAX(people_fully_vaccinated)/MAX(D.population) AS VaccinatedPercentage
FROM protfolioProject..CovidDeaths D LEFT JOIN  protfolioProject..CovidVaccinations V ON D.iso_code = V.iso_code
WHERE D.continent IS NOT NULL
GROUP BY D.location
ORDER BY D.location 
;

SELECT * FROM #populationVaccinated;


--COUNTRIES WITH HIGHEST VACCINATIONS
SELECT TOP 5  country,populationVaccinatedPercentage
FROM #populationVaccinated
ORDER BY 2 DESC;
 

 --HIGHEST CASES IN A MONTH

SELECT location, YEAR(date) AS years, MONTH(date) AS months,SUM(new_cases) AS new_cases
FROM protfolioProject..CovidDeaths
GROUP BY location, YEAR(date),MONTH(date)
ORDER BY  location,years,months;

ALTER TABLE dbo.CovidVaccinations
ALTER COLUMN  new_vaccinations float


--use cte

With PopvsVac (continent, Location, Date,population,New_Vaccinations,RollingPeopleVaccinated)
AS
(
	SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,SUM( vac.new_vaccinations) OVER (Partition by dea.location)
	FROM protfolioProject..CovidDeaths dea JOIN protfolioProject..CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent is NOT NULL 
	--ORDER BY  2,3;
)
SELECT * , (RollingPeopleVaccinated/population)*100
FROM PopvsVac;

--TEMP TABLE

DROP Table if Exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Contivent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,SUM( vac.new_vaccinations) OVER (Partition by dea.location)
	FROM protfolioProject..CovidDeaths dea JOIN protfolioProject..CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
	--WHERE dea.continent is NOT NULL 

SELECT * , (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated;