create or replace force view dwh_risk.uwi_detail_stages_0_3 as
select
    /*+parallel(16)*/
    t."START_DT_TM",t."START_DT",t."START_HH",t."START_MM",t."START_WEEK",t."FINISH_DT_TM",t."FINISH_DT",t."TIME_TO_DECISION",t."PROCESS_STATUS",t."STEP_COUNTER",t."CURRENCY_CODE",t."REGISTRATION_NUMBER",t."BRANCH_NAME",t."DEP_NAME",t."TITLE",t."PRODUCT_GROUP",t."REQUESTED_SUM",t."PREAPROVED_SUM",t."APPROVED_SUM",t."HOW_MANY_CALLS",t."SALARYFLAG",t."ISLOYAL",t."LEARNBANK",t."CASHMETHODN",t."APP_COUNT",t."LOAN_COUNT",t."LOAN_SUM",t."APP_COUNT_CLIENT",t."FIRST_TIME_REQUEST",t."PR_STATUS",t."F2_DATE",t."F2_DT",t."FIND_CLIENT_COLVIR",t."AGREEMENT_DT",t."AGREEMENT_MM",t."TIME_TO_F2",t."HAD_F2",t."TIME_TO_CASH",t."FINISH_DATE",t."FINISH_MM",t."VERIFIER_DATE",t."VERIFIER_DD",t."VERIFIER_MM",t."DBTYPE",t."REJECT_REASON",t."PRODUCT_NAME",t."SECURITY_COMPLETED",t."PROTOCOL_DATE",t."REQUEST_STATE_CODE",t."DECISION",t."CREDADM_COMPLETED",t."CATEGORY",t."GUARANTEE_COMPLETED",t."IIN",t."VERIFIER_DESC",t."INITIATOR_CODE",t."FULL_NAME",t."PROCESS_CODE",t."PROCESS_VERSION",t."PROCESS_GUID",t."CLIENT_NAME",t."STATUS",t."STAGE",t."STAFF_PROCESS",t."WRONG_CLIENT_DATA",t."STOPPED_BEFORE_SCORING",t."STOPPED_AFTER_SCORING",t."IS_APPLICATION",t."APPROVED_SCORING",t."APPROVED_VERIFICATION",t."CREDIT_ADMINS_PASSED",t."CLIENT_GOT_MONEY",t."READY_FOR_SCORING",t."READY_FOR_VERIF",t."APPROVED_FIRST_TIME",t."APPORVED_ON_FIRST_APP",t."NO_APPS_LAST_MONTH",t."PD",t."PD_CC",t."PD_ROUND",t."PD_CC_ROUND",t."INCOME",t."FIRST_TIME_REQUEST2",t."IS_INCOME75PLUS",t."IS_INCOME90PLUS",t."IS_INCOME105PLUS",t."IS_4A",t."LR_APPROV_SCOR_1",t."IS_REJECT_CANCEL",t."IS_APPROV_SCOR",t."LR_REJECT_CANCEL_1",t."LR_REJECT_CANCEL_2",t."LR_REJECT_CANCEL_3"
    ,case when t.lr_reject_cancel_1 is not null then 1 else 0 end as is_otkaz_1m_nazad
    ,a.product_name is_otkaz_1m_prod
    ,a.pr_status as is_otkaz_1m_nazad_stat
    ,a1.reject_reason as is_otkaz_1m_nazad_rejres
    ,case when t.lr_reject_cancel_2 is not null then 1 else 0 end as is_otkaz_2m_nazad
    ,b.product_name is_otkaz_2m_prod
    ,b.pr_status as is_otkaz_2m_nazad_stat
    ,b1.reject_reason as is_otkaz_2m_nazad_rejres
    ,case when t.lr_reject_cancel_3 is not null then 1 else 0 end as is_otkaz_3m_nazad
    ,c.product_name is_otkaz_3m_prod
    ,c.pr_status as is_otkaz_3m_nazad_stat
    ,c1.reject_reason as is_otkaz_3m_nazad_rejres
    ,case when t.is_reject_cancel=1 and t.lr_approv_scor_1 is not null then 1 else 0 end as is_otkaz_dalee_odobren
    ,case when t.lr_n3 is not null then 1 else 0 end as is_lr_n3
    ,count(distinct t.iin) over (partition by t.start_mm) as count_dist_iin_for_mm
    ,case when t.INCOME <=100000 then trunc(t.INCOME/20000)*20000
          when t.INCOME >100000 and t.INCOME <=400000  then trunc(t.INCOME/100000)*100000
          when t.INCOME >400000 then  400000
     end as INCOME_GRP
    ,case when substr(t."IIN",7,1) in ('1','3','5') then 'Ì'
          when substr(t."IIN",7,1) in ('2','4','6') then 'Æ'
     end as GENDER
    /*,case when length(t."IIN")=12 and substr(t."IIN",7,1) in ('1','2','3','4','5','6') then
          to_date(substr(t."IIN",5,2)||'.'
          ||substr(t."IIN",3,2)||'.'
          ||
             case when to_number(substr(t."IIN",1,2)) between 0 and 18 then '20'||substr(t."IIN",1,2)
                  else '19'||substr(t."IIN",1,2)
             end
          ,'dd.mm.yyyy')
     end as bdt */
    ,trunc((trunc(sysdate,'yyyy')-case when length(t."IIN")=12 and substr(t."IIN",7,1) in ('1','2','3','4','5','6') then
           to_date('01.01.'||
             case when to_number(substr(t."IIN",1,2)) between 0 and 18 then '20'||substr(t."IIN",1,2)
                  else '19'||substr(t."IIN",1,2)
             end
          ,'dd.mm.yyyy')
     end)/365.25) as AGE
    ,case
       when trunc((trunc((trunc(sysdate,'yyyy')-case when length(t."IIN")=12 and substr(t."IIN",7,1) in ('1','2','3','4','5','6') then
             to_date('01.01.'||
               case when to_number(substr(t."IIN",1,2)) between 0 and 18 then '20'||substr(t."IIN",1,2)
                    else '19'||substr(t."IIN",1,2)
               end
            ,'dd.mm.yyyy')
       end)/365.25))/5)*5 <=25 then 25
       when trunc((trunc((trunc(sysdate,'yyyy')-case when length(t."IIN")=12 and substr(t."IIN",7,1) in ('1','2','3','4','5','6') then
             to_date('01.01.'||
               case when to_number(substr(t."IIN",1,2)) between 0 and 18 then '20'||substr(t."IIN",1,2)
                    else '19'||substr(t."IIN",1,2)
               end
            ,'dd.mm.yyyy')
       end)/365.25))/5)*5 >=65 then 65
       else trunc((trunc((trunc(sysdate,'yyyy')-case when length(t."IIN")=12 and substr(t."IIN",7,1) in ('1','2','3','4','5','6') then
             to_date('01.01.'||
               case when to_number(substr(t."IIN",1,2)) between 0 and 18 then '20'||substr(t."IIN",1,2)
                    else '19'||substr(t."IIN",1,2)
               end
            ,'dd.mm.yyyy')
       end)/365.25))/5)*5
     end as AGE_GRP
from UWI_DETAIL_STAGES_2 t
  left join dwh_buffer.loan_request a on a.process_guid = t.lr_reject_cancel_1
  left join dwh_buffer.EKZ_REJECT_REASON a1 on a1.process_guid = t.lr_reject_cancel_1
  left join dwh_buffer.loan_request b on b.process_guid = t.lr_reject_cancel_2
  left join dwh_buffer.EKZ_REJECT_REASON b1 on b1.process_guid = t.lr_reject_cancel_2
  left join dwh_buffer.loan_request c on c.process_guid = t.lr_reject_cancel_3
  left join dwh_buffer.EKZ_REJECT_REASON c1 on c1.process_guid = t.lr_reject_cancel_3;

