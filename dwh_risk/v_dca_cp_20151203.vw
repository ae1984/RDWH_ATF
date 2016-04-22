create or replace force view dwh_risk.v_dca_cp_20151203 as
select x.fil_code,
       x.code,
       x.name,
       x.rpt_date,
       x.pd,
       x.pd_lag,
       x.is_more_10prc,
       x.is_2times,
       case when x.is_more_10prc + x.is_2times > 0 then 1 else 0 end as is_more_10prc_or_2times,
       avg(a.pd) as AVG_6,
       avg(b.pd) as AVG_3,
       min(c.REPORT_DT) REPORT_DT,
       max(c.F82) DPD,
       sum(c.F13) OD,
       sum(c.F14) OVRD_OD,
       sum(c.F13) + sum(c.F14) OD_OVRDOD,
       case when min(c.REPORT_DT) is null then 0 else 1 end as is_avaible_CP
from (select z.fil_code,
             z.code,
             z.name,
             z.rpt_date,
             z.pd,
             lag(z.pd ignore nulls) over(partition by z.code order by z.rpt_date) as pd_lag,
             case when z.pd > 0.1 then 1 else 0 end as is_more_10prc,
             case when (z.pd / lag(z.pd ignore nulls) over(partition by z.code order by z.rpt_date)) >= 2 then 1 else 0 end as is_2times
      from (select distinct v.*, t.rpt_date,t.pd
            from DCA_MAX_CLI t
            left join (select max(v.fil_code) fil_code, v.code, v.name from dwh.DCA_SRC_BM1 v group by v.code, v.name) v on v.code = t.code
           ) z
      ) x
  left join DCA_MAX_CLI a on a.code = x.code and a.rpt_date <= x.rpt_date and a.rpt_date >= add_months(x.rpt_date, -6)
  left join DCA_MAX_CLI b on b.code = x.code and b.rpt_date <= x.rpt_date and b.rpt_date >= add_months(x.rpt_date, -3)
  left join V_CP_H c on trunc(c.REPORT_DT, 'MM') = trunc(x.rpt_date, 'MM') and c.F6 = x.code
group by x.fil_code,
         x.code,
         x.name,
         x.rpt_date,
         x.pd,
         x.pd_lag,
         x.is_more_10prc,
         x.is_2times;

