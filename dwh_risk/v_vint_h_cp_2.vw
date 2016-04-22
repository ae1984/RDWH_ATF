create or replace force view dwh_risk.v_vint_h_cp_2 as
select t."CNT",t."REPORT_DT",t."NUM_DOG",t."REFER",t."CLIENT_CODE",t."DT_BEGIN",t."DT_BEGIN_MONTH",t."DT_END",t."MFO",t."FILIAL",t."TYPE_OF_BUSINESS",t."PRODUCT_CODE",t."PRODUCT_NAME",t."VCC",t."VAL_CODE",t."AMT_VAL",t."AMOUNTLOANKZT_SUM",t."PRODUCT_TYPE",t."OBJ_CRED_CODE",t."REPORT_S",t."SPU",t."INDICATOR",t."BUSINESS",t."SMEPRODUCT",t."SMEPRODUCT1",t."SECUNSEC",t."SECTYPE",t."CASH",t."CASH_PRODUCT",t."FLAG_RESTRUCT",t."FLAG_OUT_BALANCE",t."PRC_AMT_VAL",t."PRC_AMT_KZT",t."LOANREST",t."LOANREST_ALL_MONTH",t."PENALTY",t."DISCOUNT",t."OD_DAY_DEF",t."PRC_DAY_DEF",t."DEF_DAYS_OD",t."DEF_DAYS_PRC",t."DEF_AMT_OD",t."DEF_DAYS",t."DEF_AMT_OD_VAL",t."DEF_AMT_PRC",t."DEF_AMT_PRC_VAL",t."COUNT_OF_CREDIT",t."MOB",t."COUNT",t."COUNT_OF_1P",t."COUNT_OF_30P",t."COUNT_OF_60P",t."COUNT_OF_90P",t."COUNT_OF_180P",t."COUNT_OF_1P_SUM",t."COUNT_OF_30P_SUM",t."COUNT_OF_60P_SUM",t."COUNT_OF_90P_SUM",t."COUNT_OF_180P_SUM",t."_NAME_",t."USD",t."GBR",t."RUB",t."EUR",t."F76",t."F77",t."F75",t."TYPE",t."TYPE1",t."BANK",t."BIZ",t."SEC",t."SME",t."_0",t."_1",t."_2",t."_3",t."_4",t."_5",t."_6",t."_7",t."_8",t."_9",t."_10",t."_11",t."_12",t."_13",t."_14",t."_15",t."_16",t."_17",t."_18",t."_19",t."_20",t."_21",t."_22",t."_23",t."_24",t."_25",t."_26",t."_27",t."_28",t."_29",t."_30",t."_31",t."_32",t."_33",t."_34",t."_35",t."_36",t."_37",t."_38",t."_39",t."_40",t."_41",t."_42",t."_43",t."_44",t."_45",t."_46",t."_47",t."_48",t."_49",t."_50",t."_51",t."_52",t."_53",t."_54",t."_55",t."_56",t."_57",t."_58",t."_59",t."_60",t."_61",t."_62",t."_63",t."_64",t."_65",t."_66",t."_67",t."_68",t."_69",t."_70",t."_71",t."_72",t."_73",t."_74",t."_75"
  ,REPORT_S||'@'||INDICATOR||'@'||FILIAL     as VALLBANKFILIAL
  ,REPORT_S||'@'||BANK||'@'||FILIAL          as VBANKSPUFILIAL
  ,REPORT_S||'@'||BUSINESS||'@'||FILIAL      as VPRODUCTFILIAL
  ,REPORT_S||'@'||TYPE||'@'||FILIAL          as VPIFILIAL
  ,REPORT_S||'@'||SEC||'@'||FILIAL           as VSECUREDFILIAL
  ,REPORT_S||'@'||BIZ||'@'||FILIAL           as VCORPSPUFILIAL
  ,REPORT_S||'@'||SMEPRODUCT||'@'||FILIAL    as VSMETYPEFILIAL
  ,REPORT_S||'@'||SMEPRODUCT1||'@'||FILIAL   as VSMETYPEFILIAL1
  ,REPORT_S||'@'||SECTYPE||'@'||FILIAL       as VPITYPEFILIAL
  ,REPORT_S||'@'||CASH||'@'||FILIAL          as VCASH1FILIAL
  ,REPORT_S||'@'||CASH_PRODUCT||'@'||FILIAL  as VCASH2FILIAL
from V_VINT_H_CP_1 t;

