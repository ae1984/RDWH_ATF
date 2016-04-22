create or replace force view dwh_risk.v_company_salary_20151015 as
select
  a.contract_name
  ,a.bin
  ,a.type_company
  ,a.mm
  ,a.dt_grp
  ,a.trans_amount
  ,lag(trans_amount) over(partition by a.contract_name,a.mm  order by a.mm) as trans_amount_lag
  ,lead(trans_amount) over(partition by a.contract_name,a.mm  order by a.mm) as trans_amount_lead
  ,case when a.trans_amount >= nvl(lag(trans_amount) over(partition by a.contract_name,a.mm  order by a.mm),
                                   nvl(lead(trans_amount) over(partition by a.contract_name,a.mm  order by a.mm),0)) then 1 else 0 end as is_max
  ,a.cnt
  ,a.dt_avg
  ,lag(dt_avg) over(partition by a.contract_name,a.dt_grp  order by a.mm) as dt_avg_lag
  ,a.dt_avg-lag(dt_avg) over(partition by a.contract_name,a.dt_grp  order by a.mm) as day_diff
  ,case when a.dt_avg-lag(dt_avg) over(partition by a.contract_name,a.dt_grp  order by a.mm) > 41 then 1 else 0 end as is_more10day
from
(
  select
     t.contract_name
     ,t.bin
     ,t.type_company
     ,t.mm
     ,t.dt_grp
     ,sum(t.trans_amount) trans_amount
     ,sum(cnt) cnt
     ,trunc(min(t.dt)+((max(t.dt) - min(t.dt)) /2)) as dt_avg
  from V_SALARY t
  group by
     t.contract_name
     ,t.bin
     ,t.type_company
     ,t.mm
     ,t.dt_grp
) a;

