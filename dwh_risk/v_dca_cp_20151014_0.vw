create or replace force view dwh_risk.v_dca_cp_20151014_0 as
select t.rpt_date,
       t.code,
       t.name,
       t.pd,
       t.pd_lag,
       t.is_more_10prc,
       t.is_2times,
       round(t.pd*100,2) as pd_prc,
       round(t.pd*100) as pd_prc0,
       case
          when round(t.pd*100) between 0 and 10 then   '0-10'
          when round(t.pd*100) between 11 and 20 then  '11-20'
          when round(t.pd*100) between 21 and 30 then  '21-30'
          when round(t.pd*100) between 31 and 40 then  '31-40'
          when round(t.pd*100) between 41 and 50 then  '41-50'
          when round(t.pd*100) between 51 and 60 then  '51-60'
          when round(t.pd*100) between 61 and 70 then  '61-70'
          when round(t.pd*100) between 71 and 80 then  '71-80'
          when round(t.pd*100) between 81 and 90 then  '81-90'
          when round(t.pd*100) between 91 and 100 then '91-100'
       end  as pd_prc_step10,
       case
          when round(t.pd*100) between 0 and 5 then    '0-5'
          when round(t.pd*100) between 6 and 10 then   '6-10'
          when round(t.pd*100) between 11 and 15 then  '11-15'
          when round(t.pd*100) between 16 and 20 then  '16-20'
          when round(t.pd*100) between 21 and 25 then  '21-25'
          when round(t.pd*100) between 26 and 30 then  '26-30'
          when round(t.pd*100) between 31 and 35 then  '31-35'
          when round(t.pd*100) between 36 and 40 then  '36-40'
          when round(t.pd*100) between 41 and 45 then  '41-45'
          when round(t.pd*100) between 46 and 50 then  '46-50'
          when round(t.pd*100) between 51 and 55 then  '51-55'
          when round(t.pd*100) between 56 and 60 then  '56-60'
          when round(t.pd*100) between 61 and 65 then  '61-65'
          when round(t.pd*100) between 66 and 70 then  '66-70'
          when round(t.pd*100) between 71 and 75 then  '71-75'
          when round(t.pd*100) between 76 and 80 then  '76-80'
          when round(t.pd*100) between 81 and 85 then  '81-85'
          when round(t.pd*100) between 86 and 90 then  '86-90'
          when round(t.pd*100) between 91 and 95 then  '91-95'
          when round(t.pd*100) between 96 and 100 then '96-100'
       end  as pd_prc_step5,
       c.F5,
       min(a.REPORT_DT) REPORT_DT_M1,
       max(a.F82) DPD_M1,
       sum(a.F13) OD_M1,
       sum(a.F14) OVRD_OD_M1,
       sum(a.F13) + sum(a.F14) OD_OVRDOD_M1,
       min(b.REPORT_DT) REPORT_DT_M2,
       max(b.F82) DPD_M2,
       sum(b.F13) OD_M2,
       sum(b.F14) OVRD_OD_M2,
       sum(b.F13) + sum(a.F14) OD_OVRDOD_M2,

       min(c.REPORT_DT) REPORT_DT_M0,
       max(c.F82) DPD_M0,
       sum(c.F13) OD_M0,
       sum(c.F14) OVRD_OD_M0,
       sum(c.F13) + sum(c.F14) OD_OVRDOD_M0,

       case when c.F5 is null then 0 else 1 end as is_avaible_CP,
       case when (nvl(max(a.F82),0)-nvl(max(c.F82),0))>40 or (nvl(max(b.F82),0)-nvl(max(a.F82),0))>40 then 1 else 0 end as is_err
from v_h_dca_sma_20151014 t
  left join V_CP_H a on trunc(a.REPORT_DT, 'MM') = trunc(add_months(t.rpt_date,1), 'MM') and a.F6 = t.code
  left join V_CP_H b on trunc(b.REPORT_DT, 'MM') = trunc(add_months(t.rpt_date,2), 'MM') and b.F6 = t.code
  left join V_CP_H c on trunc(c.REPORT_DT, 'MM') = trunc(t.rpt_date, 'MM') and c.F6 = t.code
group by t.rpt_date,
       t.code,
       t.name,
       t.pd,
       c.F5,
       t.pd_lag,
       t.is_more_10prc,
       t.is_2times;

