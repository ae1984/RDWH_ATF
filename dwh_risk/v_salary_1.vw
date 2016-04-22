create or replace force view dwh_risk.v_salary_1 as
select lead(t.mm) over(partition by t.iin_cl, t.bin, t.contract_name order by t.mm) as mm_lead,
       add_months(t.mm,1) as mm1,
       lead(t.sum_trans_amount) over(partition by t.iin_cl, t.bin, t.contract_name order by t.mm) as sum_trans_amount_lead,
       t."SUM_TRANS_AMOUNT" as SUM_TRANS_AMOUNT_N,
       lag(t.sum_trans_amount) over(partition by t.iin_cl, t.bin, t.contract_name order by t.mm) as sum_trans_amount_lag1,
       lag(t.sum_trans_amount,2) over(partition by t.iin_cl, t.bin, t.contract_name order by t.mm) as sum_trans_amount_lag2,
       lag(t.sum_trans_amount,3) over(partition by t.iin_cl, t.bin, t.contract_name order by t.mm) as sum_trans_amount_lag3,
       lag(t.sum_trans_amount,4) over(partition by t.iin_cl, t.bin, t.contract_name order by t.mm) as sum_trans_amount_lag4,
       lag(t.sum_trans_amount,5) over(partition by t.iin_cl, t.bin, t.contract_name order by t.mm) as sum_trans_amount_lag5,
       lag(t.sum_trans_amount,6) over(partition by t.iin_cl, t.bin, t.contract_name order by t.mm) as sum_trans_amount_lag6,
       lag(t.sum_trans_amount,7) over(partition by t.iin_cl, t.bin, t.contract_name order by t.mm) as sum_trans_amount_lag7,
       case
         when nvl(lead(t.sum_trans_amount)
          over(partition by t.iin_cl,
                   t.bin,
                   t.contract_name order by t.mm),0) < t.sum_trans_amount * 0.8 then
          1
         else
          0
       end as is_less_zp,
       case
         when nvl(lead(t.sum_trans_amount_usd)
          over(partition by t.iin_cl,
                   t.bin,
                   t.contract_name order by t.mm),0) < t.sum_trans_amount_usd * 0.8 then
          1
         else
          0
       end as is_less_zp_usd,
       case
         when nvl(lead(t.mm) over(partition by t.iin_cl,
                       t.bin,
                       t.contract_name order by t.mm),
                  sysdate) - t.mm > 35 then
          1
         else
          0
       end as is_delay_zp,

       case
         when case
                when nvl(lead(t.sum_trans_amount)
                 over(partition by t.iin_cl,
                          t.bin,
                          t.contract_name order by t.mm),0) < t.sum_trans_amount * 0.8 then
                 1
                else
                 0
              end + case
                when nvl(lead(t.mm) over(partition by t.iin_cl,
                              t.bin,
                              t.contract_name order by t.mm),
                         sysdate) - t.mm > 35 then
                 1
                else
                 0
              end = 0 then
          1
         else
          0
       end stab_indx,

       case
         when case
                when nvl(lead(t.sum_trans_amount_usd)
                 over(partition by t.iin_cl,
                          t.bin,
                          t.contract_name order by t.mm),0) < t.sum_trans_amount_usd * 0.8 then
                 1
                else
                 0
              end + case
                when nvl(lead(t.mm) over(partition by t.iin_cl,
                              t.bin,
                              t.contract_name order by t.mm),
                         sysdate) - t.mm > 35 then
                 1
                else
                 0
              end = 0 then
          1
         else
          0
       end stab_indx_usd,

       t."IIN_CL",
       t."BIN",
       t."CONTRACT_NAME",
       t."MM",
       t."SUM_TRANS_AMOUNT",
       t.sum_trans_amount_usd,
       t.is_have_bin
  from (select t.iin_cl,
               t.bin,
               t.is_have_bin,
               t.contract_name,
               t.mm,
               sum(t.trans_amount) as sum_trans_amount,
               sum(t.trans_amount_usd) as sum_trans_amount_usd
          from V_SALARY t
         group by t.iin_cl, t.bin, t.contract_name, t.mm, is_have_bin) t;

