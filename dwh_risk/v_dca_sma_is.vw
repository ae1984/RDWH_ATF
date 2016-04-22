create or replace force view dwh_risk.v_dca_sma_is as
select
   x.fil_code
  ,x.code
  ,x.name
  --,x.pd_type
  ,x.month
  ,x.year
  ,x.rpt_date
  ,x.pd
  ,x.pd_lag
  ,x.is_more_10prc
  ,x.is_2times
  ,avg(a.pd) as SMA_PD
from
(
select
    z.fil_code
   ,z.code
   ,z.name
   ,z.pd_type
   ,z.month
   ,z.year
   ,z.rpt_date
   ,z.pd
   ,lag(z.pd ignore nulls) over (partition by z.code order by z.rpt_date) as pd_lag
   ,case when z.pd > 0.1 then 1 else 0 end as is_more_10prc
   ,case when (z.pd/lag(z.pd ignore nulls) over (partition by z.code order by z.rpt_date)) >=2 then 1 else 0 end as is_2times
/*   ,(select avg(pd) from (select distinct code,rpt_date,pd from DWH.DCA_TRGT_PD where pd_type=1)
     where code = z.code and rpt_date<=z.rpt_date
    ) as SMA_PD*/
from
(select distinct
   v.*
   ,t.pd_type
   ,t.month
   ,t.year
   ,t.rpt_date
   ,t.pd
from  DWH.DCA_TRGT_PD t
   left join (select max(v.fil_code) fil_code, v.code, v.name from dwh.DCA_SRC_BM1 v group by v.code,v.name) v on v.code=t.code
where t.pd_type=1 --and v.code = 10
) z
) x
   left join (select distinct code,rpt_date,pd from DWH.DCA_TRGT_PD where pd_type=1) a on a.code = x.code and a.rpt_date <= x.rpt_date
group by
   x.fil_code
  ,x.code
  ,x.name
  --,x.pd_type
  ,x.month
  ,x.year
  ,x.rpt_date
  ,x.pd
  ,x.pd_lag
  ,x.is_more_10prc
  ,x.is_2times
;

