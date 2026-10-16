# CareFlow Data Quality Summary

**Author:** Satyam | **Team:** Infotact Internship, Group 9
**Platform:** Google BigQuery | **Table:** `friendly-cubist-511618-b4.001.careflow`
**Dataset:** CareFlow Filtered Event Log, Emergency Department Sepsis Pathway (Synthetic Demo)

---

## 1. Overview

This report summarizes the data quality checks run on the CareFlow event log before it is used for process mining (PM4Py), dbt transformation, and Power BI reporting. All checks were written in SQL and run in Google BigQuery.

## 2. Dataset Profile

| Metric | Value |
|---|---|
| Total rows (events) | 9,855 |
| Total cases (patients) | 1,428 |
| Unique activities | 11 |
| Departments | 6 |
| Resources (staff) | 15 |
| Events per case | 6 to 9 (average about 6.9) |
| Case duration | 160 to 401 minutes (average about 253) |
| Event date range | 12 Sep 2026 to 10 Oct 2026 |

**Columns:** `case_id`, `event_index`, `activity`, `event_time_stamp`, `next_activity`, `elapsed_to_next_in_min`, `resource`, `department`, `status`

## 3. Checks Performed and Results

| # | Check | SQL query | Result |
|---|---|---|---|
| 1 | Data types of all columns | `INFORMATION_SCHEMA.COLUMNS` query | Reviewed (see note 1) |
| 2 | Row, case, activity, department and resource counts | Profile query | See section 2 |
| 3 | Missing values in every column | Missing values query | Only `next_activity` and `elapsed_to_next_in_min` have nulls (1,428 each) |
| 4 | Nulls only on the last event of each case | `last_events` CTE query | **0** unexpected nulls |
| 5 | Duplicate `case_id` + `event_index` | Duplicate events query | **0** duplicates |
| 6 | Event timestamps in correct order within a case | `LAG()` query | **0** out-of-order events |
| 7 | Negative or longer than 24 hour transitions | Transition time query | **0** records (maximum is 104 minutes) |
| 8 | Patient journey patterns | Journey query | Reviewed (see section 4) |

> Checks 3 to 7 were also cross-verified against the CSV file with Python. The results matched.

## 4. Key Findings

### 4.1 Nulls are expected, not errors
`next_activity` and `elapsed_to_next_in_min` are null in 1,428 rows. This equals the number of cases, because the last event of each case has no following activity. The check in section 3 (#4) confirms that no other row has a null.

### 4.2 No duplicates, no ordering problems
There are no duplicate `case_id` + `event_index` pairs and no fully duplicated rows. Within every case, `event_index` runs 1, 2, 3 ... with no gaps, and timestamps never go backwards.

### 4.3 Transition times are clean
Elapsed time between consecutive events ranges from 10 to 104 minutes (median 30). There are no negative values and no transition over 24 hours. The `next_activity` and elapsed time values also match the actual next row in each case.

### 4.4 Case paths
Cases follow one of four lengths:

| Events per case | Cases | Meaning |
|---|---|---|
| 6 | 685 | Standard pathway |
| 7 | 371 | Standard pathway with one extra step |
| 8 | 200 | Longer pathway (includes sub-specialist consult) |
| 9 | 172 | Includes a specimen rework loop |

How cases end:

| Final activity | Cases |
|---|---|
| Inpatient Ward Bed Handover | 819 |
| Discharge to Outpatient Care | 409 |
| Direct ICU Bed Transfer | 200 |

### 4.5 Rework loop
172 cases contain `Specimen Hemolysis / Re-draw Order`, so `Stat Blood Draw & Biomarkers` and `Central Laboratory Specimen Run` appear twice in those cases (the row counts are 1,600 each instead of 1,428). This is a real process pattern, not a data error. It should be passed to Sakshi as a candidate bottleneck for the process mining work.

## 5. Issues and Recommendations

| # | Issue | Recommendation |
|---|---|---|
| 1 | Original CSV column `elapsed_to_next _in_min` contains a space | Already renamed to `elapsed_to_next_in_min` in BigQuery. Use this name in all dbt models |
| 2 | `event_time_stamp` data type | Confirm it is `TIMESTAMP`, not `STRING`. If it is a string, cast it in dbt staging |
| 3 | `status` mixes several value types (`Completed`, `Administered`, `Rework Flagged`, `Sample Rejected`, ...) | Document the meaning of each value. Do not treat it as a simple success or failure flag |
| 4 | Repeated activities within one case (rework) | Process mining must allow loops. Do not de-duplicate by `case_id` + `activity` |
| 5 | Dataset is synthetic | Clean results are expected. Do not assume real-world data will be this clean |

## 6. Conclusion

The CareFlow event log passed all quality checks: no duplicates, no missing required values, no out-of-order timestamps, and no negative or abnormally long transitions. The only nulls are the expected end-of-case values. The data is reliable enough to move forward with dbt transformation, PM4Py process discovery, and Power BI reporting, provided the column name and timestamp data type are handled as noted above.

## 7. Files

| File | Purpose |
|---|---|
| `sql/03_duplicate_events.sql` | Duplicate event check |
| `sql/04_timestamp_validation.sql` | Timestamp order and missing timestamps |
| `sql/05_transition_times.sql` | Negative and over 24 hour transitions |
| `sql/06_null_checks.sql` | Null counts and last-event null check |
| `sql/07_data_types.sql` | Column data types |
| `README.md` | Project overview |
