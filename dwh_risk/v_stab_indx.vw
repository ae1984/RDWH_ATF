create or replace force view dwh_risk.v_stab_indx as
select t."BIN",
       t."CONTRACT_NAME",
       add_months(t."MM",1) as MM,
       t."STAB_INDX",
       trunc(t.stab_indx / 0.05) * 0.05 stab_indx_gr
       ,t.personal_count
       ,t.stab_personal_count
  from (

        select t.bin, t.contract_name, t.mm, avg(t.stab_indx) stab_indx, count(distinct t.iin_cl) as personal_count
          , sum(t.stab_indx) as stab_personal_count
          from v_salary_1 t

         group by t.bin, t.contract_name, t.mm

        ) t;

