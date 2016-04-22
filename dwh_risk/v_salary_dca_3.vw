create or replace force view dwh_risk.v_salary_dca_3 as
select /*+ parallel(4) */ t."MM",t."BIN",t."STAB_INDX_DCA",t."STAB_INDX_GR_3",t."IS_HAVE_BIN",t."IIN",t."AMT",t."PD", a.pd as pd2 from
(
select
   t.MM, t.BIN, t.STAB_INDX_DCA, t.stab_indx_gr_3
   ,is_have_bin
   ,count (t.iin_cl) iin
   ,sum(t.amt) amt
   ,max(t.pd) as pd
from V_SALARY_DCA_2 t
group by t.MM, t.BIN, t.STAB_INDX_DCA, t.stab_indx_gr_3,t.is_have_bin
) t
left join DCA_MAX_IIN a on a.iin = t.BIN and trunc(a.rpt_date,'MM') = t.MM;

