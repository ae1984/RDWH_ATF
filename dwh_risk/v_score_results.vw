create or replace force view dwh_risk.v_score_results as
select trim(t1.regnumber) regnumber, max(t1.pd) pd, max(t2.pd_cc) pd_cc, max(t2.pd_tenor) pd_tenor
from score_validation t1
left join score_validation_details t2 on trim(t1.regnumber)=trim(t2.regnumber) group by trim(t1.regnumber);

