create or replace force view dwh_risk.v_tmp_20150701 as
select t.contract_num,a.loanperiod from TMP_20150701 t
left join dwh_buffer.loan_request a on a.registration_number = t.contract_num;

