create or replace force view dwh_risk.v_job_sched as
select
  t.LOG_ID
  ,t.owner||'.'||t.JOB_NAME as job
  ,t.STATUS
  ,EXTRACT(day from t.RUN_DURATION*24*60*60) as duration_sec
  ,TO_DATE (TO_CHAR(t.ACTUAL_START_DATE, 'DD.MM.YYYY HH24:MI:SS'), 'DD.MM.YYYY HH24:MI:SS') as startdt
  ,TO_DATE (TO_CHAR(t.LOG_DATE, 'DD.MM.YYYY HH24:MI:SS'), 'DD.MM.YYYY HH24:MI:SS') as finishdt
  ,t.ADDITIONAL_INFO
  , trunc(t.ACTUAL_START_DATE) AS ActualStart
  , trunc(t.LOG_DATE) AS ActualFinish
   , null as options
   , null as state
   , null as eventtype
   , null as location_id
   , null as  locationname
   , nvl(to_char(EXTRACT(day from t.RUN_DURATION*24*60*60))||'сек. ','в процессе...')||nvl(t.ADDITIONAL_INFO,'.') AS label
   ,case
       when t.STATUS = 'SUCCEEDED' then 10025880
       when t.STATUS = 'FAILED' then 6506495
       --when t.state = 'STOPPED' then 12632256
       else 65535
    end as  labelcolor

from ALL_SCHEDULER_JOB_RUN_DETAILS t
where t.LOG_DATE >= sysdate-14
;

