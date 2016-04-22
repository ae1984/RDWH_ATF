create or replace force view dwh_risk.v_h_dca_sma_20151014 as
select x.load_id,
       x.fil_code,
       x.code,
       x.name,
       x.pd_type,
       x.month,
       x.year,
       x.rpt_date,
       x.pd,
       x.pd_lag,
       x.is_more_10prc,
       x.is_2times,
       avg(a.pd) as AVG_6,
       avg(b.pd) as AVG_3,
       decode(x.var1, null, 0, 1) have_base_model,
       decode(x.var2, null, 0, 1) have_loan_model,
       decode(x.var3, null, 0, 1) have_rests_model,
       decode(x.var4, null, 0, 1) have_moves_model

  from (select z.load_id,
               z.fil_code,
               z.code,
               z.name,
               z.pd_type,
               z.month,
               z.year,
               z.rpt_date,
               z.pd,
               z.var1,
               z.var2,
               z.var3,
               z.var4,
               lag(z.pd ignore nulls) over(partition by z.code order by z.rpt_date) as pd_lag,
               case
                 when z.pd > 0.1 then
                  1
                 else
                  0
               end as is_more_10prc,
               case
                 when (z.pd / lag(z.pd ignore nulls)
                       over(partition by z.code order by z.rpt_date)) >= 2 then
                  1
                 else
                  0
               end as is_2times
        /*   ,(select avg(pd) from (select distinct code,rpt_date,pd from DWH.DCA_TRGT_PD where pd_type=1)
         where code = z.code and rpt_date<=z.rpt_date
        ) as SMA_PD*/
          from (select distinct v.*,
                                t.load_id,
                                t.pd_type,
                                t.month,
                                t.year,
                                t.rpt_date,
                                t.pd,
                                t.var1,
                                t.var2,
                                t.var3,
                                t.var4
                  from DWH.DCA_TRGT_PD t
                  left join (select max(v.fil_code) fil_code, v.code, v.name
                              from dwh.DCA_SRC_BM1 v
                             group by v.code, v.name) v
                    on v.code = t.code
                 where t.pd_type = 1 --and v.code = 10
                   and t.load_id in (1000161,
                                     --1000143,
                                     --1000180,
                                     1000200,
                                     1000220,
                                     1000163,
                                     1000240,
                                     1000260)) z) x
  left join (select distinct code, rpt_date, pd
               from DWH.DCA_TRGT_PD
              where pd_type = 1
                and load_id in (1000161,
                                --1000143,
                                --1000180,
                                1000200,
                                1000220,
                                1000163,
                                1000240,
                                1000260)) a
    on a.code = x.code
   and a.rpt_date <= x.rpt_date
   and a.rpt_date >= add_months(x.rpt_date, -6)
  left join (select distinct code, rpt_date, pd
               from DWH.DCA_TRGT_PD
              where pd_type = 1
                and load_id in (1000161,
                                --1000143,
                                --1000180,
                                1000200,
                                1000220,
                                1000163,
                                1000240,
                                1000260)) b
    on b.code = x.code
   and b.rpt_date <= x.rpt_date
   and b.rpt_date >= add_months(x.rpt_date, -3)
 group by x.load_id,
          x.fil_code,
          x.code,
          x.name,
          x.pd_type,
          x.month,
          x.year,
          x.rpt_date,
          x.pd,
          x.pd_lag,
          x.is_more_10prc,
          x.is_2times,
          decode(x.var1, null, 0, 1),
          decode(x.var2, null, 0, 1),
          decode(x.var3, null, 0, 1),
          decode(x.var4, null, 0, 1)
;

