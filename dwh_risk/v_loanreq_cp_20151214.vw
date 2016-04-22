create or replace force view dwh_risk.v_loanreq_cp_20151214 as
select /*+parallel(32)*/
   t.registration_number
   ,a.f53 as refer
   --,case when (select count(1) from dwh_buffer.loan_request z where z.registration_number=t.registration_number) > 1 then 1 else 0 end as is_more_1_req
   ,case when t.cnt > 1 then 1 else 0 end as is_more_1_req
   ,case when a.cnt > 1 then 1 else 0 end as is_more_1_loan
   ,case when a.f53 is null then 0 else 1 end is_have_cp
   ,t.dep_id,t.dep_name,t.initiator_code,t.verefeir_code,t.verefeir_name
from (
      select aa.*, count(1) over (partition by aa.registration_number) as cnt from dwh_buffer.loan_request aa
     )t
 join (
       select bb.*, count(1) over (partition by bb.f9) as cnt from v_cp_h bb where bb.report_dt = to_date('30.10.2015')
      ) a on a.f9 = t.registration_number --and a.report_dt = to_date('30.10.2015') --(select max(report_dt) from v_cp_h)
;

