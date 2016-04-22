create or replace force view dwh_risk.v_salary_2 as
select /*+parallel(128)*/
  z."MM_P1",z."MM",z."IIN_CL",z."BIN",z."AMT",z."MM_LAG",z."AMT_LAG"
  ,case when nvl(z.mm-z.mm_lag,0) > 31 or nvl(amt_lag * 0.8,0) > nvl(amt,0) then 0 else 1 end is_stab_idx
  ,z.mm-z.mm_lag as diff_mm
  ,amt_lag*0.8 as amt_lag08
from
  (
    select
      add_months(t.mm,1) as mm_p1
      ,t.mm
      ,t.iin_cl
      ,t.bin
      ,sum_trans_amount amt
      ,lag(t.mm) over (partition by t.bin, t.iin_cl order by t.mm ) mm_lag
      ,lag(t.sum_trans_amount) over (partition by t.bin, t.iin_cl order by t.mm ) amt_lag
    from (select t.iin_cl,
                   t.bin,
                   t.is_have_bin,
                   t.contract_name,
                   t.mm,
                   sum(t.trans_amount) as sum_trans_amount
          from V_SALARY t
          group by t.iin_cl, t.bin, t.contract_name, t.mm, is_have_bin) t
  ) z;

