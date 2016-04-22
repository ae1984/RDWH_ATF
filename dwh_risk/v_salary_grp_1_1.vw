create or replace force view dwh_risk.v_salary_grp_1_1 as
select t.mm, t.bin, t.contract_name, t.amt_grp, count(1) as cnt from V_SALARY_GRP_1 t
group by t.mm, t.bin, t.contract_name, t.amt_grp;

