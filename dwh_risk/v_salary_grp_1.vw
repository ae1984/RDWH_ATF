create or replace force view dwh_risk.v_salary_grp_1 as
select /*+parallel(64)*/
       t.mm
      ,t.iin_cl
      ,t.bin
      ,t.contract_name
      ,sum_trans_amount amt
      ,case when trunc(sum_trans_amount/10000) * 10000 <= 1000000 then trunc(sum_trans_amount/10000) * 10000 else 1010000 end as amt_grp
    from (select t.iin_cl,
                   t.bin,
                   t.is_have_bin,
                   t.contract_name,
                   t.mm,
                   sum(t.trans_amount) as sum_trans_amount
          from V_SALARY t
          group by t.iin_cl, t.bin, t.contract_name, t.mm, is_have_bin) t;

