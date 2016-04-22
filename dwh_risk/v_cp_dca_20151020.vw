create or replace force view dwh_risk.v_cp_dca_20151020 as
select /*+parallel(8)*/

/*
grant select on v_cp_dca_20151020 to PROCESS_RISK;
надо будет подправить вьюху эту, чтоб грузануть все отчетные мес€ца начина€ с августа 2014.
и добавить туда PD_60_6(ever DPD60+ на 6 мес€це от отчетной даты), PD_90_6 и PD_90_12
*/
  t.report_dt
  ,t.F53 REFER
  ,t.F6 CLI_CODE
  ,t.F82 DPD_MAX
  ,t.F13+t.F14 debt
  ,t.F25 SUM_PROVIZ
  ,t.F88 PD
  ,t.F87 LGD
  ,T.F90 LLP
  --,a.PD  PD_DCA
  ,lead(t.report_dt,6) over (partition by t.F53 order by t.report_dt ) report_dt_lead6
  ,lead(t.F82,6) over (partition by t.F53 order by t.report_dt ) DPD_lead6
  ,lead(t.report_dt,12) over (partition by t.F53 order by t.report_dt ) report_dt_lead12
  ,lead(t.F82,12) over (partition by t.F53 order by t.report_dt ) DPD_lead12
  ,case when lead(t.F82,6) over (partition by t.F53 order by t.report_dt ) >=60 then 1 else 0 end PD_60_6
  ,case when lead(t.F82,6) over (partition by t.F53 order by t.report_dt ) >=90 then 1 else 0 end PD_90_6
  ,case when lead(t.F82,12) over (partition by t.F53 order by t.report_dt ) >=90 then 1 else 0 end PD_90_12

from v_cp_h t
  /*left join (select distinct *
             from DWH.DCA_TRGT_PD
             where pd_type = 1
                   and trunc(rpt_date, 'MM') >=trunc(to_date('01.05.2015'), 'MM')
            ) a on a.code = t.F6*/
where trunc(t.report_dt, 'MM') >= trunc(to_date('01.01.2014'), 'MM')
;
grant select on DWH_RISK.V_CP_DCA_20151020 to PROCESS_RISK;


