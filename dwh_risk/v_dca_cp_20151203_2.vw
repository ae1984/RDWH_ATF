create or replace force view dwh_risk.v_dca_cp_20151203_2 as
select
   t."FIL_CODE",t."CODE",t."NAME",t."RPT_DATE",t."PD",t."PD_LAG",t."IS_MORE_10PRC",t."IS_2TIMES",t."IS_MORE_10PRC_OR_2TIMES",t."AVG_6",t."AVG_3",t."REPORT_DT",t."DPD",t."OD",t."OVRD_OD",t."OD_OVRDOD",t."IS_AVAIBLE_CP"
   ,lead(t.dpd,2) over (partition by t.code order by t.rpt_date) as dpd_lead_2m
   ,case when lead(t.dpd,2) over (partition by t.code order by t.rpt_date) > 0 then 1 else 0 end  as is_lead_default_2m
   ,case when t.dpd > 0 then 1 else 0 end as is_dpd
   ,case when t.OD_OVRDOD > 0 then 1 else 0 end as is_OD_OVRDOD
from V_DCA_CP_20151203 t
order by t.code , t.rpt_date;

