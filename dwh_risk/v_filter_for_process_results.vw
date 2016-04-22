create or replace force view dwh_risk.v_filter_for_process_results as
select t.process_guid from dwh_buffer.loan_request t
left join EXE_PROCESS_RESULTS a on a.process_guid = '{'||t.process_guid || '}'
where a.process_guid is null
      and t.src = 'SQL'
      and t.start_date is not null
      and t.finish_date is not null
      and t.process_guid not in (select process_guid from PROCESS_RESULTS_NOT_FOUND)
      /*and
      t.registration_number in
      (select t.REGISTRATION_NUMBER from V_XLS_H_EKZ_ALL_UNSEC_BAD t
      union all
      select t.REGISTRATION_NUMBER from V_H_DP_EKZ_ALL_UNSEC_p2_2_RES t)*/
      --and rownum <=200000
;

