create or replace force view dwh_risk.v_default_20150804 as
select
  trunc(MONTHS_BETWEEN(trunc(sysdate), trunc(t.fromdate))) as MOB
  ,
(case when nvl(t.DCLOSE,trunc(sysdate)-1)-t.doper>=1
          then 1
          else 0
          end)*(case when trunc(sysdate)-1-t.doper>=1
          then 1
          else null
          end) default_01,
       (case when nvl(t.DCLOSE,trunc(sysdate)-1)-t.doper>=7
          then 1
          else 0
          end)*(case when trunc(sysdate)-1-t.doper>=7
          then 1
          else null
          end) default_07,
       (case when nvl(t.DCLOSE,trunc(sysdate)-1)-t.doper>=14
          then 1
          else 0
          end)*(case when trunc(sysdate)-1-t.doper>=14
          then 1
          else null
          end) default_14,
       (case when nvl(t.DCLOSE,trunc(sysdate)-1)-t.doper>=21
          then 1
          else 0
          end)*(case when trunc(sysdate)-1-t.doper>=21
          then 1
          else null
          end) default_21,
       (case when nvl(t.DCLOSE,trunc(sysdate)-1)-t.doper>=30
          then 1
          else 0
          end)*(case when trunc(sysdate)-1-t.doper>=30
          then 1
          else null
          end) default_30,
       (case when nvl(t.DCLOSE,trunc(sysdate)-1)-t.doper>=60
          then 1
          else 0
          end)*(case when trunc(sysdate)-1-t.doper>=60
          then 1
          else null
          end) default_60,
       (case when nvl(t.DCLOSE,trunc(sysdate)-1)-t.doper>=90
          then 1
          else 0
          end)*(case when trunc(sysdate)-1-t.doper>=90
          then 1
          else null
          end) default_90
       ,case when trunc(sysdate) -1 - t.doper>=1
          then 1
          else 0
          end censored_01,
       case when trunc(sysdate) -1 - t.doper>=7
          then 1
          else 0
          end censored_07,
       case when trunc(sysdate) -1 - t.doper>=14
          then 1
          else 0
          end censored_14,
       case when trunc(sysdate) -1 - t.doper>=21
          then 1
          else 0
          end censored_21,
       case when trunc(sysdate) -1 - t.doper>=30
          then 1
          else 0
          end censored_30,
       case when trunc(sysdate) -1 - t.doper>=60
          then 1
          else 0
          end censored_60,
       case when trunc(sysdate) -1 - t.doper>=90
          then 1
          else 0
          end censored_90
  ,t."CONTRACT_ID",t."ID",t."LONGNAME",t."DOPER",t."AMOUNT_VAL",t."PRC",t."DCLCFROM",t."DCLCTO",t."CSR_CODE",t."WAITDATE",t."PAYSDOK",t."SDOK",t."DCLOSE",t."PAYSDOKN",t."SDOKN",t."FIX_PAY_NORD",t."STAT",t."UPD_DT1",t."VCC",t."FILIAL",t."CLI_CODE",t."FROMDATE",t."STATE",t."CONTRACT_NUM",t."FULL_NAME",t."VAL_CODE",t."VAL_ID",t."REFER_WH"
from V_MOB_20150804 t;

