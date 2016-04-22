create or replace force view dwh_risk.v_slace_loan as
select t.refer_wh from V_DM_LOAN_BASE_CLN t
where t.FROMDATE between to_date('01.01.1990') and to_date('15.09.2015');

