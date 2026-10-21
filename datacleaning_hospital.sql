-- DATA CLEANING (Patient table)

CREATE TABLE if not exists dim_patient_clean  (
patient_id VARCHAR(20) PRIMARY KEY,
full_name VARCHAR(100),
gender VARCHAR(10),
dob DATE,
city VARCHAR(50),
state VARCHAR(50),
country VARCHAR(50)
);

INSERT INTO dim_patient_clean(patient_id,full_name,gender,dob,city,state,country)
SELECT 
	p.patientid,
	INITCAP(REGEXP_REPLACE(TRIM(firstname || ' ' || lastname),'\s+',' ','g')),
	CASE 
	WHEN gender in ('M','Male') THEN 'Male'
	WHEN gender in ('F','Female') THEN 'Female'
	ELSE 'Unknown'
	END AS gender,
	p.dob,
	SPLIT_PART(citystatecountry,',',1) AS city,
	SPLIT_PART(citystatecountry,',',2) AS state,
	SPLIT_PART(citystatecountry,',',3) AS country
FROM dim_patient p
WHERE p.firstname is not null;


-- DATA CLEANING (Department Table)
CREATE TABLE if not exists dim_department_clean(
department_id VARCHAR(20) PRIMARY KEY,
department_name VARCHAR(100),
department_category VARCHAR(100)
)
INSERT INTO dim_department_clean(department_id,department_name,department_category)
SELECT 
	departmentid ,
	specialization,
	departmentcategory
FROM dim_department 
WHERE departmentcategory is not null

-- DATA CLEANING (Patients Visits Table)
CREATE TABLE if not exists patient_visits (
  VisitID varchar(20) PRIMARY KEY,
  PatientID varchar(20),
  DoctorID varchar(20),
  DepartmentID varchar(20),
  DiagnosisID varchar(20),
  TreatmentID varchar(20),
  PaymentMethodID varchar(20),
  VisitDate date,
  VisitTime time,
  DischargeDate date,
  BillAmount decimal(18,2),
  InsuranceAmount decimal(18,2),
  SatisfactionScore integer,
  WaitTimeMinutes integer,
FOREIGN KEY (PatientID) REFERENCES dim_patient_clean(patient_id),
FOREIGN KEY (DoctorID) REFERENCES Dim_Doctor(DoctorID),
FOREIGN KEY (DepartmentID) REFERENCES dim_department_clean(department_id),
FOREIGN KEY (DiagnosisID) REFERENCES Dim_Diagnosis(DiagnosisID),
FOREIGN KEY (TreatmentID) REFERENCES Dim_Treatment(TreatmentID),
FOREIGN KEY (PaymentMethodID) REFERENCES Dim_PaymentMethod(PaymentMethodID)
);
INSERT INTO patient_visits  					--adding all columns so dont have to mention which columns we are inserting into as long as data is inserted in the same order as the table)
 SELECT * FROM patientvisits_2020_2021
  UNION ALL
  SELECT * FROM patientvisits_2022_2023
 UNION ALL 
  SELECT * FROM patientvisits_2024
  UNION ALL
   SELECT * FROM patientvisits_2025

SELECT *
FROM patient_visits 
WHERE DATE(visitdate) > '2024-01-12'

