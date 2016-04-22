create or replace force view dwh_risk.v_salary_dca_2_1_0 as
select /*+ parallel(32) */
        t."MM",t."BIN",t."IS_HAVE_BIN",t."STAB_INDX_DCA",t."STAB_INDX_GR_DCA",t."STAB_INDX_3",t."STAB_INDX_GR_3",t."PD",t."IIN_CL",t."AMT"
       ,max(c.OVRD_MAIN) OVRD_MAIN
       ,max(c.ovrd_prc) ovrd_prc
       ,case when greatest(nvl(max(c.OVRD_MAIN),0),nvl(max(c.ovrd_prc),0)) >30 then 1 else 0 end as is_OVRD_30p
from V_SALARY_DCA_2 t
left join dwh_buffer.dm_cif_base a on a.iin = t.iin_cl
left join dwh_buffer.dm_loan_base b on b.cli_id = a.id
left join CREDIT_PORTFOLIO3 c on c.refer_wh = b.refer_wh and c.dt = t.MM
group by t.MM
         ,t.BIN
         ,t.IS_HAVE_BIN
         ,t.STAB_INDX_DCA
         ,t.STAB_INDX_GR_DCA
         ,t.STAB_INDX_3
         ,t.STAB_INDX_GR_3
         ,t.pd
         ,t.iin_cl
         ,t.amt;

