create or replace force view dwh_risk.v_xls_h_ekz_all_unsec_bad as
select
  IS_ZP_PROJ
  ,IS_ZP_PROJ_3M
  ,IS_ZP_CARD
  ,IS_STAFF
  ,IS_DEPOSIT
  ,t.CLIENT_ID,t.REGISTRATION_NUMBER,t.IIN,t.RNN,t.SEX,t.BIRTHDATE,t.IDENTITY_CARD_ISSUE_DATE
  ,t.IDENTITY_CARD_NUMBER,t.IDENTITY_CARD_EXPIRYDATE,t.IDENTITY_CARD_AUTHORITY,t.EDUCATION_LVL_ID
  ,t.FAMILY_STATUS_ID,t.CREDIT_EXPERT_FULL_NAME,t.BRANCH_NAME,t.REG_REGION,t.REG_CITY,t.REG_VILLAGE
  ,t.REG_HOUSE,t.REG_FLAT,t.REG_STREET,t.REG_RAION,t.REG_MICRORAION,t.REGISTRPHONE,t.AC_REGION,t.AC_CITY
  ,t.AC_VILLAGE,t.AC_HOUSE,t.AC_FLAT,t.AC_STREET,t.AC_RAION,t.AC_MICRORAION,t.FACTPHONE,t.STAZH,t.STAZH_ALL
  ,t.PKB_DEIST_ZAIMY,t.PKB_ZAVERW_ZAIMY,t.PKB_SUMMA_ZADOLJ,t.PKB_PLATEJEI,t.LOAN_AMOUNT,t.CURRENCY,t.PERCENT_RATE
  ,t.FREE_REPAYMENT_SCHEDULE,t.COMISSION,t.COMISSION_SERVICE,t.N_APP_TYPE,t.SROK_ZAIM,t.CHILDREN,t.ISLOYAL,t.STAT_NEDVIZH
  ,t.INDUSTRIYA,t.PROPIS_PROZHIV,t.ZP_PR,t.TITLE,t.STATUS
  ,to_date(substr(t.START_DATE,1,19),'YYYY-MM-DD HH24:MI:SS') as START_DATE
  ,to_date(substr(t.FINISH_DATE,1,19),'YYYY-MM-DD HH24:MI:SS') as FINISH_DATE
  ,t.AVR_ZP,t.FLAG_VOEN,t.P30P3MOB
  ,t.P60P6MOB,t.P60P12MOB,t.P90P12MOB
  ,c.cli_code
  ,c.ows_client_id
  ,c.cli_id
  ,d.company_name
from  H_201508_STEP6 t
  left join dwh_buffer.client c on c.cli_code  = t.client_id
                                   or c.iin = t.iin
                                   or c.rnn = t.rnn
  left join dwh_buffer.OWS_CLIENT_BUF d on d.OWS_CLIENT_ID = c.ows_client_id
--XLS_H_EKZ_ALL_UNSEC_BAD t
;

