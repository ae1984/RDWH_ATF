create or replace force view dwh_risk.v_company_salary_20151015_3 as
select t."CONTRACT_NAME",
       t."BIN",
       t."TYPE_COMPANY",
       t."MM",
       t."DT",
       t."TRANS_AMOUNT",
       t."CNT",
       t."MAX_TRANS_AMOUNT_MM",
       t."IS_ZP",
       lag(t.dt) over(partition by t.BIN order by t.mm) as dt_lag,

       t.dt - nvl(lag(t.dt) over(partition by t.BIN order by t.mm), t.dt) as diff_day,
       case
         when t.dt -
              nvl(lag(t.dt) over(partition by t.BIN order by t.mm), t.dt) > 41 then
          1
         else
          0
       end is_delay_zp_41,
       case
         when t.dt -
              nvl(lag(t.dt) over(partition by t.BIN order by t.mm), t.dt) > 41 then
          1
         else
          0
       end is_delay_zp_35,
       case
         when t.dt -
              nvl(lag(t.dt) over(partition by t.BIN order by t.mm), t.dt) > 41 then
          1
         else
          0
       end is_delay_zp_51



  from V_COMPANY_SALARY_20151015_2 t
 where t.is_zp = 1;

