create or replace force view dwh_risk.v_slace_loan_2008 as
select t.refer_wh from V_DM_LOAN_BASE_CLN t
where t.FROMDATE between to_date('01.01.2000') and to_date('31.12.2008');

