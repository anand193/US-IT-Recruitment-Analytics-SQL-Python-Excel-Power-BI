CREATE DATABASE recruitment_analytics;
use recruitment_analytics;
show databases;

CREATE TABLE companies (
    company_id INT PRIMARY KEY,
    company_name VARCHAR(255),
    industry VARCHAR(100),
    company_size VARCHAR(50),
    hq_city VARCHAR(100)
);

select * from companies;
DESCRIBE companies;

CREATE TABLE candidates (
    candidate_id INT PRIMARY KEY,
    candidate_name VARCHAR(255),
    years_experience INT,
    current_city VARCHAR(100),
    top_skill_area VARCHAR(100),
    summary TEXT,
    experience_bucket VARCHAR(50)
);
describe candidates;

CREATE TABLE jobs (
    job_id INT PRIMARY KEY,
    company_id INT,
    posted_at DATETIME,
    title VARCHAR(255),
    role_family VARCHAR(100),
    level VARCHAR(50),
    location_type VARCHAR(50),
    employment_type VARCHAR(50),
    salary_low DECIMAL(12,2),
    salary_high DECIMAL(12,2),
    status VARCHAR(50),
    salary_midpoint DECIMAL(12,2),
    posted_date DATE,
    posted_month INT,
    posted_year INT,
    posted_month_year VARCHAR(7),
    salary_range INT,

    FOREIGN KEY (company_id)
        REFERENCES companies(company_id)
);
show tables;
CREATE TABLE applications (
    application_id INT PRIMARY KEY,
    job_id INT,
    candidate_id INT,
    applied_at DATETIME,
    source VARCHAR(100),
    stage VARCHAR(100),
    score DECIMAL(5,2),
    application_date DATE,
    application_month INT,
    application_year INT,
    application_month_year VARCHAR(7),

    FOREIGN KEY (job_id)
        REFERENCES jobs(job_id),

    FOREIGN KEY (candidate_id)
        REFERENCES candidates(candidate_id)
);

DESCRIBE applications;
SHOW CREATE TABLE applications;

CREATE TABLE interviews (
    interview_id INT PRIMARY KEY,
    application_id INT,
    round_name VARCHAR(100),
    scheduled_at DATETIME,
    result VARCHAR(100),

    FOREIGN KEY (application_id)
        REFERENCES applications(application_id)
);
DESCRIBE interviews;
CREATE TABLE offers (
    offer_id INT PRIMARY KEY,
    application_id INT,
    offered_at DATETIME,
    base_salary DECIMAL(12,2),
    accepted BOOLEAN,
    accepted_at DATETIME NULL,
    acceptance_status VARCHAR(50),

    FOREIGN KEY (application_id)
        REFERENCES applications(application_id)
);

DESCRIBE offers;

SHOW TABLES;

SHOW CREATE TABLE jobs;
SHOW CREATE TABLE applications;
SHOW CREATE TABLE offers;
select * from companies;

select * from companies;
SELECT COUNT(*) AS total_companies
FROM companies;
SELECT COUNT(*) AS invalid_company_ids
FROM jobs
WHERE company_id NOT IN (
    SELECT company_id
    FROM companies
);
SELECT COUNT(*) AS total_applications
FROM applications;

SELECT COUNT(*) AS invalid_job_ids
FROM applications
WHERE job_id NOT IN (
    SELECT job_id
    FROM jobs
);

SELECT COUNT(*) AS invalid_candidate_ids
FROM applications
WHERE candidate_id NOT IN (
    SELECT candidate_id
    FROM candidates
);
SELECT COUNT(*) AS total_interviews
FROM interviews;
SELECT COUNT(*) AS invalid_application_ids
FROM interviews
WHERE application_id NOT IN (
    SELECT application_id
    FROM applications
);
select * from offers;
SELECT accepted, COUNT(*) AS total
FROM offers
GROUP BY accepted;

describe offers;
TRUNCATE TABLE offers;
ALTER TABLE offers
MODIFY accepted TINYINT;
select * from offers;
select * from offers;
SELECT COUNT(*) AS total_offers
FROM offers;
DELETE FROM offers;
select * from offers;

SELECT COUNT(*) AS total_offers
FROM offers;

SELECT accepted, COUNT(*) AS total
FROM offers
GROUP BY accepted;

SELECT COUNT(*) AS invalid_accepted_dates
FROM offers
WHERE accepted = 0
AND accepted_at IS NOT NULL;

-- data validation in mysql
-- 1. Total offers
SELECT COUNT(*) AS total_offers
FROM offers;

-- 2. Accepted vs Not Accepted
SELECT accepted, COUNT(*) AS total
FROM offers
GROUP BY accepted;

-- 3. Check invalid accepted dates
SELECT COUNT(*) AS invalid_accepted_dates
FROM offers
WHERE accepted = 0
AND accepted_at IS NOT NULL;

-- Recruitment Funnel Analysis
-- How many candidates move through each stage of the recruitment funnel, and where are the biggest drop-offs?
SELECT 
    stage,
    COUNT(*) AS total_applications
FROM applications
GROUP BY stage
ORDER BY total_applications DESC;

-- Funnel conversion & drop-off
SELECT
    stage,
    COUNT(*) AS candidates,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_total
FROM applications
GROUP BY stage
ORDER BY
    FIELD(stage, 'applied', 'screened', 'interview', 'offer');
    
-- Interview → Offer → Acceptance
SELECT
    COUNT(DISTINCT i.application_id) AS interviewed,
    COUNT(DISTINCT o.application_id) AS offered,
    COUNT(DISTINCT CASE 
        WHEN o.accepted = 1 THEN o.application_id 
    END) AS accepted_offers
FROM interviews i
LEFT JOIN offers o
    ON i.application_id = o.application_id;

-- Finding:
-- Total interviewed applications: 3,570
-- Total applications receiving offers: 938
-- Total accepted offers: 699
-- Interview-to-offer conversion rate: 26.27%
-- Offer acceptance rate: 74.52%

-- Business Insight:
-- Only about 1 in 4 interviewed applications resulted in an offer,
-- indicating potential room to improve candidate selection and interview
-- effectiveness. However, nearly 3 out of 4 offers were accepted,
-- suggesting strong offer acceptance once candidates reach the offer stage.
--------------
-- Interview Outcome Analysis
-- What percentage of interviews are successful, unsuccessful, or have other outcomes?

SELECT
    result,
    COUNT(*) AS total_interviews
FROM interviews
GROUP BY result
ORDER BY total_interviews DESC;

-- Finding:
-- A total of 7,196 interviews were conducted.
-- 5,323 interviews (73.99%) resulted in a pass.
-- 1,155 interviews (16.05%) resulted in a fail.
-- 718 interviews (9.97%) were placed on hold.

-- Business Insight:
-- The high interview pass rate of 73.99% indicates that most candidates
-- reaching the interview stage meet the interview requirements.
-- However, 16.05% of interviews resulted in failure and 9.97% remained
-- on hold, representing potential areas for further investigation.

-- Q5 Interview Round Analysis
-- Which interview rounds have the highest number of candidates, and how do outcomes vary by round?

SELECT
    round_name,
    COUNT(*) AS total_interviews,
    SUM(CASE WHEN result = 'pass' THEN 1 ELSE 0 END) AS passed,
    SUM(CASE WHEN result = 'fail' THEN 1 ELSE 0 END) AS failed,
    SUM(CASE WHEN result = 'hold' THEN 1 ELSE 0 END) AS on_hold,
    ROUND(
        SUM(CASE WHEN result = 'pass' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
        2
    ) AS pass_rate
FROM interviews
GROUP BY round_name
ORDER BY pass_rate DESC;

-- Finding:
-- The Final interview round has the highest pass rate at 75.06%,
-- followed by Hiring Manager at 74.19%, Panel at 73.72%,
-- and Recruiter at 72.96%.
--
-- Business Insight:
-- Interview pass rates are relatively consistent across all rounds,
-- ranging from 72.96% to 75.06%. The Recruiter round has the lowest
-- pass rate, which may indicate an opportunity to review the initial
-- candidate screening process and improve candidate selection before
-- candidates progress to later interview stages.

-- Q6 — Recruitment Source Performance
-- Which candidate sourcing channels generate the most applications?


SELECT
    source,
    COUNT(*) AS total_applications,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS application_percentage
FROM applications
GROUP BY source
ORDER BY total_applications DESC;

-- Finding:
-- Job Board generated the highest number of applications with 7,094
-- applications (47.29% of total applications).
-- Referral generated 2,694 applications (17.96%), followed by
-- LinkedIn with 2,648 applications (17.65%).
-- Outbound and Recruiter sources generated 1,333 (8.89%) and
-- 1,231 (8.21%) applications respectively.
--
-- Business Insight:
-- Job Board is the largest candidate acquisition channel by volume.
-- However, application volume alone does not indicate source quality.
-- Source-level interview and offer conversion should be analyzed to
-- determine which channels produce the most effective candidates.

-- ============================================================
-- Q7. Recruitment Source Performance
-- ============================================================

SELECT
    a.source,
    COUNT(DISTINCT a.application_id) AS applications,
    COUNT(DISTINCT i.application_id) AS interviewed,
    COUNT(DISTINCT o.application_id) AS offered,

    ROUND(
        COUNT(DISTINCT i.application_id) * 100.0
        / COUNT(DISTINCT a.application_id),
        2
    ) AS interview_rate,

    ROUND(
        COUNT(DISTINCT o.application_id) * 100.0
        / COUNT(DISTINCT a.application_id),
        2
    ) AS offer_rate

FROM applications a

LEFT JOIN interviews i
    ON a.application_id = i.application_id

LEFT JOIN offers o
    ON a.application_id = o.application_id

GROUP BY a.source
ORDER BY interview_rate DESC;

-- Finding:
-- Job Board generated the highest application volume (7,094)
-- and had the highest interview rate at 24.87%.
-- Recruiter had the highest offer rate at 6.82%, despite generating
-- only 1,231 applications.
-- Outbound had the lowest interview rate at 21.08%, but its offer
-- rate of 6.30% was higher than LinkedIn (6.00%) and Referral (5.64%).
--
-- Business Insight:
-- Job Board is the strongest source by application volume and
-- interview conversion. However, Recruiter sourcing appears more
-- effective at generating offers relative to application volume.
-- This suggests that source effectiveness should be evaluated using
-- conversion rates in addition to application volume.

-- Q8 — Offer Acceptance by Source
-- Which sourcing channels produce candidates who actually accept the offers?

SELECT
    a.source,
    COUNT(DISTINCT o.offer_id) AS total_offers,
    COUNT(DISTINCT CASE
        WHEN o.accepted = 1 THEN o.offer_id
    END) AS accepted_offers,
    ROUND(
        COUNT(DISTINCT CASE
            WHEN o.accepted = 1 THEN o.offer_id
        END) * 100.0
        / COUNT(DISTINCT o.offer_id),
        2
    ) AS acceptance_rate
FROM applications a
JOIN offers o
    ON a.application_id = o.application_id
GROUP BY a.source
ORDER BY acceptance_rate DESC;

-- Finding:
-- Recruiter sourcing had the highest offer acceptance rate at 82.14%,
-- followed by Referral at 77.63% and Job Board at 75.16%.
-- LinkedIn had the lowest acceptance rate at 67.92%.
-- Job Board generated the highest number of accepted offers (345)
-- because it also generated the highest number of applications and offers.
--
-- Business Insight:
-- Recruiter and Referral channels appear to generate candidates
-- with stronger offer acceptance rates. However, Recruiter has a
-- relatively small offer volume compared with Job Board.
-- Therefore, recruitment source performance should be evaluated
-- using both conversion rates and absolute hiring volume.

-- ============================================================
-- Q9. Offer Salary Analysis
-- ============================================================

SELECT
    COUNT(*) AS total_offers,
    ROUND(AVG(base_salary), 2) AS avg_offer_salary,
    MIN(base_salary) AS min_offer_salary,
    MAX(base_salary) AS max_offer_salary,
    ROUND(AVG(
        CASE
            WHEN accepted = 1 THEN base_salary
        END
    ), 2) AS avg_accepted_offer_salary,
    ROUND(AVG(
        CASE
            WHEN accepted = 0 THEN base_salary
        END
    ), 2) AS avg_rejected_offer_salary
FROM offers;

-- Finding:
-- A total of 938 offers were made with an average offer salary
-- of $129,879.69.
-- Offer salaries ranged from $61,321 to $240,017.
-- The average salary for accepted offers was $130,569.57,
-- compared with $127,862.00 for offers that were not accepted.
--
-- Business Insight:
-- Accepted offers had an average salary approximately $2,708 higher
-- than non-accepted offers. However, the difference alone does not
-- establish that salary caused candidates to accept offers.
-- Additional analysis by job level, role, location, and experience
-- is required to understand the factors influencing offer acceptance.

-- ============================================================
-- Q10. Average Salary by Job Level
-- ============================================================

SELECT
    j.level,
    COUNT(DISTINCT o.offer_id) AS total_offers,
    ROUND(AVG(o.base_salary), 2) AS avg_offer_salary,
    MIN(o.base_salary) AS min_offer_salary,
    MAX(o.base_salary) AS max_offer_salary
FROM offers o
JOIN applications a
    ON o.application_id = a.application_id
JOIN jobs j
    ON a.job_id = j.job_id
GROUP BY j.level
ORDER BY avg_offer_salary DESC;

-- Finding:
-- Lead roles had the highest average offer salary at $174,179.50,
-- followed by Senior ($142,708.47), Mid ($117,037.76), and
-- Junior ($84,080.31).
-- The data shows a clear increase in average compensation as
-- job seniority increases.
--
-- Business Insight:
-- Compensation is strongly aligned with job seniority, with Lead
-- roles commanding the highest average salaries and Junior roles
-- the lowest. This information can help recruitment and management
-- teams benchmark compensation and evaluate salary expectations
-- across different career levels.

-- ============================================================
-- Q11. Hiring Demand by Role Family
-- ============================================================

SELECT
    role_family,
    COUNT(*) AS total_jobs,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS job_percentage
FROM jobs
GROUP BY role_family
ORDER BY total_jobs DESC;

-- Finding:
-- Operations has the highest hiring demand with 991 job postings,
-- representing 49.55% of all 2,000 job postings.
-- Engineering accounts for 425 postings (21.25%), while Data
-- accounts for 302 postings (15.10%).
-- Product, Customer Success, and Sales have comparatively lower
-- hiring volumes.
--
-- Business Insight:
-- Operations represents the largest hiring demand in the dataset,
-- while Engineering and Data are the next largest role families.
-- Recruitment teams can use this information to prioritize sourcing
-- efforts and allocate recruitment resources toward high-demand
-- role families.

-- ============================================================
-- Q12. Candidate Demand by Role Family
-- ============================================================

SELECT
    j.role_family,
    COUNT(DISTINCT j.job_id) AS total_jobs,
    COUNT(a.application_id) AS total_applications,
    ROUND(
        COUNT(a.application_id) * 1.0 /
        COUNT(DISTINCT j.job_id),
        2
    ) AS applications_per_job
FROM jobs j
LEFT JOIN applications a
    ON j.job_id = a.job_id
GROUP BY j.role_family
ORDER BY applications_per_job DESC;

-- Finding:
-- Product roles have the highest candidate competition with
-- 7.81 applications per job, followed by Data (7.59) and
-- Operations (7.51).
-- Operations has the highest number of job openings (991),
-- but its applications per job are not the highest.
--
-- Business Insight:
-- High hiring demand does not necessarily mean high candidate
-- competition. Product and Data roles attract relatively high
-- application volumes compared with the number of available
-- positions. Recruitment teams may need to prioritize sourcing
-- capacity differently based on both job demand and candidate
-- availability.

-- ============================================================
-- Q13. Hiring Demand by Company
-- ============================================================

SELECT
    c.company_name,
    COUNT(j.job_id) AS total_jobs
FROM companies c
JOIN jobs j
    ON c.company_id = j.company_id
GROUP BY c.company_id, c.company_name
ORDER BY total_jobs DESC
LIMIT 10;


-- Finding:
-- The highest-volume companies generated 12–13 job postings each.
-- Wood, Tran and Cooper, Lewis, Kennedy and Santana, and
-- Harris-Walters had the highest hiring demand with 13 job postings each.
--
-- Business Insight:
-- Companies with consistently high job-posting volumes may require
-- greater recruitment capacity and closer account management.
-- Identifying high-demand clients can help the staffing company
-- prioritize sourcing resources and maintain service levels.

-- Q14 — Company Hiring Demand + Candidate Interest
SELECT
    c.company_name,
    COUNT(DISTINCT j.job_id) AS total_jobs,
    COUNT(a.application_id) AS total_applications,
    ROUND(
        COUNT(a.application_id) * 1.0 /
        COUNT(DISTINCT j.job_id),
        2
    ) AS applications_per_job
FROM companies c
JOIN jobs j
    ON c.company_id = j.company_id
LEFT JOIN applications a
    ON j.job_id = a.job_id
GROUP BY c.company_id, c.company_name
ORDER BY total_jobs DESC, applications_per_job DESC
LIMIT 10;

-- Finding:
-- Burton Ltd has the highest candidate interest among the
-- top hiring companies, with 8.25 applications per job.
-- Daniels, Adkins and Brown follows with 8.17 applications
-- per job, while Morton-Chase has the lowest rate at 6.58.
--
-- Lewis, Kennedy and Santana has the highest hiring demand
-- among the listed companies with 13 job postings and
-- receives 7.62 applications per job.
--
-- Business Insight:
-- Hiring demand and candidate interest are not necessarily
-- proportional across companies.
-- Companies with high job volumes but lower applications per
-- job may require additional sourcing efforts, while companies
-- with high applications per job may have a stronger candidate
-- pipeline.
--
-- Recruitment teams can use this analysis to prioritize
-- sourcing resources toward high-demand clients with relatively
-- lower candidate availability.

-- Next: Q15 — Company Recruitment Performance

SELECT
    c.company_name,
    COUNT(DISTINCT j.job_id) AS total_jobs,
    COUNT(DISTINCT a.application_id) AS applications,
    COUNT(DISTINCT i.application_id) AS interviewed,
    COUNT(DISTINCT o.application_id) AS offered,

    ROUND(
        COUNT(DISTINCT i.application_id) * 100.0 /
        COUNT(DISTINCT a.application_id),
        2
    ) AS interview_rate,

    ROUND(
        COUNT(DISTINCT o.application_id) * 100.0 /
        COUNT(DISTINCT a.application_id),
        2
    ) AS offer_rate

FROM companies c
JOIN jobs j
    ON c.company_id = j.company_id

LEFT JOIN applications a
    ON j.job_id = a.job_id

LEFT JOIN interviews i
    ON a.application_id = i.application_id

LEFT JOIN offers o
    ON a.application_id = o.application_id

GROUP BY c.company_id, c.company_name
HAVING applications > 0
ORDER BY interview_rate DESC
LIMIT 10;

-- Finding:
-- Blake and Sons has the highest interview rate among the
-- listed companies at 57.14%, but it generated only 7 applications
-- and no offers.
--
-- Rodriguez-Johnson generated 23 applications, 10 interviews,
-- and 5 offers, resulting in the highest offer rate among the
-- listed companies at 21.74%.
--
-- Hoffman, Baker and Richards and Alvarez, Joseph and West
-- both achieved a 50.00% interview rate and a 12.50% offer rate.
--
-- Business Insight:
-- Interview rate alone is not sufficient to evaluate client-level
-- recruitment performance. Both candidate volume and downstream
-- conversion should be considered.
--
-- Companies with strong offer conversion and reasonable application
-- volume may represent more efficient recruitment opportunities,
-- while companies with high application volume but lower conversion
-- may require process or candidate-quality investigation.

-- Q16 — High-Volume Clients & Offer Conversion

SELECT
    c.company_name,
    COUNT(DISTINCT j.job_id) AS total_jobs,
    COUNT(DISTINCT a.application_id) AS applications,
    COUNT(DISTINCT i.application_id) AS interviewed,
    COUNT(DISTINCT o.application_id) AS offered,

    ROUND(
        COUNT(DISTINCT i.application_id) * 100.0 /
        COUNT(DISTINCT a.application_id),
        2
    ) AS interview_rate,

    ROUND(
        COUNT(DISTINCT o.application_id) * 100.0 /
        COUNT(DISTINCT a.application_id),
        2
    ) AS offer_rate

FROM companies c
JOIN jobs j
    ON c.company_id = j.company_id

LEFT JOIN applications a
    ON j.job_id = a.job_id

LEFT JOIN interviews i
    ON a.application_id = i.application_id

LEFT JOIN offers o
    ON a.application_id = o.application_id

GROUP BY c.company_id, c.company_name

HAVING applications >= 30

ORDER BY offer_rate DESC
LIMIT 10;

-- Finding:
-- Stewart Ltd generated 69 applications, 25 interviews, and
-- 11 offers, resulting in the highest offer rate among the
-- listed high-volume clients at 15.94%.
--
-- Duran, Obrien and Gibbs and Suarez, Shields and Hill also
-- demonstrated strong offer conversion rates of 15.63% and
-- 15.15% respectively.
--
-- Smith-Bowen generated the highest application volume with
-- 76 applications, but its offer rate was 13.16%.
-- Garner-Thornton had the lowest interview rate at 23.68%.
--
-- Business Insight:
-- High application volume does not necessarily translate into
-- higher recruitment efficiency. Client performance should be
-- evaluated using both recruitment volume and conversion rates.
--
-- High-volume clients with weaker conversion rates may require
-- investigation into candidate quality, job requirements,
-- screening effectiveness, or interview processes.


-- ============================================================
-- Q17. Job Level Recruitment Performance
-- ============================================================
SELECT
    j.level,
    COUNT(DISTINCT a.application_id) AS applications,
    COUNT(DISTINCT i.application_id) AS interviewed,
    COUNT(DISTINCT o.application_id) AS offered,

    ROUND(
        COUNT(DISTINCT i.application_id) * 100.0 /
        COUNT(DISTINCT a.application_id),
        2
    ) AS interview_rate,

    ROUND(
        COUNT(DISTINCT o.application_id) * 100.0 /
        COUNT(DISTINCT a.application_id),
        2
    ) AS offer_rate

FROM jobs j

JOIN applications a
    ON j.job_id = a.job_id

LEFT JOIN interviews i
    ON a.application_id = i.application_id

LEFT JOIN offers o
    ON a.application_id = o.application_id

GROUP BY j.level
ORDER BY interview_rate DESC;

-- Finding:
-- Mid-level roles generated the highest interview rate at 24.06%,
-- followed by Junior at 23.71%, Senior at 23.70%, and Lead at 23.44%.
--
-- Lead roles generated the highest offer rate at 6.63%, closely
-- followed by Mid-level roles at 6.60%.
-- Senior roles had the lowest offer rate at 5.80%.
--
-- Interview conversion was highly consistent across job levels,
-- with only a 0.62 percentage-point difference between the highest
-- and lowest interview rates.
--
-- Business Insight:
-- Job level does not appear to create a major difference in
-- application-to-interview conversion within this dataset.
-- However, the slightly lower offer rate for Senior roles may
-- warrant further investigation into candidate quality, job
-- requirements, or hiring criteria.
--
-- Recruitment teams should therefore evaluate job-level performance
-- using both conversion rates and application volume rather than
-- assuming that seniority alone determines recruitment efficiency.

-- Q18 — Role Family Performance
-- Which role families convert applications into interviews and offers most effectively?
SELECT
    j.role_family,
    COUNT(DISTINCT a.application_id) AS applications,
    COUNT(DISTINCT i.application_id) AS interviewed,
    COUNT(DISTINCT o.application_id) AS offered,

    ROUND(
        COUNT(DISTINCT i.application_id) * 100.0 /
        COUNT(DISTINCT a.application_id),
        2
    ) AS interview_rate,

    ROUND(
        COUNT(DISTINCT o.application_id) * 100.0 /
        COUNT(DISTINCT a.application_id),
        2
    ) AS offer_rate

FROM jobs j

JOIN applications a
    ON j.job_id = a.job_id

LEFT JOIN interviews i
    ON a.application_id = i.application_id

LEFT JOIN offers o
    ON a.application_id = o.application_id

GROUP BY j.role_family
ORDER BY offer_rate DESC;

-- Finding:
-- Operations generated the highest application volume with 7,443
-- applications and also produced the highest number of offers (487).
-- Its interview rate was 24.28% and offer rate was 6.54%.
--
-- Sales had the highest interview rate at 26.56%, although it had
-- a relatively small application volume of 561.
--
-- Customer Success had the lowest interview rate at 22.56% and
-- the lowest offer rate at 5.15%.
--
-- Data generated substantial application volume (2,291), but had
-- a relatively lower interview rate of 22.61% and offer rate of 5.63%.
--
-- Business Insight:
-- Operations represents the largest and one of the strongest
-- recruitment pipelines in terms of both volume and conversion.
-- Sales demonstrates strong interview conversion but should be
-- evaluated alongside its smaller application volume.
--
-- Data and Customer Success show relatively lower downstream
-- conversion rates and may warrant further investigation into
-- candidate quality, screening effectiveness, or job requirements.

-- Q19 — Location Type Performance

SELECT
    j.location_type,
    COUNT(DISTINCT a.application_id) AS applications,
    COUNT(DISTINCT i.application_id) AS interviewed,
    COUNT(DISTINCT o.application_id) AS offered,

    ROUND(
        COUNT(DISTINCT i.application_id) * 100.0 /
        COUNT(DISTINCT a.application_id),
        2
    ) AS interview_rate,

    ROUND(
        COUNT(DISTINCT o.application_id) * 100.0 /
        COUNT(DISTINCT a.application_id),
        2
    ) AS offer_rate

FROM jobs j

JOIN applications a
    ON j.job_id = a.job_id

LEFT JOIN interviews i
    ON a.application_id = i.application_id

LEFT JOIN offers o
    ON a.application_id = o.application_id

GROUP BY j.location_type
ORDER BY offer_rate DESC;

-- Finding:
-- Remote positions generated the highest application volume
-- with 6,548 applications, followed by Hybrid with 5,172
-- and Onsite with 3,280.
--
-- Onsite positions had the highest interview rate at 24.51%,
-- while Remote positions had the lowest at 23.37%.
--
-- Offer rates were almost identical across all location types:
-- 6.28% for Onsite and 6.25% for both Hybrid and Remote.
--
-- Business Insight:
-- Location type does not appear to have a significant impact
-- on application-to-offer conversion in this dataset.
-- However, Remote positions attract substantially more applications,
-- suggesting stronger candidate interest in remote opportunities.


-- Q20 — Candidate Experience vs Recruitment Outcome

-- ============================================================
-- Q20. Candidate Experience vs Recruitment Outcome
-- ============================================================

SELECT
    c.experience_bucket,
    COUNT(DISTINCT a.application_id) AS applications,
    COUNT(DISTINCT i.application_id) AS interviewed,
    COUNT(DISTINCT o.application_id) AS offered,

    ROUND(
        COUNT(DISTINCT i.application_id) * 100.0 /
        COUNT(DISTINCT a.application_id),
        2
    ) AS interview_rate,

    ROUND(
        COUNT(DISTINCT o.application_id) * 100.0 /
        COUNT(DISTINCT a.application_id),
        2
    ) AS offer_rate

FROM candidates c

JOIN applications a
    ON c.candidate_id = a.candidate_id

LEFT JOIN interviews i
    ON a.application_id = i.application_id

LEFT JOIN offers o
    ON a.application_id = o.application_id

GROUP BY c.experience_bucket
ORDER BY interview_rate DESC;

-- Finding:
-- Candidates with 0-2 years of experience had the highest
-- interview rate at 24.84% and the highest offer rate at 6.67%.
--
-- Candidates with 10+ years of experience generated the highest
-- application volume with 5,918 applications.
--
-- Candidates with 6-10 years of experience had the lowest
-- interview rate at 22.97%.
--
-- Offer rates were relatively consistent across experience groups,
-- ranging from 6.12% to 6.67%.
--
-- Business Insight:
-- Candidate experience does not appear to have a major impact
-- on offer conversion in this dataset.
-- Although the 0-2 years group has slightly higher conversion rates,
-- the differences are relatively small.
--
-- Recruitment teams should therefore evaluate experience together
-- with other factors such as candidate score, role family, job level,
-- and location rather than using experience alone to predict
-- recruitment outcomes.


-- ============================================================
-- Q21. Candidate Score vs Recruitment Outcome
-- ============================================================

SELECT
    CASE
        WHEN a.score < 0.60 THEN 'Low Score'
        WHEN a.score < 0.80 THEN 'Medium Score'
        ELSE 'High Score'
    END AS score_group,

    COUNT(DISTINCT a.application_id) AS applications,
    COUNT(DISTINCT i.application_id) AS interviewed,
    COUNT(DISTINCT o.application_id) AS offered,

    ROUND(
        COUNT(DISTINCT i.application_id) * 100.0 /
        COUNT(DISTINCT a.application_id),
        2
    ) AS interview_rate,

    ROUND(
        COUNT(DISTINCT o.application_id) * 100.0 /
        COUNT(DISTINCT a.application_id),
        2
    ) AS offer_rate

FROM applications a

LEFT JOIN interviews i
    ON a.application_id = i.application_id

LEFT JOIN offers o
    ON a.application_id = o.application_id

GROUP BY score_group
ORDER BY
    FIELD(score_group, 'Low Score', 'Medium Score', 'High Score');
    
    -- Finding:
-- High-score candidates had the highest offer rate at 6.50%,
-- followed by Medium-score candidates at 6.20% and Low-score
-- candidates at 6.11%.
--
-- Low-score candidates had the highest interview rate at 24.20%,
-- while Medium and High-score candidates both had an interview
-- rate of 23.55%.
--
-- Interview rates were relatively consistent across all score
-- groups, ranging from 23.55% to 24.20%.
--
-- Business Insight:
-- Candidate score appears to have a slightly stronger relationship
-- with offer conversion than with interview conversion.
-- However, the differences are relatively small, so candidate score
-- should not be used as the sole factor for recruitment decisions.
--
-- Recruitment teams should evaluate candidate score alongside
-- experience, role requirements, job level, and other candidate
-- attributes when assessing recruitment effectiveness.

-- ============================================================
-- Q22. Monthly Recruitment Trend
-- ============================================================

SELECT
    application_month_year,
    COUNT(DISTINCT application_id) AS applications
FROM applications
GROUP BY application_month_year
ORDER BY application_month_year;

-- Finding:
-- Application volume peaked in August 2025 with 855 applications.
-- Following the August peak, application volume generally declined,
-- reaching 440 applications in December 2025 and 261 in January 2026.
--
-- February 2026 recorded only 29 applications. This appears to be
-- a partial month and should not be directly compared with complete
-- months when evaluating recruitment trends.
--
-- Business Insight:
-- Recruitment activity shows a decline after the August 2025 peak.
-- Management should investigate whether this decline reflects
-- changes in hiring demand, sourcing activity, seasonality, or
-- dataset coverage.
--
-- Data Quality Note:
-- February 2026 appears to contain incomplete data. Therefore,
-- February should be excluded from full-month trend comparisons
-- unless the dataset is confirmed to contain the complete month.

-- ============================================================
-- Q23. Recruitment Time-to-Hire Analysis
-- ============================================================

SELECT
    COUNT(DISTINCT o.application_id) AS total_offers,

    ROUND(
        AVG(
            DATEDIFF(
                DATE(o.offered_at),
                DATE(a.applied_at)
            )
        ),
        2
    ) AS avg_days_to_offer,

    MIN(
        DATEDIFF(
            DATE(o.offered_at),
            DATE(a.applied_at)
        )
    ) AS min_days_to_offer,

    MAX(
        DATEDIFF(
            DATE(o.offered_at),
            DATE(a.applied_at)
        )
    ) AS max_days_to_offer

FROM applications a
JOIN offers o
    ON a.application_id = o.application_id;
    
-- Finding:
-- A total of 938 offers were analyzed.
-- The average time from application to offer was 28.70 days.
-- The fastest application-to-offer cycle was 14 days,
-- while the longest was 44 days.
--
-- Business Insight:
-- The average application-to-offer cycle of approximately
-- 29 days provides a useful baseline for recruitment efficiency.
-- Recruitment teams can use this metric to monitor process
-- speed and identify opportunities to reduce hiring cycle time.
--
-- Data Limitation:
-- The dataset does not contain a candidate joining or placement date.
-- Therefore, this metric represents Application-to-Offer Time
-- rather than true Time-to-Hire.