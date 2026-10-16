# CareFlow Data Quality Analysis

## Project Overview
This project focuses on checking the quality and consistency of CareFlow event data using Google BigQuery and SQL.

## Dataset Information
- **Platform:** Google BigQuery
- **Table:** `friendly-cubist-511618-b4.001.careflow`
- **Purpose:** Validate event records, timestamps, and transition times.

## Data Quality Checks

### 1. Duplicate Event Validation
**File:** `03_duplicate_events.sql`

Checks for duplicate combinations of `case_id` and `event_index`.

### 2. Timestamp Validation
**File:** `04_timestamp_validation.sql`

Checks whether event timestamps follow the correct sequence within each case and identifies missing timestamps.

### 3. Transition Time Validation
**File:** `05_transition_times.sql`

Checks for negative transition times and transitions longer than 24 hours. Missing transition times are also counted.

## Results
Record the actual results returned by BigQuery after running each query. An empty issue-results table may indicate that no records matched the query's conditions.

## Tools Used
- Google BigQuery
- SQL
- Visual Studio Code
- Git and GitHub

## Conclusion
These SQL checks help assess the reliability of CareFlow event data before further analysis and reporting. Final conclusions should be based on the verified query results.