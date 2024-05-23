USE Hr;

SELECT * 
FROM hr_data;

SELECT termdate 
FROM hr_data
ORDER BY termdate DESC;

UPDATE hr_data
SET termdate = FORMAT(CONVERT(DATETIME, LEFT(termdate,19), 120), 'yyyy-MM-dd');

ALTER TABLE hr_data
ADD New_termdate DATE;

-- copy converted time values from termdate to new_termdate
UPDATE hr_data
SET New_termdate = CASE
 WHEN termdate IS NOT NULL AND ISDATE(termdate) = 1 THEN CAST (termdate AS DATETIME) ELSE NULL END;

-- create new column 'age'
ALTER TABLE hr_data
ADD age nvarchar(50);

-- populate new column with age
UPDATE hr_data
SET age = DATEDIFF(YEAR, birthdate, GETDATE());

-- Age distribution in the company
SELECT
  MIN(age) AS Youngest,
  MAX(age) AS Oldest
FROM hr_data;

--Age group by gender
SELECT age_group,
COUNT(*) AS Count
FROM
(SELECT 
 CASE 
  WHEN age >= 31 AND age <= 40 THEN '31 TO 40'
  WHEN age >= 41 AND age <= 50 THEN '41 TO 50'
  WHEN age >= 51 AND age <= 60 THEN '51 TO 60'
  ELSE '60+'
  END AS age_group
FROM hr_data
WHERE New_termdate IS NULL
) AS Subquery
GROUP BY age_group
ORDER BY age_group;

-- age group by gender
SELECT age_group, gender,
COUNT(*) AS Count
FROM
(SELECT 
 CASE 
  WHEN age >= 31 AND age <= 40 THEN '31 TO 40'
  WHEN age >= 41 AND age <= 50 THEN '41 TO 50'
  WHEN age >= 51 AND age <= 60 THEN '51 TO 60'
  ELSE '60+'
  END AS age_group, gender
FROM hr_data
WHERE New_termdate IS NULL
) AS Subquery
GROUP BY age_group, gender
ORDER BY age_group, gender;

--What's the gender breakdown in the comapany?
SELECT gender,
COUNT(gender) AS Count
FROM hr_data
WHERE New_termdate IS NULL
GROUP BY gender
ORDER BY gender;

--How does gender vary across departments and job titles ?
SELECT department, gender,
COUNT(gender) AS Count
FROM hr_data
WHERE New_termdate IS NULL
GROUP BY department, gender
ORDER BY department, gender;

--job titles
SELECT department,jobtitle, gender,
COUNT(gender) AS Count
FROM hr_data
WHERE New_termdate IS NULL
GROUP BY department,jobtitle, gender
ORDER BY department,jobtitle, gender;

-- What's the race distribution in the comapany ?
SELECT race,
COUNT(race) AS Count
FROM hr_data
WHERE New_termdate IS NULL
GROUP BY race
ORDER BY count DESC;

--What's the average length of employment in the company ?
SELECT
AVG(DATEDIFF(year, hire_date, New_termdate)) AS tenure
FROM hr_data
WHERE New_termdate IS NOT NULL AND New_termdate <= GETDATE();

--Which department has the highest turnover rate ?
-- step-1.get total count
-- step-2.get terminated count
-- step-3.terminated count/total count
SELECT
 department,
 total_count,
 terminated_count,
 round(CAST(terminated_count AS FLOAT)/total_count, 2) AS turnover_rate
FROM 
   (SELECT
   department,
   count(*) AS total_count,
   SUM(CASE
        WHEN new_termdate IS NOT NULL AND new_termdate <= getdate()
		THEN 1 ELSE 0
		END
   ) AS terminated_count
  FROM hr_data
  GROUP BY department
  ) AS Subquery
ORDER BY turnover_rate DESC

--What is the tenure distribution for each department?
SELECT department,
AVG(DATEDIFF(year, hire_date, New_termdate)) AS tenure
FROM hr_data
WHERE New_termdate IS NOT NULL AND New_termdate <= GETDATE()
GROUP BY department
ORDER BY tenure DESC;

--How many employees work remotely for each department?
SELECT location,
COUNT(*) AS count
FROM hr_data
WHERE New_termdate IS NULL
GROUP BY location;

--What's the distribution of employees across different states?
SELECT location_state,
COUNT(*) AS count
FROM hr_data
WHERE New_termdate IS NULL
GROUP BY location_state
ORDER BY count DESC;

--How are job titles distributed in the company?
SELECT jobtitle,
COUNT(*) AS count
FROM hr_data
WHERE New_termdate IS NULL
GROUP BY jobtitle
ORDER BY count DESC;

--How have employee hire counts varied over time?
-- step-1.calculate hire
-- step-2.calculate terminations
-- step-3.(hires-terminations)/hires percent hire change

SELECT
hire_year,
hires,
terminations,
hires - terminations AS net_change,
(round(CAST(hires - terminations AS FLOAT) / hires, 2)) *100 AS percent_hire_change
FROM  
  (SELECT
  YEAR(hire_date) AS hire_year,
  count(*) as hires,
  SUM(CASE WHEN New_termdate IS NOT NULL AND New_termdate <= GETDATE() THEN 1 ELSE 0 END) terminations
  FROM hr_data
  GROUP BY year(hire_date)
  ) AS subquery
ORDER BY percent_hire_change ASC;

