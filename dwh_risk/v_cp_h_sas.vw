create or replace force view dwh_risk.v_cp_h_sas as
select t.REPORT_DT
       ,t.F1 MFO
       ,t.F5 CLIENTLABEL
       ,t.F63 RNN
       ,t.F9 LOANLABEL
       ,t.F10 CURRENCY
       ,t.F11 AMOUNTLOAN
       ,t.F13 LOANREST
       ,t.F18 PERCENT_KZT
       ,t.F22 OPENDATE
       ,t.F23 CLOSEDATE
       ,t.F25 PROVISIONSAMOUNT
       ,t.F28 DISCOUNT
       ,t.F30 FINES_AND_PENALTY
       ,t.F32 AFFILIATION
       ,t.F33 ISSUE_TYPE
       ,t.F35 RESTRUCTURING_SIGN
       ,t.F39 VCC_code
       ,t.F6 CLIENT_CODE
       ,t.F49 PSC_code
       ,t.F50 AMOUNTLOAN_OLD_SYS
       ,t.F71 LEGAL_INDIVIDUAL
       ,t.F73 OUTSTANDING
       ,t.F74 IFRS_Industry
       ,t.F75 TYPE_OF_BUSINESS
       ,t.F77 Type_of_business_by_VCC
       ,(case when t.F77 like '%SNT%' then 'SPU'
       else 'non-SPU'
       end) SPU_clients
       ,t.F79 RWO
       ,t.F80 PROSRDAYS_PRINCIPAL
       ,t.F81 PROSRDAYS_INTEREST
       ,t.F82 PROSRDAYS_MAX
       ,t.F95 CLASS_
       ,t.F96 ISL
       ,t.F8 N_CREDIT_LINE
       ,t.F34 DATE_RESTR_LAST
       ,t.F36 DATE_RESTR_PREVIOUS
       ,t.F27 PRODUCT_TYPE
       ,t.F76 VCC_NAME
       ,t.F14 PROSR_LOANREST
       ,t.F19 PROSR_PERCENT
       ,t.F83 COLLATERAL
       ,t.F57 CODE_ATF_PRODUCT
       ,t.F58 NAME_ATF_PRODUCT
       ,t.F31 LOAN_PURPOSE
       ,t.F7 IIN
       ,t.F41 Код_NACE

from V_CP_H t;

