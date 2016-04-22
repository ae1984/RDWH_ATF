create or replace force view dwh_risk.uwi_detail_stages_old as
select
   t.START_DATE start_dt_tm,
   trunc(t.START_DATE, 'dd') start_dt,
   to_number(substr(to_char(t.start_date,'dd.mm.yyyy HH24:mi:ss'),12,2)) start_hh,
   trunc(t.START_DATE, 'mm') start_mm,
   trunc(t.start_date, 'iw') start_week,
   t.FINISH_DATE finish_dt_tm,
   trunc(t.FINISH_DATE, 'dd') finish_dt,
   case when t.process_status = 'Completed' then  t.FINISH_DATE - t.START_DATE  else  null  end * 24 time_to_decision,
   t.PROCESS_STATUS,
   t.STEP_COUNTER,
   t.CURRENCY_CODE,
   --t.Reg_Num,
   t.registration_number,
   t.BRANCH_Name,
   t.Dep_Name,
   t.TITLE,
   case when title like '%Автокредитование%' or  title='Тулпар' then 'Авто'
        when title like '%Ипотека%' then 'Ипотека'
        when title='Потребительское кредитование' or lower(title)='%залог%' then 'Под залог'
        when title like '%Легкий%' then 'Легкий'
        when title like '%Револьверное кредитование%' then 'Револьверное кредитование'
        else title
   end product_group,
   to_number ( replace(t.LOAN_AMOUNT,'.',',') )  requested_sum,
   t.Ssum                preaproved_sum,
   t.Dsum                approved_sum,
   --t.Rejectreason,
   case  when call1dec is null then 0
         else  case when call2dec  is null then 1
                    else case when call3dec  is null then 2
                              else case when call4dec  is null then 3
                                        else case when call5dec  is null then 4
                                                  else case when call6dec  is null then 5
                                                            else 6
                                                       end
                                             end
                                   end
                         end
               end
   end how_many_calls,
   t.salaryflag,
   t.Isloyal,
   case when t.salaryflag = 1 and t.Isloyal = 1 then 'Зарплатник+Лояльный'
        when t.salaryflag = 1                   then 'Зарплатник'
        when t.Isloyal = 1                      then 'Лояльный'
        else '-'
   end as cli_type,
   t.learnbank,
   t.Cashmethodn,
   1 as app_count,
   case when  upper(request_state_code) = upper('Finished')
              or upper(PR_STATUS) in (
                    upper('Завершено'),
                    upper('Отправка досье ПКАФ'),
                    upper('Запрос на принятие заявки ПКАФ'),
                    upper('Досье возвращено консультанту'),
                    upper('Досье осталось у ПКАФ'),
                    upper('Подтверждение получения досье ПКАФ'),
                    upper('Подготовка распоряжения'),
                    upper('Передача досье в Архив'),
                    upper('Досье возвращено ПКАФ'),
                    upper('Запрос на принятие заявки Архив'),
                    upper('Сбор подписей и подготовка к выдаче'),
                    upper('Открытие текущего счета'),
                    upper('Запрос на принятие заявки для ПКАФ'),
                    upper('Отправка досье в ПКАФ'),
                    upper('Подготовка распоряжения'),
                    upper('Передача досье в Архив'),
                    upper('Подтверждение получения досье ПКАФ'),
                    upper('Запрос на принятие заявки Архив'),
                    upper('Запрос на принятие заявки Архивом'),
                    upper('Передача досье в Архив'),
                    upper('Завершен'),
                    upper('Завершено')
                 )  then  1 else  0 end as loan_count,
   case when t.PR_STATUS like ('Завершено') then  t.Dsum else 0 end as loan_sum,
   row_number() over(partition by t.iin order by t.START_DATE) app_count_client,
   case when row_number() over(partition by t.iin,trunc(t.START_DATE) order by t.START_DATE) = 1 then 1 else 0 end unique_client_day,
   t.PR_STATUS,
   t.f2_date,
   trunc(t.f2_date) f2_dt,
   case when t.client_id > 0 then 1 else 0 end find_client_colvir,
   trunc(t.agreement_date) agreement_dt,
   trunc(t.agreement_date, 'mm') agreement_mm,
   case when t.f2_date > to_date('01.01.1900', 'dd.mm.yyyy') then t.f2_date - t.START_DATE else  null end * 24 time_to_f2,
   decode(t.f2_date, to_date('01.01.1900', 'dd.mm.yyyy'), 0, 1) had_f2,
   case when t.agreement_date > to_date('01.01.1900', 'dd.mm.yyyy') then t.agreement_date - t.start_date else null end * 24 time_to_cash,
   t.FINISH_DATE,
   trunc(t.FINISH_DATE, 'mm') finish_mm,
   t.Verifier_date,
   trunc(t.Verifier_date, 'dd') Verifier_dd,
   trunc(t.Verifier_date, 'mm') Verifier_mm,
   t.dbtype,
    -- rr.reject_reason,
   t.producttypen||t.product_name product_name,
   t.security_completed,
   t.protocol_date,
   t.request_state_code,
   --t.title,
   t.decision,
   --t.currency_code,
   t.credadm_completed,
   t.category,
   t.guarantee_completed,
   t.iin,
   t.verifier_desc,
   t.verifier_result
   ,t.verifier_name,
   --v."AGR_ID",v."OFFER_LIMIT",v."OFFER_DT",v."CLI_ID",v."CLI_CODE",
   --case when agr_id is not null then 1 else 0 end had_offer
   --,
   --campaign_code,
   t.initiator_code,
   t.full_name,
   t.process_code, t.process_version, t.process_guid,
   t.client_name,
   u."STATUS",u."STAGE",u."STAFF_PROCESS",u."WRONG_CLIENT_DATA",u."STOPPED_BEFORE_SCORING",u."STOPPED_AFTER_SCORING",u."IS_APPLICATION",u."APPROVED_SCORING",u."APPROVED_VERIFICATION",u."CREDIT_ADMINS_PASSED",u."CLIENT_GOT_MONEY",u."READY_FOR_SCORING",u."READY_FOR_VERIF",
   case when  t.start_date-nvl(lag(t.start_date) over (partition by t.iin order by t.start_date), to_date('01.01.1999','dd.mm.yyyy'))<30 then 0 else 1 end no_apps_last_month,
   s.pd,
   s.pd_cc,
   round(s.pd*100) pd_round,
   round(s.pd_cc*100) pd_cc_round
   --t.client_name
   ,scoring_dt.dt as scor_dt_b
   ,nvl(scoring_dt_end.dt,scoring_dt_end1.dt) as scor_dt_e
   ,verif_dt.dt as verif_dt_b
   ,nvl(verif_dt_end.dt,verif_dt_end1.dt) as verif_dt_e
   ,(t.FINISH_DATE - t.start_date)*24*60 as lifetime_request
   ,(nvl(scoring_dt_end.dt,scoring_dt_end1.dt) - scoring_dt.dt)*24*60 as lifetime_scoring
   ,(nvl(verif_dt_end.dt,verif_dt_end1.dt) - verif_dt.dt)*24*60 as lifetime_verific
from dwh_prim.loan_request t
   --  left join EKZ_REJECT_REASON rr on rr.process_guid = t.process_guid
   left join UWI_proc_stages u on t.pr_status=u.status
   left join v_score_results s on t.registration_number=s.regnumber
   left join (select t1.process_guid, min(t1.message_date) as dt
              from dwh_prim.ekz_ret_getstep t1
              where upper(t1.message_comment) like upper('%Скоринг%')

              group by t1.process_guid
             )  scoring_dt on scoring_dt.process_guid = t.process_guid
   left join (select t2.process_guid, min(t2.message_date) as dt
              from dwh_prim.ekz_ret_getstep t2
              where t2.message_comment in (  'Отклонена - Скоринговое решение'
                                            ,'Согласование условий с клиентом'
                                            ,'Согласование условий'
                                            ,'Сканирование документов'
                                            ,'Ожидание верификации'
                                            ,'Верификация'
                                            ,'Открытие счета'
                                            ,'Сбор подписей'
                                            ,'Отменена Клиентом - До верификации'
                                           )
              --where upper(t2.message_comment) like upper('%Скоринг%')
              group by t2.process_guid
             )  scoring_dt_end on scoring_dt_end.process_guid = t.process_guid


   left join (select t3.process_guid, min(t3.message_date) as dt
              from dwh_prim.ekz_ret_getstep t3
              where upper(t3.message_comment) like  upper('%верификац%')
              group by t3.process_guid
             )  verif_dt on verif_dt.process_guid = t.process_guid
   left join (select t4.process_guid, max(t4.message_date) as dt
              from dwh_prim.ekz_ret_getstep t4
              where t4.message_comment in ( 'Открытие текущего счета'
                                            ,'Сбор подписей'
                                            ,'Отменена - верификация'
                                            ,'На доработке - верификатор'

                                           )
              --where t4.message_comment like  '%верификац%'
              group by t4.process_guid
             )  verif_dt_end on verif_dt_end.process_guid = t.process_guid

   left join (select t5.process_guid, max(t5.message_date) as dt
              from dwh_prim.ekz_ret_getstep t5
              where upper(t5.pr_status) --like upper('%Скоринг%')
                                      in (  'Отклонена - Скоринговое решение'
                                            ,'Согласование условий с клиентом'
                                            ,'Согласование условий'
                                            ,'Сканирование документов'
                                            ,'Ожидание верификации'
                                            ,'Верификация'
                                            ,'Открытие счета'
                                            ,'Сбор подписей'
                                            ,'Отменена Клиентом - До верификации'
                                           )
              group by t5.process_guid
             )  scoring_dt_end1 on scoring_dt_end1.process_guid = t.process_guid

   left join (select t6.process_guid, max(t6.message_date) as dt
              from dwh_prim.ekz_ret_getstep t6
              where upper(t6.pr_status) --like upper('%Скоринг%')
                                      in (  'Открытие текущего счета'
                                            ,'Сбор подписей'
                                            ,'Отменена - верификация'
                                            ,'На доработке - верификатор'
                                           )
              group by t6.process_guid
             )  verif_dt_end1 on verif_dt_end1.process_guid = t.process_guid
/*
left join
(
select t.*, c.cli_id,c.cli_code

from
(
select distinct agr_id, offer_limit, trunc(offer_dt) offer_dt
--,campaign_code
from
(
select
o.agr_id,
first_value(ov.offer_limit) over (partition by o.agr_id order by o.offer_open_dttm) offer_limit,
min(o.offer_open_dttm) over (partition by o.agr_id ) offer_dt
--,o.campaign_code
from offer o
join offer_variant ov on o.offer_id=ov.offer_id
)) t
join client c on c.agr_id=t.agr_id
) v on v.cli_code=t.client_id and v.offer_dt<=t.start_date*/



where t.dbtype = 2
      and  t.START_DATE >= to_date('2015.01.01', 'yyyy.mm.dd')
  -- and t.client_id=66759

--select * from loan_request t where t.dbtype = 2
--select * from v_uwi_all t  where t.dbtype = 1
;

