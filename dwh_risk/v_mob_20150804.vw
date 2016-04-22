create or replace force view dwh_risk.v_mob_20150804 as
select t."CONTRACT_ID",t."ID",t."LONGNAME",t."DOPER",t."AMOUNT_VAL",t."PRC",t."DCLCFROM",t."DCLCTO",t."CSR_CODE",t."WAITDATE",t."PAYSDOK",t."SDOK",t."DCLOSE",t."PAYSDOKN",t."SDOKN",t."FIX_PAY_NORD",t."STAT",t."UPD_DT1"
   ,dcb.vcc
   ,dcb.Filial
   ,dcb.cli_code
   ,a.fromdate
   ,a.state,a.contract_num,dcb.full_name
   ,a.val_code
   ,a.val_id
   ,a.refer_wh
from LOAN_SCHED t
  left join DWH_BUFFER.DM_LOAN_BASE a on a.contract_id = t.contract_id
  --left join DWH_BUFFER.client c on c.cli_id = a.cli_id
  left join DWH_BUFFER.dm_cif_base dcb on dcb.id  = a.cli_id
where t.LONGNAME in ('Проценты по кредиту','Основной долг','Комиссия за  обслуживания банковского займа')
;

