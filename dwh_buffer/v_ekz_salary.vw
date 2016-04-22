create or replace force view dwh_buffer.v_ekz_salary as
select "PROCESS_GUID","PROCESS_CODE","PROCESS_VERSION","START_DATE","FINISH_DATE","PROCESS_STATUS","SUBDIVISION","STEP_COUNTER","ISRUNNING","INITIATOR_CODE","PROCESS_NUM","AMOUNT","CURRENCY","CLIENT_NAME","REGNUMBER","BRANCH_ID","BRANCHNAME","DEP_ID","DEPNAME","PR_STATUS","TITLE","FULL_NAME","APPL_STATUS","APPL_DATE","rnn","Ssum","Dsum","Rejectreason","call1dec","call2dec","call3dec","call4dec","call5dec","call6dec","cc_checkresult","signdoc_date","isemp","mphone","wphone","wphone_int","registrphone","factphone","inquirywphone","inquirywphone_int","conf1_contphone","conf2_contphone","addmphone","Verifier_name","Verifier_code","Verifier_Result","Verifier_date","f2_date","employee_id","idcardnum","prompt_status","wconf1_contphone","wconf2_contphone","producttype","producttypen","iin","salaryflag","salary_project_rnn1","salary_project_rnn2","salary_project_rnn3","child_guid","child_status","Verifier_desc","database_desc","employer_desc","client_desc","sendactivateflag","inscardnum","file_status","approval_status","way4_date","app_file","reply_file","way4_error","main_contract_num","institution","client_id","short_name","parent_regnum","isrev","Org_Name","Comworkexp","Workexp","PartnerId","Education","Birthdate","Sex","Maritalstat","Income","PartnerN","Isloyal","Specflag","VerifierRemakeCnt","CashmethodId","Cashmethodn","Email","Rrn","SubTypeId","SubTypeName","VerifierConfRemakeCnt","agreement_date","loanPeriod","lpurpose","learnbank","monsum","commison","commservice","postname","PKB_Report","AppofExtsite","CB_Report","UserDSACode","UserDSAName","IsDSA","GSVP_NUM","SENDER_NAME","SENDER_RNN","SENDER_BIN","isInsurance","schedulen","carmodelid","site1kz"
    from dbo.Salary@EKZ_MSSQL m;
grant select on DWH_BUFFER.V_EKZ_SALARY to AIBEK_BE;
grant select on DWH_BUFFER.V_EKZ_SALARY to DWH_PRIM;
grant select on DWH_BUFFER.V_EKZ_SALARY to DWH_RISK;
grant select on DWH_BUFFER.V_EKZ_SALARY to DWH_SALES;
grant select on DWH_BUFFER.V_EKZ_SALARY to HEAD_DENIS_PL;
grant select on DWH_BUFFER.V_EKZ_SALARY to HEAD_EVGENIY_PI;
grant select on DWH_BUFFER.V_EKZ_SALARY to KRISTINA_KO;
grant select on DWH_BUFFER.V_EKZ_SALARY to PROCESS_RISK;
grant select on DWH_BUFFER.V_EKZ_SALARY to PROCESS_SALES;


