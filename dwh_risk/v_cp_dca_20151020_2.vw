create or replace force view dwh_risk.v_cp_dca_20151020_2 as
select /*+ parallel(16)*/
       a.code CLI_CODE_DCA,
       t.F53 REFER,
       t.F6 CLI_CODE,
       t.F82 DPD_MAX,
       t.F13 + t.F14 debt,
       t.F25 SUM_PROVIZ,
       t.F88 PD,
       t.F87 LGD,
       T.F90 LLP,
       a.PD PD_DCA
from (select distinct *
          from DWH.DCA_TRGT_PD
         where pd_type = 1
           and trunc(rpt_date, 'MM') = trunc(to_date('01.08.2015'), 'MM')) a
  join (select *
          from v_cp_h
         where trunc(report_dt, 'MM') = trunc(to_date('01.08.2015'), 'MM')) t
    on t.F6 = a.code;

