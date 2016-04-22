create or replace force view dwh_risk.v_dm_loan_base_cln as
select t."CONTRACT_ID",t."DEP_ID",t."CLI_ID",t."CLI_DEP_ID",t."CONTRACT_NUM",t."VAL_ID",t."VAL_CODE",t."PRD_CODE",t."PRD_NAME",t."PRD_TERM",t."TERM_TYPE",t."TERM_CNT",t."FROMDATE",t."TODATE",t."STATE",t."FIL_CODE",t."FIL_NAME",t."SUM_FULL",t."REFER_WH",t."RATE",t."ACC_ID",t."ACC_DEP_ID",t."ACC_PR_ID",t."ACC_PR_DEP_ID",t."SELL_DEP_ID",t."CSLN_FROMDATE",t."OBJ_ID"
,c.full_name,c.cli_code,c.iin,c.vcc

from /*dwh_buffer.dm_loan_base*/  dwh_buffer.dm_loan_base t
     left join dwh_buffer.client c on c.cli_id = t.cli_id;

