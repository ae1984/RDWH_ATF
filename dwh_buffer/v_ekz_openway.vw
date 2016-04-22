create or replace force view dwh_buffer.v_ekz_openway as
select "PROCESS_GUID","PROCESS_CODE","PROCESS_VERSION","START_DATE","FINISH_DATE","PROCESS_STATUS","SUBDIVISION","STEP_COUNTER","ISRUNNING","INITIATOR_CODE","PROCESS_NUM","AMOUNT","CURRENCY","CLIENT_NAME","REGNUMBER","BRANCHNAME","DEPNAME","PR_STATUS","OPERATIONNAME","TITLE","FULL_NAME","BRANCH_ID","DEP_ID","OPERATION_ID","CARDPRODUCT_ID","CARDPRODUCT_NAME","APPL_STATUS","APPL_DATE","FLDEL","PIN2_STATUS","is_owner","way4clientid","sub_type","DELIVERY_BRANCH","Delivery_dep","subtype","nsubtype","cur","limit","iin","RevType","CardNumber","ContractNumber","Institution","ParentRegNumber","ClientNumber","ShortName","RNN","REPLY_FILE","way4_error","FILE_STATUS","APP_FILE","IsPakageAddCard","IBAN","AddCardCount","Verifier_code","Verifier_name","Verifier_Result","Verifier_date","IS_REV_CARD","INITIATOR_POSITION","AppFileName","Persent"
    from dbo.OpenWay@EKZ_MSSQL;
grant select on DWH_BUFFER.V_EKZ_OPENWAY to AIBEK_BE;
grant select on DWH_BUFFER.V_EKZ_OPENWAY to DWH_PRIM;
grant select on DWH_BUFFER.V_EKZ_OPENWAY to DWH_RISK;
grant select on DWH_BUFFER.V_EKZ_OPENWAY to DWH_SALES;
grant select on DWH_BUFFER.V_EKZ_OPENWAY to HEAD_DENIS_PL;
grant select on DWH_BUFFER.V_EKZ_OPENWAY to HEAD_EVGENIY_PI;
grant select on DWH_BUFFER.V_EKZ_OPENWAY to KRISTINA_KO;
grant select on DWH_BUFFER.V_EKZ_OPENWAY to PROCESS_RISK;
grant select on DWH_BUFFER.V_EKZ_OPENWAY to PROCESS_SALES;


