create or replace force view dwh_risk.v_filter_for_scoringrbplogs as
select distinct t.process_guid from dwh_buffer.loan_request t
left join EXE_ScoringRBPLogs a on upper(a.process_guid) = t.process_guid
where a.process_guid is null
      and t.src = 'SQL'
      and t.start_date is not null
      and t.finish_date is not null
      /*and
      t.registration_number in
      (select t.REGISTRATION_NUMBER from V_XLS_H_EKZ_ALL_UNSEC_BAD t
      union all
      select t.REGISTRATION_NUMBER from V_H_DP_EKZ_ALL_UNSEC_p2_2_RES t)*/
      and rownum <=200000;

