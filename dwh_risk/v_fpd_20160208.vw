create or replace force view dwh_risk.v_fpd_20160208 as
select /*+parallel(32)*/
   t.report_dt report_dt1
   ,trunc(t.report_dt,'mm') report_dt,
   --trunc(t.report_dt,'q') report_Q
   /*case
      when extract (month from trunc(t.report_dt,'q')) = 1 then 'QI '|| extract (year from t.report_dt)
      when extract (month from trunc(t.report_dt,'q')) = 4 then 'QII '|| extract (year from t.report_dt)
      when extract (month from trunc(t.report_dt,'q')) = 7 then 'QIII '|| extract (year from t.report_dt)
      when extract (month from trunc(t.report_dt,'q')) = 10 then 'QIV '|| extract (year from t.report_dt)
   end as report_Q*/
   case
      when extract (month from trunc(t.report_dt,'q')) = 1 then  extract (year from t.report_dt)||' Q1'
      when extract (month from trunc(t.report_dt,'q')) = 4 then  extract (year from t.report_dt)||' Q2'
      when extract (month from trunc(t.report_dt,'q')) = 7 then  extract (year from t.report_dt)||' Q3'
      when extract (month from trunc(t.report_dt,'q')) = 10 then extract (year from t.report_dt)||' Q4'
   end as report_Q

   ,a.registration_number
   ,a.producttypen
   ,t.f53 as refer
   --,case when (select count(1) from dwh_buffer.loan_request z where z.registration_number=t.registration_number) > 1 then 1 else 0 end as is_more_1_req
   ,case when a.cnt > 1 then 1 else 0 end as is_more_1_req
   ,case when t.cnt > 1 then 1 else 0 end as is_more_1_loan
   ,case when t.f53 is null then 0 else 1 end is_have_cp
   ,a.start_date
   ,a.finish_date
   ,a.dep_id
   ,a.dep_name
   ,a.initiator_code
   ,a.verefeir_code
   ,a.verefeir_name
   ,t.code_sel_dep
   ,t.sel_dep
   ,lead(t.F82,2) over (partition by t.F53 order by t.report_dt) as OVRD_lead2M
   ,case when nvl(lead(t.F82,1)  over (partition by t.F53 order by t.report_dt),0) > 0  then 1 else 0 end FPD0
   ,case when nvl(lead(t.F82,3)  over (partition by t.F53 order by t.report_dt),0) > 30 then 1 else 0 end FPD60
   ,case when nvl(lead(t.F82,2)  over (partition by t.F53 order by t.report_dt),0) > 30 then 1 else 0 end is_OVRD_lead2M_30p
   ,case when nvl(lead(t.F82,3)  over (partition by t.F53 order by t.report_dt),0) > 30 then 1 else 0 end is_OVRD_lead3M_30p
   ,case when nvl(lead(t.F82,6)  over (partition by t.F53 order by t.report_dt),0) > 30 then 1 else 0 end is_OVRD_lead6M_30p
   ,case when nvl(lead(t.F82,12) over (partition by t.F53 order by t.report_dt),0) > 90 then 1 else 0 end is_OVRD_lead12M_90p
   ,case when nvl(lead(t.F82,1)  over (partition by t.F53 order by t.report_dt),0) > 30 then 1 else 0 end a30_1MOB
   ,case when nvl(lead(t.F82,2)  over (partition by t.F53 order by t.report_dt),0) > 30 then 1 else 0 end a30_2MOB
   ,case when nvl(lead(t.F82,3)  over (partition by t.F53 order by t.report_dt),0) > 30 then 1 else 0 end a30_3MOB
   ,case when nvl(lead(t.F82,4)  over (partition by t.F53 order by t.report_dt),0) > 30 then 1 else 0 end a30_4MOB
   ,case when nvl(lead(t.F82,5)  over (partition by t.F53 order by t.report_dt),0) > 30 then 1 else 0 end a30_5MOB
   ,case when nvl(lead(t.F82,6)  over (partition by t.F53 order by t.report_dt),0) > 30 then 1 else 0 end a30_6MOB
   ,case when nvl(lead(t.F82,7)  over (partition by t.F53 order by t.report_dt),0) > 30 then 1 else 0 end a30_7MOB
   ,case when nvl(lead(t.F82,8)  over (partition by t.F53 order by t.report_dt),0) > 30 then 1 else 0 end a30_8MOB
   ,case when nvl(lead(t.F82,9)  over (partition by t.F53 order by t.report_dt),0) > 30 then 1 else 0 end a30_9MOB
   ,case when nvl(lead(t.F82,10) over (partition by t.F53 order by t.report_dt),0) > 30 then 1 else 0 end a30_10MOB
   ,case when nvl(lead(t.F82,11) over (partition by t.F53 order by t.report_dt),0) > 30 then 1 else 0 end a30_11MOB
   ,case when nvl(lead(t.F82,12) over (partition by t.F53 order by t.report_dt),0) > 30 then 1 else 0 end a30_12MOB
   ,case when nvl(lead(t.F82,1)  over (partition by t.F53 order by t.report_dt),0) > 60 then 1 else 0 end a60_1MOB
   ,case when nvl(lead(t.F82,2)  over (partition by t.F53 order by t.report_dt),0) > 60 then 1 else 0 end a60_2MOB
   ,case when nvl(lead(t.F82,3)  over (partition by t.F53 order by t.report_dt),0) > 60 then 1 else 0 end a60_3MOB
   ,case when nvl(lead(t.F82,4)  over (partition by t.F53 order by t.report_dt),0) > 60 then 1 else 0 end a60_4MOB
   ,case when nvl(lead(t.F82,5)  over (partition by t.F53 order by t.report_dt),0) > 60 then 1 else 0 end a60_5MOB
   ,case when nvl(lead(t.F82,6)  over (partition by t.F53 order by t.report_dt),0) > 60 then 1 else 0 end a60_6MOB
   ,case when nvl(lead(t.F82,7)  over (partition by t.F53 order by t.report_dt),0) > 60 then 1 else 0 end a60_7MOB
   ,case when nvl(lead(t.F82,8)  over (partition by t.F53 order by t.report_dt),0) > 60 then 1 else 0 end a60_8MOB
   ,case when nvl(lead(t.F82,9)  over (partition by t.F53 order by t.report_dt),0) > 60 then 1 else 0 end a60_9MOB
   ,case when nvl(lead(t.F82,10) over (partition by t.F53 order by t.report_dt),0) > 60 then 1 else 0 end a60_10MOB
   ,case when nvl(lead(t.F82,11) over (partition by t.F53 order by t.report_dt),0) > 60 then 1 else 0 end a60_11MOB
   ,case when nvl(lead(t.F82,12) over (partition by t.F53 order by t.report_dt),0) > 60 then 1 else 0 end a60_12MOB

   ,case when nvl(lead(t.F82,1)  over (partition by t.F53 order by t.report_dt),0) > 90 then 1 else 0 end a90_1MOB
   ,case when nvl(lead(t.F82,2)  over (partition by t.F53 order by t.report_dt),0) > 90 then 1 else 0 end a90_2MOB
   ,case when nvl(lead(t.F82,3)  over (partition by t.F53 order by t.report_dt),0) > 90 then 1 else 0 end a90_3MOB
   ,case when nvl(lead(t.F82,4)  over (partition by t.F53 order by t.report_dt),0) > 90 then 1 else 0 end a90_4MOB
   ,case when nvl(lead(t.F82,5)  over (partition by t.F53 order by t.report_dt),0) > 90 then 1 else 0 end a90_5MOB
   ,case when nvl(lead(t.F82,6)  over (partition by t.F53 order by t.report_dt),0) > 90 then 1 else 0 end a90_6MOB
   ,case when nvl(lead(t.F82,7)  over (partition by t.F53 order by t.report_dt),0) > 90 then 1 else 0 end a90_7MOB
   ,case when nvl(lead(t.F82,8)  over (partition by t.F53 order by t.report_dt),0) > 90 then 1 else 0 end a90_8MOB
   ,case when nvl(lead(t.F82,9)  over (partition by t.F53 order by t.report_dt),0) > 90 then 1 else 0 end a90_9MOB
   ,case when nvl(lead(t.F82,10) over (partition by t.F53 order by t.report_dt),0) > 90 then 1 else 0 end a90_10MOB
   ,case when nvl(lead(t.F82,11) over (partition by t.F53 order by t.report_dt),0) > 90 then 1 else 0 end a90_11MOB
   ,case when nvl(lead(t.F82,12) over (partition by t.F53 order by t.report_dt),0) > 90 then 1 else 0 end a90_12MOB

   ,case when nvl(lead(t.F82,1)  over (partition by t.F53 order by t.report_dt),0) > 0  then
      nvl(lead(t.F13,1) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,1)  over (partition by t.F53 order by t.report_dt),0)
      else 0 end FPD0_OVRD_OD
   ,case when nvl(lead(t.F82,3)  over (partition by t.F53 order by t.report_dt),0) > 30 then
      nvl(lead(t.F13,3) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,3)  over (partition by t.F53 order by t.report_dt),0)
      else 0 end FPD60_OVRD_OD
   ,case when nvl(lead(t.F82,2)  over (partition by t.F53 order by t.report_dt),0) > 30 then
      nvl(lead(t.F13,2) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,2)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end is_OVRD_lead2M_30p_OVRD_OD
   ,case when nvl(lead(t.F82,3)  over (partition by t.F53 order by t.report_dt),0) > 30 then
      nvl(lead(t.F13,3) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,3)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end is_OVRD_lead3M_30p_OVRD_OD
   ,case when nvl(lead(t.F82,6)  over (partition by t.F53 order by t.report_dt),0) > 30 then
      nvl(lead(t.F13,6) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,6)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end is_OVRD_lead6M_30p_OVRD_OD
   ,case when nvl(lead(t.F82,12) over (partition by t.F53 order by t.report_dt),0) > 90 then
      nvl(lead(t.F13,12) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,12)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end is_OVRD_lead12M_90p_OVRD_OD
   ,case when nvl(lead(t.F82,1)  over (partition by t.F53 order by t.report_dt),0) > 30 then
      nvl(lead(t.F13,1) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,1)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a30_1MOB_OVRD_OD
   ,case when nvl(lead(t.F82,2)  over (partition by t.F53 order by t.report_dt),0) > 30 then
      nvl(lead(t.F13,2) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,2)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a30_2MOB_OVRD_OD
   ,case when nvl(lead(t.F82,3)  over (partition by t.F53 order by t.report_dt),0) > 30 then
      nvl(lead(t.F13,3) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,3)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a30_3MOB_OVRD_OD
   ,case when nvl(lead(t.F82,4)  over (partition by t.F53 order by t.report_dt),0) > 30 then
      nvl(lead(t.F13,4) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,4)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a30_4MOB_OVRD_OD
   ,case when nvl(lead(t.F82,5)  over (partition by t.F53 order by t.report_dt),0) > 30 then
      nvl(lead(t.F13,5) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,5)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a30_5MOB_OVRD_OD
   ,case when nvl(lead(t.F82,6)  over (partition by t.F53 order by t.report_dt),0) > 30 then
      nvl(lead(t.F13,6) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,6)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a30_6MOB_OVRD_OD
   ,case when nvl(lead(t.F82,7)  over (partition by t.F53 order by t.report_dt),0) > 30 then
      nvl(lead(t.F13,7) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,7)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a30_7MOB_OVRD_OD
   ,case when nvl(lead(t.F82,8)  over (partition by t.F53 order by t.report_dt),0) > 30 then
      nvl(lead(t.F13,8) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,8)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a30_8MOB_OVRD_OD
   ,case when nvl(lead(t.F82,9)  over (partition by t.F53 order by t.report_dt),0) > 30 then
      nvl(lead(t.F13,9) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,9)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a30_9MOB_OVRD_OD
   ,case when nvl(lead(t.F82,10) over (partition by t.F53 order by t.report_dt),0) > 30 then
      nvl(lead(t.F13,10) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,10)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a30_10MOB_OVRD_OD
   ,case when nvl(lead(t.F82,11) over (partition by t.F53 order by t.report_dt),0) > 30 then
      nvl(lead(t.F13,11) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,11)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a30_11MOB_OVRD_OD
   ,case when nvl(lead(t.F82,12) over (partition by t.F53 order by t.report_dt),0) > 30 then
      nvl(lead(t.F13,12) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,12)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a30_12MOB_OVRD_OD
   ,case when nvl(lead(t.F82,1)  over (partition by t.F53 order by t.report_dt),0) > 60 then
      nvl(lead(t.F13,1) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,1)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a60_1MOB_OVRD_OD
   ,case when nvl(lead(t.F82,2)  over (partition by t.F53 order by t.report_dt),0) > 60 then
      nvl(lead(t.F13,2) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,2)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a60_2MOB_OVRD_OD
   ,case when nvl(lead(t.F82,3)  over (partition by t.F53 order by t.report_dt),0) > 60 then
      nvl(lead(t.F13,3) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,3)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a60_3MOB_OVRD_OD
   ,case when nvl(lead(t.F82,4)  over (partition by t.F53 order by t.report_dt),0) > 60 then
      nvl(lead(t.F13,4) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,4)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a60_4MOB_OVRD_OD
   ,case when nvl(lead(t.F82,5)  over (partition by t.F53 order by t.report_dt),0) > 60 then
      nvl(lead(t.F13,5) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,5)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a60_5MOB_OVRD_OD
   ,case when nvl(lead(t.F82,6)  over (partition by t.F53 order by t.report_dt),0) > 60 then
      nvl(lead(t.F13,6) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,6)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a60_6MOB_OVRD_OD
   ,case when nvl(lead(t.F82,7)  over (partition by t.F53 order by t.report_dt),0) > 60 then
      nvl(lead(t.F13,7) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,7)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a60_7MOB_OVRD_OD
   ,case when nvl(lead(t.F82,8)  over (partition by t.F53 order by t.report_dt),0) > 60 then
      nvl(lead(t.F13,8) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,8)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a60_8MOB_OVRD_OD
   ,case when nvl(lead(t.F82,9)  over (partition by t.F53 order by t.report_dt),0) > 60 then
      nvl(lead(t.F13,9) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,9)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a60_9MOB_OVRD_OD
   ,case when nvl(lead(t.F82,10) over (partition by t.F53 order by t.report_dt),0) > 60 then
      nvl(lead(t.F13,10) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,10)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a60_10MOB_OVRD_OD
   ,case when nvl(lead(t.F82,11) over (partition by t.F53 order by t.report_dt),0) > 60 then
      nvl(lead(t.F13,11) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,11)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a60_11MOB_OVRD_OD
   ,case when nvl(lead(t.F82,12) over (partition by t.F53 order by t.report_dt),0) > 60 then
      nvl(lead(t.F13,12) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,12)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a60_12MOB_OVRD_OD

   ,case when nvl(lead(t.F82,1)  over (partition by t.F53 order by t.report_dt),0) > 90 then
      nvl(lead(t.F13,1) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,1)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a90_1MOB_OVRD_OD
   ,case when nvl(lead(t.F82,2)  over (partition by t.F53 order by t.report_dt),0) > 90 then
      nvl(lead(t.F13,2) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,2)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a90_2MOB_OVRD_OD
   ,case when nvl(lead(t.F82,3)  over (partition by t.F53 order by t.report_dt),0) > 90 then
      nvl(lead(t.F13,3) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,3)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a90_3MOB_OVRD_OD
   ,case when nvl(lead(t.F82,4)  over (partition by t.F53 order by t.report_dt),0) > 90 then
      nvl(lead(t.F13,4) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,4)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a90_4MOB_OVRD_OD
   ,case when nvl(lead(t.F82,5)  over (partition by t.F53 order by t.report_dt),0) > 90 then
      nvl(lead(t.F13,5) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,5)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a90_5MOB_OVRD_OD
   ,case when nvl(lead(t.F82,6)  over (partition by t.F53 order by t.report_dt),0) > 90 then
      nvl(lead(t.F13,6) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,6)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a90_6MOB_OVRD_OD
   ,case when nvl(lead(t.F82,7)  over (partition by t.F53 order by t.report_dt),0) > 90 then
      nvl(lead(t.F13,7) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,7)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a90_7MOB_OVRD_OD
   ,case when nvl(lead(t.F82,8)  over (partition by t.F53 order by t.report_dt),0) > 90 then
      nvl(lead(t.F13,8) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,8)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a90_8MOB_OVRD_OD
   ,case when nvl(lead(t.F82,9)  over (partition by t.F53 order by t.report_dt),0) > 90 then
      nvl(lead(t.F13,9) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,9)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a90_9MOB_OVRD_OD
   ,case when nvl(lead(t.F82,10) over (partition by t.F53 order by t.report_dt),0) > 90 then
      nvl(lead(t.F13,10) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,10)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a90_10MOB_OVRD_OD
   ,case when nvl(lead(t.F82,11) over (partition by t.F53 order by t.report_dt),0) > 90 then
      nvl(lead(t.F13,11) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,11)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a90_11MOB_OVRD_OD
   ,case when nvl(lead(t.F82,12) over (partition by t.F53 order by t.report_dt),0) > 90 then
      nvl(lead(t.F13,12) over (partition by t.F53 order by t.report_dt),0)+
      nvl(lead(t.F14,12)  over (partition by t.F53 order by t.report_dt),0)
       else 0 end a90_12MOB_OVRD_OD


   ,case when trunc(t.csln_fromdate,'MM') = trunc(t.report_dt,'MM') then 1 else 0 end as is_issue_mm
   --,case when trunc(min(t.f22_1) over (partition by t.f6),'MM') = trunc(t.report_dt,'MM') then 1 else 0 end as is_issue_mm2
   ,case when trunc(t.csln_fromdate,'MM') = trunc(t.report_dt,'MM')
          and upper(nvl(t.f35,'-')) in ('N','-') then 1 else 0 end as is_new
          --and upper(nvl(t.f35,'-')) in ('N','T','T2','T6','-','') then 1 else 0 end as is_new
   --,t.f51 as is_RWO
   ,case
      when trunc(t.csln_fromdate,'MM') = trunc(t.report_dt,'MM') and upper(nvl(t.f35,'-')) in ('N','-') then 'Новый, не реструктурированный'
      when trunc(t.csln_fromdate,'MM') = trunc(t.report_dt,'MM') and upper(nvl(t.f35,'-')) not in ('N','-') then 'Новый, отструктурированный'
      when trunc(t.csln_fromdate,'MM') <> trunc(t.report_dt,'MM') and upper(nvl(t.f35,'-')) in ('N','-') then 'Не новый, не реструктурированный'
      when trunc(t.csln_fromdate,'MM') <> trunc(t.report_dt,'MM') and upper(nvl(t.f35,'-')) not in ('N','-') then 'Не новый, реструктурированный'
      else 'неопределен (возможно нет даты открытия)'
    end as is_flag_stat
   --,t.f11 as t_loan_sum
   ,t.f11*get_nbrk_curr(t.csln_fromdate,t.f10,0) as t_loan_sum
   ,t.f11 as t_loan_sum_val
   ,t.f10 as currency_code
   ,t.f78 is_RWO1
   ,t.f79 is_RWO2
   ,t.f58 product_colvir
   ,t.f69 as CBO
   ,t.f1 as filial_collvir
   , (select ee.fil_name from v_filials ee where ee.fil_code=t.f1) filial_name
   ,t.f77 VCC
   ,a.salaryflag
   ,a.isloyal
   ,case when nvl(a.salaryflag,0)+nvl(a.isloyal,0)=0 then 1 else 0 end as is_mass
   /*,case
     when trunc(a.income/25000)*25000>600000 then 600000
     else trunc(a.income/25000)*25000
    end as income_group*/
   ,case
     when trunc(a.income) < 50000 then 0
     when trunc(a.income) between 50000 and 74999 then 50000
     when trunc(a.income) between 75000 and 99999 then 75000
     when trunc(a.income) between 100000 and 149999 then 100000
     when trunc(a.income) >=150000 then 150000
    end as income_group
   ,b.product_type
   ,t.f35
   ,t.csln_fromdate
   ,t.f6
    ,case when substr(t.f7,7,1) in ('1','3','5') then 'М'
          when substr(t.f7,7,1) in ('2','4','6') then 'Ж'
     end as GENDER
   ,c.qca_min,c.qca_max
   --,t.f35_1
   /*,t.f9_1
   ,case when (sum(t.f35_1) over (partition by t.f6)) > 0 then 1 else 0 end as is_restr_by_f9
   ,trunc(min(t.f22_1) over (partition by t.f6),'mm') as first_dt
   ,min(t.f34_1) over (partition by t.f6) as first_dt_restr
   ,trunc(months_between(min(t.f34_1) over (partition by t.f6), min(t.f22_1) over (partition by t.f6))) as cnt_mm_to_restr
   ,case when length(t.f22)=10 then to_date(t.f22) else null end as loan_sdt
   ,t.f22
   ,max(t.issue_kzt_sum_repdt) over (partition by t.f6) as issue_kzt_sum_max
   ,t.dpd_max
   ,t.f82
   ,t.f5*/
from (
      select  aa.refer_wh
             ,aa.sell_dep_id
             --,nvl(aa.csln_fromdate,aa.fromdate) as csln_fromdate
             --,nvl(nvl(aa.csln_fromdate,aa.fromdate),to_date(bb.f22)) as csln_fromdate
             ,to_date(bb.f22) as csln_fromdate
             ,bb.*
             ,cc.code as code_sel_dep
             ,cc.longname as sel_dep
             ,count(1) over (partition by bb.f9) as cnt
      from v_cp_h bb
      left join (
           select distinct refer_wh,sell_dep_id,csln_fromdate,fromdate  from(
              select * from dwh_buffer.dm_loan_base
              union all
              select * from dwh_buffer.dm_loan_base_20151229
           )
         ) aa on aa.refer_wh = bb.F53
      left join (
           select distinct id,code,longname  from (
             select * from dwh_buffer.c_dep
             union all
             select * from dwh_buffer.c_dep_20151229
           )
         ) cc on cc.id = aa.sell_dep_id
     )t
 /*right*/ left join (
       select aa.*, count(1) over (partition by aa.registration_number) as cnt from dwh_buffer.loan_request aa
      ) a on t.f9 = a.registration_number
    left join XLS_H_PRODUCTTYPE b on upper(b.details) = upper(t.F58)
left join (
  select trim(f3) clicode,min(f4) qca_min,max(f4) qca_max from xls_QCA_20160208 t
  where t.f3 is not null and t.f3 not like 'Код%'
  group by  f3
) c on c.clicode = any(t.F6,t.F7)
;

