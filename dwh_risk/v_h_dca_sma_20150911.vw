create or replace force view dwh_risk.v_h_dca_sma_20150911 as
select
   t."LOAD_ID",t."FIL_CODE",t."CODE",t."NAME",t."PD_TYPE",t."MONTH",t."YEAR",t."RPT_DATE",t."PD",t."PD_LAG",t."IS_MORE_10PRC",t."IS_2TIMES",t."AVG_6",t."AVG_3",t."HAVE_BASE_MODEL",t."HAVE_LOAN_MODEL",t."HAVE_RESTS_MODEL",t."HAVE_MOVES_MODEL"
  ,case when t.pd=nvl(t.pd_lag,t.pd) then 0 else 1 end is_1M_change
  ,case when t.pd=nvl(t.avg_6,t.pd) then 0 else 1 end is_6M_change
  ,case when t.pd=nvl(t.avg_3,t.pd) then 0 else 1 end is_3M_change
  --,case when a.ovrd>0 then 1 else 0 end is_ovrd
  ,case when b.max_ovrd>0 then 1 else 0 end is_ovrd
  ,b.max_ovrd
  ,a.vcc_type
  --,a.is_cif_base
  --,a.is_loan_base
from --H_DCA_SMA_20150918 t
     V_H_DCA_SMA_20151014 t
left join (select
             code
             ,load_id
             ,vcc_type
             ,greatest(nvl(max(ovrd_main),0),nvl(max(ovrd_prc),0) )as ovrd
             ,is_cif_base,is_loan_base
           from --DCA_20150918 t
                V_DCA_20150918 t
           group by code,vcc_type,load_id,is_cif_base,is_loan_base) a on a.code = t.code and a.load_id = t.load_id
left join (
select clicode, max(ovrd) max_ovrd  from (
  select clicode, greatest(to_number(main_ovrd) , to_number(prc_ovrd)) ovrd  from H_XLS_CP_20150828 where clicode is not null
)
group by clicode
) b on b.clicode = t.code and t.load_id = 1000240
;

