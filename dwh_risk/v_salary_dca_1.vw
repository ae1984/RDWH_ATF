create or replace force view dwh_risk.v_salary_dca_1 as
select /*+ parallel(32)*/
  t.mm
  ,t.bin
  ,t.contract_name
  ,t.iin_cl
  ,case when nvl(a.is_more_10prc,0) + nvl(a.is_2times,0) > 0 then 0 else 1 end is_stability_DCA
  ,case when nvl(t.is_delay_zp,0) + nvl(a.is_more_10prc,0) + nvl(a.is_2times,0) > 0 then 0 else 1 end is_stability_3
  ,a.is_amount_lag
  ,a.is_more_10prc
  ,a.is_2times
  ,t.is_delay_zp
  ,t.is_have_bin
  ,a.PD
  ,a.pd_lag
from V_SALARY_1 t
left join V_SALARY_DCA a on a.bin = t.bin and a.mm = t.mm
where t.mm between to_date('01.05.2015') and trunc(add_months(sysdate,0/*-1*/),'MM');

