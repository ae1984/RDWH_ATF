create or replace force view dwh_risk.v_loan_fil_dt as
select t.refer_wh
       ,t.csln_fromdate
       ,t.dep_id
       ,a.longname as filial
from dwh_buffer.dm_loan_base t
left join dwh_buffer.c_dep a on a.id = t.dep_id;

