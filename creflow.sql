SELECT *
FROM `friendly-cubist-511618-b4.001.careflow`
LIMIT 1000;

-----data type
SELECT column_name, data_type
FROM `friendly-cubist-511618-b4.001.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'careflow'
ORDER BY ordinal_position;

-----Count rows, cases, and activities,department, resources
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT case_id) AS total_cases,
  COUNT(DISTINCT activity) AS unique_activities,
  COUNT(DISTINCT department) AS departments,
  COUNT(DISTINCT resource) AS resources
FROM `friendly-cubist-511618-b4.001.careflow`;



-----Check missing values

SELECT
  COUNTIF(case_id IS NULL) AS missing_case_id,
  COUNTIF(event_index IS NULL) AS missing_event_index,
  COUNTIF(activity IS NULL) AS missing_activity,
  COUNTIF(event_time_stamp IS NULL) AS missing_timestamp,
  COUNTIF(next_activity IS NULL) AS missing_next_activity,
  COUNTIF(elapsed_to_next_in_min IS NULL) AS missing_elapsed_time,
  COUNTIF(resource IS NULL) AS missing_resource,
  COUNTIF(department IS NULL) AS missing_department,
  COUNTIF(status IS NULL) AS missing_status
FROM `friendly-cubist-511618-b4.001.careflow`;

-----Duplicate event checks reviewed

SELECT
  case_id,
  event_index,
  COUNT(*) AS duplicate_count
FROM `friendly-cubist-511618-b4.001.careflow`
GROUP BY case_id, event_index
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


------Validate patient event order
WITH ordered_events AS (
  SELECT
    case_id,
    event_index,
    activity,
    event_time_stamp,
    LAG(event_time_stamp) OVER (
      PARTITION BY case_id
      ORDER BY event_index
    ) AS previous_timestamp
  FROM `friendly-cubist-511618-b4.001.careflow`
)
SELECT *
FROM ordered_events
WHERE previous_timestamp IS NOT NULL
  AND event_time_stamp < previous_timestamp
ORDER BY case_id, event_index;


------Investigate unusual transition times
SELECT
  case_id,
  event_index,
  activity,
  next_activity,
  elapsed_to_next_in_min
FROM `friendly-cubist-511618-b4.001.careflow`
WHERE elapsed_to_next_in_min < 0
   OR elapsed_to_next_in_min > 1440
ORDER BY elapsed_to_next_in_min DESC;




------Check patient journey patterns

SELECT
  case_id,
  COUNT(*) AS total_events,
  COUNT(DISTINCT activity) AS unique_activities,
  MIN(event_time_stamp) AS first_event,
  MAX(event_time_stamp) AS last_event
FROM `friendly-cubist-511618-b4.001.careflow`
GROUP BY case_id
ORDER BY total_events DESC
LIMIT 20;

----Nulls check
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT case_id) AS total_cases,
  COUNTIF(case_id IS NULL) AS null_case_id,
  COUNTIF(event_index IS NULL) AS null_event_index,
  COUNTIF(activity IS NULL) AS null_activity,
  COUNTIF(event_time_stamp IS NULL) AS null_timestamp,
  COUNTIF(next_activity IS NULL) AS null_next_activity,
  COUNTIF(resource IS NULL) AS null_resource,
  COUNTIF(department IS NULL) AS null_department,
  COUNTIF(status IS NULL) AS null_status
FROM `friendly-cubist-511618-b4.001.careflow`;

---Check that the nulls only appear on the last event of each case
WITH last_events AS (
  SELECT case_id, MAX(event_index) AS last_idx
  FROM `friendly-cubist-511618-b4.001.careflow`
  GROUP BY case_id
)
SELECT COUNT(*) AS unexpected_null_next_activity
FROM `friendly-cubist-511618-b4.001.careflow` t
JOIN last_events l USING (case_id)
WHERE t.next_activity IS NULL
  AND t.event_index != l.last_idx;
