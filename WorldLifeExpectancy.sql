-- Performing Data Cleaning on World Life Expectancy Dataset

SELECT * 
FROM worldlifexpectancy;

-- 1. Finding the duplicates

SELECT Country, Year, CONCAT(Country, Year), COUNT(CONCAT(Country, Year))
FROM worldlifexpectancy
GROUP BY Country, Year, CONCAT(Country, Year)
HAVING COUNT(CONCAT(Country, Year)) > 1;

SELECT *
FROM (
	 SELECT Row_ID, 
	 CONCAT(Country, Year), 
	 ROW_NUMBER() OVER( PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) as Row_Num
	 FROM worldlifexpectancy) AS Row_table
WHERE Row_Num >1;

-- 2. Deleting the duplicates

DELETE FROM worldlifexpectancy
WHERE
	ROW_ID IN (
    SELECT Row_ID
FROM (
	 SELECT Row_ID, 
	 CONCAT(Country, Year), 
	 ROW_NUMBER() OVER( PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) as Row_Num
	 FROM worldlifexpectancy) AS Row_table
WHERE Row_Num >1);

-- 3. Looking for blanks in the 'Status' column

SELECT * 
FROM worldlifexpectancy
WHERE Status = '';

SELECT DISTINCT(STATUS)
FROM worldlifexpectancy
WHERE Status <> ''; 

SELECT DISTINCT(Country)
FROM worldlifexpectancy
WHERE Status = 'Developing';

-- 3.1. Updating the blanks with the proper 'Status' values.
-- Since we have two Distinct values for Status column we will update for both of them.

UPDATE worldlifexpectancy t1
JOIN worldlifexpectancy t2
  ON t1.Country = t2.Country
SET t1.Status = 'Developing'
WHERE t1.Status = ''
AND t2.Status <> ''
AND t2.Status = 'Developing';

UPDATE worldlifexpectancy t1
JOIN worldlifexpectancy t2
  ON t1.Country = t2.Country
SET t1.Status = 'Developed'
WHERE t1.Status = ''
AND t2.Status <> ''
AND t2.Status = 'Developed';

-- 4. Looking for blanks in the 'Lifeexpectancy' column

SELECT *
FROM worldlifexpectancy
WHERE Lifeexpectancy = '';

-- 4.1. Performing the inner joins to look for blanks 
-- In order to fill the blanks, we will take the average of rows above and below of the blanks value.

SELECT Country, Year, Lifeexpectancy
FROM worldlifexpectancy;

SELECT t1.Country, t1.Year, t1.Lifeexpectancy,
       t2.Country, t2.Year, t2.Lifeexpectancy,
       t3.Country, t3.Year, t3.Lifeexpectancy,
       ROUND((t2.Lifeexpectancy + t3.Lifeexpectancy)/2,1)
FROM worldlifexpectancy t1
JOIN worldlifexpectancy t2
   ON t1.Country = t2.Country
   -- Taking the below row of the blank value
   AND t1.Year = t2.Year - 1         
JOIN worldlifexpectancy t3
   ON t1.Country = t3.Country
   -- Taking the above row of the blank value
   AND t1.Year = t3.Year + 1        
WHERE t1.Lifeexpectancy = '';

-- 4.2. Updating the blank values with Average values

UPDATE worldlifexpectancy t1
JOIN worldlifexpectancy t2
   ON t1.Country = t2.Country
   AND t1.Year = t2.Year - 1
JOIN worldlifexpectancy t3
   ON t1.Country = t3.Country
   AND t1.Year = t3.Year + 1
SET t1.Lifeexpectancy = ROUND((t2.Lifeexpectancy + t3.Lifeexpectancy)/2,1)
WHERE t1.Lifeexpectancy = '';

-- Performing Exploratory Data Analysis (EDA) on World Life Expectancy Dataset

SELECT * 
FROM worldlifexpectancy;

-- 1. What is the Minimum and Maxium Life expectancy of the Countries?

SELECT Country, MIN(Lifeexpectancy), MAX(Lifeexpectancy)
FROM worldlifexpectancy
GROUP BY COUNTRY
HAVING MIN(Lifeexpectancy) <> 0
AND MAX(Lifeexpectancy) <> 0
ORDER BY COUNTRY DESC;

-- 2. By how many years the life expectancy has increased as per Countries in the last 15 years? 
 
SELECT Country, MIN(Lifeexpectancy), MAX(Lifeexpectancy),
ROUND(MAX(Lifeexpectancy)-MIN(Lifeexpectancy),1) AS Life_Increase_15_Years
FROM worldlifexpectancy
GROUP BY COUNTRY
HAVING MIN(Lifeexpectancy) <> 0
AND MAX(Lifeexpectancy) <>0
ORDER BY Life_Increase_15_Years DESC;

-- 3. What is the Average life expectancy for each year?

SELECT YEAR, ROUND(AVG(Lifeexpectancy),2)
FROM worldlifexpectancy
WHERE Lifeexpectancy <> 0
GROUP BY Year
ORDER BY Year;

# In the year 2007 the average life expectancy for the world was 66.75 years 
# which got increased by 4.87 years in 2022.

-- 4. What is the correlation between GDP and Life expectancy?

SELECT COUNTRY, ROUND(AVG(Lifeexpectancy),1) AS Life_Exp, ROUND(AVG(GDP),1) AS GDP
FROM worldlifexpectancy
GROUP BY COUNTRY
HAVING Life_Exp > 0
AND GDP > 0
ORDER BY GDP DESC;

# Higher the GDP of the Country higher is the life expectenancy.

-- 5. Considering 1500 as a midpoint for the GDP, looking at Countries with High vs Low GDP
--    and the effect of it on the life expectancy.      

SELECT
SUM(CASE WHEN GDP >= 1500 THEN 1 ELSE 0 END) High_GDP_COUNT,
AVG(CASE WHEN GDP >= 1500 THEN Lifeexpectancy ELSE NULL END) High_Lifeexpectancy,
SUM(CASE WHEN GDP <= 1500 THEN 1 ELSE 0 END) Low_GDP_COUNT,
AVG(CASE WHEN GDP <= 1500 THEN Lifeexpectancy ELSE NULL END) Low_Lifeexpectancy
FROM worldlifexpectancy;

# Low GDP Countries have 10 years less life expectancy than the countries with high GDP.

-- 6. Looking for Life Expectancy for Developed vs Developing Countries.

SELECT Status, ROUND(AVG(Lifeexpectancy),1)
FROM worldlifexpectancy
GROUP BY Status;

SELECT Status, COUNT(DISTINCT COUNTRY), ROUND(AVG(Lifeexpectancy),1)
FROM worldlifexpectancy
GROUP BY Status;

# Developed Countries life expectancy is higher than the developing Countires.

-- 7. Corelation between Life Expectancy and BMI of the Country?

SELECT COUNTRY,ROUND(AVG(Lifeexpectancy),1) AS Life_Exp, ROUND(AVG(BMI),1) AS BMI
FROM worldlifexpectancy
GROUP BY COUNTRY
HAVING Life_Exp > 0
AND BMI > 0
ORDER BY BMI ASC;

-- 8. Number of people dying each year in the Country having 'United' in their name?
 
SELECT Country, Year, Lifeexpectancy, AdultMortality,SUM(AdultMortality)
OVER(PARTITION BY Country ORDER BY Year) AS Rolling_Total
FROM worldlifexpectancy
WHERE Country LIKE '%United%';
