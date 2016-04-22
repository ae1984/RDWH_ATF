create or replace force view dwh_risk.v_loan_sched as
select t."CONTRACT_ID",t."ID",t."LONGNAME",t."DOPER",t."AMOUNT_VAL",t."PRC",t."DCLCFROM",t."DCLCTO",t."CSR_CODE",t."WAITDATE",t."PAYSDOK",t."SDOK",t."DCLOSE",t."PAYSDOKN",t."SDOKN",t."FIX_PAY_NORD", a.stat from dwh_buffer.DM_LOAN_PAYM_3 t
left join dwh_buffer.loan_sched_1 a on a.contract_id = t.contract_id and  a.id = t.id;

