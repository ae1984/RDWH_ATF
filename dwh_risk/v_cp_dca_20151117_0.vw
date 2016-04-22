create or replace force view dwh_risk.v_cp_dca_20151117_0 as
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
  ,t.f73 Outstanding
  ,t.F91 IFRS_interest_LLP
  ,t.F92 LLP_total
  ,t.F93 LLP_prc
  ,t.F94 Current_coverage
  ,t.F95 CLASS_
  ,t.F96 ISL
  ,t.F97 LLP_OD
  ,t.F98 LLP_prcprc
  ,t.F89 LDP
  ,a.PD  PD_DCA
  ,lead(t.report_dt,6) over (partition by t.F53 order by t.report_dt ) report_dt_lead6
  ,lead(t.F82,6) over (partition by t.F53 order by t.report_dt ) DPD_lead6
  ,lead(t.report_dt,12) over (partition by t.F53 order by t.report_dt ) report_dt_lead12
  ,lead(t.F82,12) over (partition by t.F53 order by t.report_dt ) DPD_lead12
  ,case when lead(t.F82,3) over (partition by t.F53 order by t.report_dt ) >=60 then 1 else 0 end PD_60_3
  ,case when lead(t.F82,6) over (partition by t.F53 order by t.report_dt ) >=60 then 1 else 0 end PD_60_6
  ,case when lead(t.F82,6) over (partition by t.F53 order by t.report_dt ) >=90 then 1 else 0 end PD_90_6
  ,case when lead(t.F82,12) over (partition by t.F53 order by t.report_dt ) >=90 then 1 else 0 end PD_90_12
  ,b."REFER_WH",b."DT",b."SUP_PERC_CUR",b."SUP_PERC_EQU",b."DEBT_DEA_CUR",b."DEBT_DEA_EQU",b."OVRD_MAIN_CUR",b."OVRD_MAIN_EQU",b."INTEREST_RATE",b."OVRD_PRC_DEBT_B_CUR",b."OVRD_PRC_DEBT_B_EQU",b."OVRD_MAIN",b."OVRD_PRC",b."WR_PD_CUR",b."WR_PD_EQU"
  ,t.f75 as Type_of_business
  ,t.f39 as VCC
  ,c.short_vcc
  ,case when upper(nvl(t.f35,'-')) in ('N','T','T2','T6','-') then 0 else 1 end is_restruct
  ,case when c.short_vcc in ('corp','SNT') then 1 else 0 end is_corp
  ,case when c.short_vcc in ('sme') then 1 else 0 end is_sme
from (select * from V_CP_H /*where f75 in ('корп','мсб')*/) t
  left join DCA_MAX_CLI a on a.code = t.F6 and trunc(a.rpt_date, 'MM') = trunc(t.report_dt, 'MM')
  left join CREDIT_PORTFOLIO3 b on b.refer_wh = t.F53 and b.dt = trunc(t.report_dt, 'MM')
  left join XLS_H_VCC_DESCR_20151204 c on replace(c.vcc_code,'.','') = replace(t.f39,'.','')
where trunc(t.report_dt, 'MM') >= trunc(to_date('01.01.2014'), 'MM');

