create or replace force view dwh_risk.v_company_salary_20151015_2 as
select
       t."CONTRACT_NAME",t."BIN",t."TYPE_COMPANY",t."MM",t."DT",t."TRANS_AMOUNT",t."CNT"
       ,max(t.trans_amount)over (partition by t.bin, t.mm) as max_trans_amount_mm
       ,case when max(t.trans_amount)over (partition by t.bin, t.mm) = t.trans_amount then 1 else 0 end is_zp
from (
select
     t.contract_name
     ,t.bin
     ,t.type_company
     ,t.mm
     ,t.dt
     ,sum(t.trans_amount) trans_amount
     ,sum(cnt) cnt

from V_SALARY t
group by
     t.contract_name
     ,t.bin
     ,t.type_company
     ,t.mm
     ,t.dt
) t;

