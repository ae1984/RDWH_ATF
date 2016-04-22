create or replace force view dwh_risk.v_salary_dca_2 as
select /*+parallel(32) */
   z."MM",z."BIN",z."IS_HAVE_BIN",z."STAB_INDX_DCA",z."STAB_INDX_GR_DCA",z."STAB_INDX_3",z."STAB_INDX_GR_3"
   ,z.pd
   ,a.iin_cl
   ,a.amt
   ,z.is_more50prc_stab
   ,z.is_more50prc_delay_zp
   ,z.delay_zp_index
from (
select
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
   --,count(distinct t.iin_cl) as personal_count
   --,sum(t.is_stability) as stab_personal_count
from V_SALARY_DCA_1 t
group by t.bin,/* t.contract_name ,*/ t.mm, t.is_have_bin
) z
left join V_SALARY_MM a on a.mm = z.mm and a.bin = z.bin
;

