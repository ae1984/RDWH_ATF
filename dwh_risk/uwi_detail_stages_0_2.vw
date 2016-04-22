create or replace force view dwh_risk.uwi_detail_stages_0_2 as
select
  /*+ parallel(8) */
  t."START_DT_TM",t."START_DT",t."START_HH",t."START_MM",t."START_WEEK",t."FINISH_DT_TM",t."FINISH_DT",t."TIME_TO_DECISION",t."PROCESS_STATUS",t."STEP_COUNTER",t."CURRENCY_CODE",t."REGISTRATION_NUMBER",t."BRANCH_NAME",t."DEP_NAME",t."TITLE",t."PRODUCT_GROUP",t."REQUESTED_SUM",t."PREAPROVED_SUM",t."APPROVED_SUM",t."HOW_MANY_CALLS",t."SALARYFLAG",t."ISLOYAL",t."LEARNBANK",t."CASHMETHODN",t."APP_COUNT",t."LOAN_COUNT",t."LOAN_SUM",t."APP_COUNT_CLIENT",t."FIRST_TIME_REQUEST",t."PR_STATUS",t."F2_DATE",t."F2_DT",t."FIND_CLIENT_COLVIR",t."AGREEMENT_DT",t."AGREEMENT_MM",t."TIME_TO_F2",t."HAD_F2",t."TIME_TO_CASH",t."FINISH_DATE",t."FINISH_MM",t."VERIFIER_DATE",t."VERIFIER_DD",t."VERIFIER_MM",t."DBTYPE",t."REJECT_REASON",t."PRODUCT_NAME",t."SECURITY_COMPLETED",t."PROTOCOL_DATE",t."REQUEST_STATE_CODE",t."DECISION",t."CREDADM_COMPLETED",t."CATEGORY",t."GUARANTEE_COMPLETED",t."IIN",t."VERIFIER_DESC",t."INITIATOR_CODE",t."FULL_NAME",t."PROCESS_CODE",t."PROCESS_VERSION",t."PROCESS_GUID",t."CLIENT_NAME",t."STATUS",t."STAGE",t."STAFF_PROCESS",t."WRONG_CLIENT_DATA",t."STOPPED_BEFORE_SCORING",t."STOPPED_AFTER_SCORING",t."IS_APPLICATION",t."APPROVED_SCORING",t."APPROVED_VERIFICATION",t."CREDIT_ADMINS_PASSED",t."CLIENT_GOT_MONEY",t."READY_FOR_SCORING",t."READY_FOR_VERIF",t."APPROVED_FIRST_TIME",t."APPORVED_ON_FIRST_APP",t."NO_APPS_LAST_MONTH",t."PD",t."PD_CC",t."PD_ROUND",t."PD_CC_ROUND",t."INCOME",t."FIRST_TIME_REQUEST2",t."IS_INCOME75PLUS",t."IS_INCOME90PLUS",t."IS_INCOME105PLUS",t."IS_4A"

 ,(select lras.process_guid
   from LOAN_REQUEST_APPROV_SCOR lras
   where  lras.iin = t.iin
          and trunc(lras.start_date) between t.finish_dt
          and add_months(trunc(t.finish_date), 1)
          and rownum<2
  ) as lr_APPROV_SCOR_1
--t.client_name
  ,case when lrrc.registration_number is null then 0 else 1 end as is_REJECT_CANCEL

  ,case when lra.registration_number is null then 0 else 1 end as is_APPROV_SCOR

 ,(select lrr.process_guid
   from LOAN_REQUEST_REJECT_CANCEL lrr
   where  lrr.iin = t.iin
          and trunc(lrr.finish_date) between add_months(t.start_dt , -1) and t.start_dt-1
          and rownum<2
  ) as lr_REJECT_CANCEL_1
 ,(select lrr.process_guid
   from LOAN_REQUEST_REJECT_CANCEL lrr
   where  lrr.iin = t.iin
          and trunc(lrr.finish_date) between add_months(t.start_dt , -2) and add_months(t.start_dt-1,-1)
          and rownum<2
  ) as lr_REJECT_CANCEL_2
 ,(select lrr.process_guid
   from LOAN_REQUEST_REJECT_CANCEL lrr
   where  lrr.iin = t.iin
          and trunc(lrr.finish_date) between add_months(t.start_dt , -3) and add_months(t.start_dt-1,-2)
          and rownum<2
  ) as lr_REJECT_CANCEL_3
 ,(select lr.process_guid
   from DWH_BUFFER.LOAN_REQUEST lr
   where  lr.iin = t.iin
          and trunc(lr.finish_date) between add_months(trunc(t.start_dt) , -3) and trunc(t.start_dt-1)
          and rownum<2
  ) as lr_n3
from UWI_DETAIL_STAGES t
  left join LOAN_REQUEST_REJECT_CANCEL lrrc on lrrc.process_guid = t.process_guid
  left join LOAN_REQUEST_APPROV_SCOR lra on lra.process_guid = t.process_guid
;

