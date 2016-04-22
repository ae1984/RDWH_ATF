create or replace force view dwh_buffer.v_ekz_cashandgoforrb as
select "PROCESS_GUID","PROCESS_CODE","START_DATE","FINISH_DATE","PROCESS_STATUS","PROCESS_NUM","INITIATOR_CODE","app_producttype","app_reqsum","app_cur","app_purpose","app_sheduleid","app_shedulen","app_percent","app_standartpercent","app_isgenrepsch","app_sum1","app_cur1","app_period1","app_curleqsum","app_reqmonthpaydate","app_loanpurpose","app_addfield1","app_addfield2","decis_sum","decis_cur","decis_period","decis_percent","decis_effect","decis_score","decis_monthpay","decis_maxsum","decis_maxsumcur"
    from  dbo.v_CashAndGoForRB@ekz_mssql;
grant select on DWH_BUFFER.V_EKZ_CASHANDGOFORRB to AIBEK_BE;
grant select on DWH_BUFFER.V_EKZ_CASHANDGOFORRB to DWH_PRIM;
grant select on DWH_BUFFER.V_EKZ_CASHANDGOFORRB to DWH_RISK;
grant select on DWH_BUFFER.V_EKZ_CASHANDGOFORRB to DWH_SALES;
grant select on DWH_BUFFER.V_EKZ_CASHANDGOFORRB to HEAD_DENIS_PL;
grant select on DWH_BUFFER.V_EKZ_CASHANDGOFORRB to HEAD_EVGENIY_PI;
grant select on DWH_BUFFER.V_EKZ_CASHANDGOFORRB to KRISTINA_KO;
grant select on DWH_BUFFER.V_EKZ_CASHANDGOFORRB to PROCESS_RISK;
grant select on DWH_BUFFER.V_EKZ_CASHANDGOFORRB to PROCESS_SALES;


