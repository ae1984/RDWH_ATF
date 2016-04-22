create or replace force view dwh_risk.v_salary_1_corp as
select
  add_months(tt.mm,1) mm
  ,tt.bin
  ,case when nvl(lead(tt.sum_trans_amount) over(partition by tt.bin order by tt.mm),0) < tt.sum_trans_amount * 0.8 then 1 else 0 end as is_less_zp_corp
  ,case when nvl(lead(tt.sum_trans_amount_usd) over(partition by tt.bin order by tt.mm),0) < tt.sum_trans_amount_usd * 0.8 then 1 else 0 end as is_less_zp_corp_usd
from (
  select
     t.bin, t.mm, sum(t.sum_trans_amount) sum_trans_amount,sum(t.sum_trans_amount_usd) sum_trans_amount_usd
  from V_SALARY_1 t
  group by t.bin, t.mm
) tt;

