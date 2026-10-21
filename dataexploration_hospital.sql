-- FOR each doctor how many distinct patients


SELECT doctorid,count(*)
FROM
(SELECT  DISTINCT doctorid,patientid
FROM patient_visits
)
GROUP BY doctorid
ORDER BY COUNT(*) DESC;

-- revenue split by each payment method along with total visits

SELECT paymentmethod, ROUND(SUM(billamount),2) as revenue,COUNT(*) As total_visits
FROM patient_visits p 
INNER JOIN dim_paymentmethod pm
	ON p.paymentmethodid = pm.paymentmethodid
GROUP BY paymentmethod;

-- categorize patient into age group and calculate avg bill amount( assume age at time of visit based on visit date)
WITH age_cat as
(
SELECT 
CASE 
WHEN (visitdate - dob)/365.24 < 18 THEN '0-17'   -- add .24 to account for leap year which occurs once every 4 years
WHEN (visitdate - dob)/365.24 <= 35 THEN '18-35'
WHEN (visitdate - dob)/365.24 <=55 THEN '36-55'
ELSE '56+'
END as age_category,
billamount
FROM dim_patient_clean pc
INNER JOIN patient_visits pv
ON pc.patient_id = pv.patientid)

SELECT age_category,ROUND(AVG(billamount),2),COUNT(*)
FROM age_cat
GROUP BY age_category;


-- total revenue and number of visits for each department

SELECT
	dc.department_name,
	ROUND(SUM(billamount),2) as total_revenue,
	COUNT(*) as no_of_visits
FROM patient_visits pv
INNER JOIN dim_department_clean dc
ON dc.department_id = pv.departmentid
GROUP BY dc.department_name
ORDER BY total_revenue DESC;

-- rank departments based on total revenue in each department category
SELECT
	department_category,
	dc.department_name,
	ROUND(SUM(billamount),2) as total_revenue,
	COUNT(*) as no_of_visits,
	RANK() OVER(partition by department_category ORDER BY SUM(billamount) DESC )
FROM patient_visits pv
INNER JOIN dim_department_clean dc
ON dc.department_id = pv.departmentid
GROUP BY dc.department_name,department_category;

-- each department find avg satisfaction score and avg wait time
SELECT
	dc.department_name,ROUND(AVG(satisfactionscore),2) as  avg_satisfaction_score,ROUND(AVG(waittimeminutes),2) as avg_waittime
FROM patient_visits pv
INNER JOIN dim_department_clean dc
ON dc.department_id = pv.departmentid
GROUP BY dc.department_name;

-- compare total number of hospital visits on weekdays vs weekends
SELECT 
CASE WHEN EXTRACT(DOW FROM visitdate) in (1,2,3,4,5) THEN 'weekday'
ELSE 'weekend'
END as day_of_week,COUNT(*)
FROM patient_visits
GROUP BY 
CASE WHEN EXTRACT(DOW FROM visitdate) in (1,2,3,4,5) THEN 'weekday'
ELSE 'weekend'
END;

-- for each month calculate total visits and a running cumulative total of visits
WITH cte AS
(SELECT 
	to_char(visitdate,'yyyy-mm') as year_month,COUNT(*) as no_of_visits
FROM patient_visits
GROUP BY to_char(visitdate,'yyyy-mm')
)
SELECT *,SUM(no_of_visits) OVER (ORDER BY year_month ) as running_total
FROM cte;

-- doctors with highest avg satisfaction score with minimum of 100 visits
with cte_satisfy AS
(
SELECT 
	doctorid,
	AVG(satisfactionscore) as  avg_score,
	COUNT(*) as no_of_visits,
	RANK() OVER (order by AVG(satisfactionscore) desc) as rnk
FROM patient_visits pv
GROUP BY doctorid
HAVING COUNT(*)>100
)
SELECT *
FROM cte_satisfy
WHERE rnk = 1;

-- Identify most commmonlyu prescribed treatment for each diagnosis
SELECT *
FROM
(
SELECT diagnosisname,treatmentname,COUNT(*),RANK() OVER (PARTITION BY diagnosisname ORDER BY COUNT(*) DESC) rnk
FROM dim_diagnosis d
INNER JOIN patient_visits p
ON d.diagnosisid = p.diagnosisid
INNER JOIN dim_treatment t
ON p.treatmentid = t.treatmentid
GROUP BY diagnosisname,treatmentname
)
WHERE rnk = 1
