create or replace force view dwh_risk.v_vint_h_cp_1 as
select t."CNT",t."REPORT_DT",t."NUM_DOG",t."REFER",t."CLIENT_CODE",t."DT_BEGIN",t."DT_BEGIN_MONTH",t."DT_END",t."MFO",t."FILIAL",t."TYPE_OF_BUSINESS",t."PRODUCT_CODE",t."PRODUCT_NAME",t."VCC",t."VAL_CODE",t."AMT_VAL",t."AMOUNTLOANKZT_SUM",t."PRODUCT_TYPE",t."OBJ_CRED_CODE",t."REPORT_S",t."SPU",t."INDICATOR",t."BUSINESS",t."SMEPRODUCT",t."SMEPRODUCT1",t."SECUNSEC",t."SECTYPE",t."CASH",t."CASH_PRODUCT",t."FLAG_RESTRUCT",t."FLAG_OUT_BALANCE",t."PRC_AMT_VAL",t."PRC_AMT_KZT",t."LOANREST",t."LOANREST_ALL_MONTH",t."PENALTY",t."DISCOUNT",t."OD_DAY_DEF",t."PRC_DAY_DEF",t."DEF_DAYS_OD",t."DEF_DAYS_PRC",t."DEF_AMT_OD",t."DEF_DAYS",t."DEF_AMT_OD_VAL",t."DEF_AMT_PRC",t."DEF_AMT_PRC_VAL",t."COUNT_OF_CREDIT",t."MOB",t."COUNT",t."COUNT_OF_1P",t."COUNT_OF_30P",t."COUNT_OF_60P",t."COUNT_OF_90P",t."COUNT_OF_180P",t."COUNT_OF_1P_SUM",t."COUNT_OF_30P_SUM",t."COUNT_OF_60P_SUM",t."COUNT_OF_90P_SUM",t."COUNT_OF_180P_SUM",t."_NAME_",t."USD",t."GBR",t."RUB",t."EUR",t."F76",t."F77",t."F75"
  , case
      when t.BUSINESS = '001' then 'CORP'
      when t.BUSINESS = '002' then 'SME'
      when t.BUSINESS in ('003','004','005') then 'PI'
    end as type
  , case
      when t.BUSINESS in ('002','003','004','005') then 'PISME'
      else 'CORP'
    end as type1
  ,t.INDICATOR||t.SPU as BANK
  ,t.BUSINESS||t.SPU as BIZ
  ,t.BUSINESS||t.SECUNSEC as SEC
  ,t.BUSINESS||t.SMEPRODUCT as SME

  /*************************FOR VINTAGE*****************************/
  /*VALLBANK=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(INDICATOR)||'@00');
  VBANKSPU=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(BANK)||'@00');
  VPRODUCT=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(BUSINESS)||'@00');
  VPI=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(TYPE)||'@00');
  VSECURED=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(SEC)||'@00');
  VCORPSPU=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(BIZ)||'@00');
  VRESME=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(TYPE1)||'@00');
  VSMETYPE=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(SMEPRODUCT)||'@00');
  VSMETYPE1=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(SMEPRODUCT1)||'@00');
  VPITYPE=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(SECTYPE)||'@00');
  VCASH1=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(CASH)||'@00');
  VCASH2=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(CASH_PRODUCT)||'@00');  */

  /********************FILIAL*************************/
  /*VALLBANKFILIAL=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(INDICATOR)||'@'||STRIP(FILIAL));
  VBANKSPUFILIAL=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(BANK)||'@'||STRIP(FILIAL));
  VPRODUCTFILIAL=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(BUSINESS)||'@'||STRIP(FILIAL));
  VPIFILIAL=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(TYPE)||'@'||STRIP(FILIAL));
  VSECUREDFILIAL=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(SEC)||'@'||STRIP(FILIAL));
  VCORPSPUFILIAL=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(BIZ)||'@'||STRIP(FILIAL));
  VSMETYPEFILIAL=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(SMEPRODUCT)||'@'||STRIP(FILIAL));
  VSMETYPEFILIAL1=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(SMEPRODUCT1)||'@'||STRIP(FILIAL));
  VPITYPEFILIAL=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(SECTYPE)||'@'||STRIP(FILIAL));
  VCASH1FILIAL=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(CASH)||'@'||STRIP(FILIAL));
  VCASH2FILIAL=TRIMN(STRIP(OPENDATE_YM)||'@'||STRIP(CASH_PRODUCT)||'@'||STRIP(FILIAL)); */

  ,case when mob = 0 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end  as "_0"
  ,case when mob = 1 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end  as "_1"
  ,case when mob = 2 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end  as "_2"
  ,case when mob = 3 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end  as "_3"
  ,case when mob = 4 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end  as "_4"
  ,case when mob = 5 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end  as "_5"
  ,case when mob = 6 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end  as "_6"
  ,case when mob = 7 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end  as "_7"
  ,case when mob = 8 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end  as "_8"
  ,case when mob = 9 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end  as "_9"
  ,case when mob = 10 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_10"
  ,case when mob = 11 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_11"
  ,case when mob = 12 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_12"
  ,case when mob = 13 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_13"
  ,case when mob = 14 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_14"
  ,case when mob = 15 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_15"
  ,case when mob = 16 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_16"
  ,case when mob = 17 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_17"
  ,case when mob = 18 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_18"
  ,case when mob = 19 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_19"
  ,case when mob = 20 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_20"
  ,case when mob = 21 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_21"
  ,case when mob = 22 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_22"
  ,case when mob = 23 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_23"
  ,case when mob = 24 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_24"
  ,case when mob = 25 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_25"
  ,case when mob = 26 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_26"
  ,case when mob = 27 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_27"
  ,case when mob = 28 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_28"
  ,case when mob = 29 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_29"
  ,case when mob = 30 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_30"
  ,case when mob = 31 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_31"
  ,case when mob = 32 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_32"
  ,case when mob = 33 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_33"
  ,case when mob = 34 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_34"
  ,case when mob = 35 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_35"
  ,case when mob = 36 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_36"
  ,case when mob = 37 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_37"
  ,case when mob = 38 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_38"
  ,case when mob = 39 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_39"
  ,case when mob = 40 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_40"
  ,case when mob = 41 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_41"
  ,case when mob = 42 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_42"
  ,case when mob = 43 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_43"
  ,case when mob = 44 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_44"
  ,case when mob = 45 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_45"
  ,case when mob = 46 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_46"
  ,case when mob = 47 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_47"
  ,case when mob = 48 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_48"
  ,case when mob = 49 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_49"
  ,case when mob = 50 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_50"
  ,case when mob = 51 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_51"
  ,case when mob = 52 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_52"
  ,case when mob = 53 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_53"
  ,case when mob = 54 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_54"
  ,case when mob = 55 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_55"
  ,case when mob = 56 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_56"
  ,case when mob = 57 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_57"
  ,case when mob = 58 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_58"
  ,case when mob = 59 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_59"
  ,case when mob = 60 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_60"
  ,case when mob = 61 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_61"
  ,case when mob = 62 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_62"
  ,case when mob = 63 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_63"
  ,case when mob = 64 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_64"
  ,case when mob = 65 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_65"
  ,case when mob = 66 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_66"
  ,case when mob = 67 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_67"
  ,case when mob = 68 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_68"
  ,case when mob = 69 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_69"
  ,case when mob = 70 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_70"
  ,case when mob = 71 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_71"
  ,case when mob = 72 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_72"
  ,case when mob = 73 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_73"
  ,case when mob = 74 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_74"
  ,case when mob = 75 and LOANREST > 0 then LOANREST_ALL_MONTH/LOANREST else 0 end as "_75"
from v_vint_h_cp t
--where t.client_code = '828357'
;

