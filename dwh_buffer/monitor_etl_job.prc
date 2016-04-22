create or replace procedure dwh_buffer.MONITOR_ETL_JOB is
    check_session integer;
    check_status integer;
    check_error integer;
    i number;
BEGIN
    select count(*) into i from Etl_Actions_Log t 
    where trunc(t.updated) = trunc(sysdate) and t.action_name = 'FINISH_ETL_RUN' and t.state = 'COMPLETED'; 
        
    select count(*) into check_session  from v$session s where status='ACTIVE' and username='DWH_BUFFER' and s.ACTION = 'ETL_JOB';
    select count(*) into check_status  from USER_SCHEDULER_JOBS t where t.job_name = 'ETL_JOB'  and t.state = 'RUNNING';
    if check_session<1 and check_status<1 and i <=0  then 
       select count(*) into check_error from ETL_ACTIONS_LOG where trunc(created) = trunc(sysdate) and state  in ('FAILED');
        if check_error <= 20 then
            dbms_scheduler.run_job(job_name => 'ETL_JOB' ,use_current_session => FALSE);---run job
        end if;
    end if;
end MONITOR_ETL_JOB;
/

