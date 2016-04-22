create or replace force view dwh_risk.v_salary_dca_1_2 as
select /*+ parallel(8)*/
   add_months(t.mm,1) mm
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
   ,case when avg(t.is_more_10prc)+avg(t.is_2times) > 0 then 1 else 0 end as  is_2times_or_is_more_10prc
   ,trunc(avg(t.is_delay_zp) / 0.05) * 0.05   is_delay_zp_grp
   ,avg(a.is_less_zp_corp) is_less_zp_corp
   ,avg(a.is_less_zp_corp_usd) is_less_zp_corp_usd
   --,count(distinct t.iin_cl) as personal_count
   --,sum(t.is_stability) as stab_personal_count
   ,max(t.contract_name) cl_name_w4
   ,max(b.cli_name) cl_name_colvir
   ,max(b.vcc) vcc
   ,case when max(b.cnt)> 1 then 1 else 0 end as is_have_dublicate_client
   ,max(c.descr) as vcc_descr
   ,case when d.IIN is null then 0 else 1 end as is_have_loan
from V_SALARY_DCA_1 t
left join V_SALARY_1_CORP a on a.bin = t.bin and a.mm = t.mm
left join v_vcc_iin_client_20160125 b on b.iin = t.bin
left join XLS_H_VCC_DESCR c on c.vcc = b.vcc
left join V_IS_HAVE_CREDIT_FOR_MM d on d.IIN = t.bin and d.mm = t.mm
group by t.bin,d.IIN,/* t.contract_name ,*/ t.mm, t.is_have_bin
;

