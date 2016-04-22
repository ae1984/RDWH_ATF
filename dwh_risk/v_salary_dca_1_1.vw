create or replace force view dwh_risk.v_salary_dca_1_1 as
select /*+ parallel(8)*/
   t.mm
   ,t.bin
   --,t.contract_name
   ,t.is_have_bin
   ,avg(t.is_stability_DCA) as stab_indx_DCA
   ,trunc(avg(t.is_stability_DCA) / 0.05) * 0.05 stab_indx_gr_DCA
   ,avg(t.is_stability_3) as stab_indx_3
   ,trunc(avg(t.is_stability_3) / 0.05) * 0.05 stab_indx_gr_3
   ,trunc(avg(t.is_delay_zp) / 0.05) * 0.05 delay_zp_index
   ,case when trunc(avg(t.is_stability_3) / 0.05) * 0.05 > 0.5 then 1 else 0 end as is_more50prc_stab
   ,case when trunc(avg(t.is_delay_zp) / 0.05) * 0.05 > 0.5 then 1 else 0 end as is_more50prc_delay_zp
   ,max(t.PD) as pd
   ,avg(t.is_more_10prc) is_more_10prc
   ,avg(t.is_2times) is_2times
   ,trunc(avg(t.is_delay_zp) / 0.05) * 0.05   is_delay_zp_grp
   ,avg(a.is_less_zp_corp) is_less_zp_corp
   --,count(distinct t.iin_cl) as personal_count
   --,sum(t.is_stability) as stab_personal_count
   ,max(t.contract_name) contract_name
from V_SALARY_DCA_1 t
left join V_SALARY_1_CORP a on a.bin = t.bin and a.mm = t.mm
group by t.bin,/* t.contract_name ,*/ t.mm, t.is_have_bin
;

