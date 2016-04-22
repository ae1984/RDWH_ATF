create or replace force view dwh_risk.v_w4_trans_iin as
select trunc(t.trans_date,'MM') as mmyyyy,
       t.trans_amount*Get_NBRK_Curr(t.trans_date,to_char(t.trans_curr_c),0) as trans_amount_eq,
       t."TRANS_DIR_TYPE",t."POSTING_DATE",t."TARGET_NUMBER",t."OWS_CLIENT_ID",t."SETTL_AMOUNT",t."SETTL_CURR",t."SETTL_CURR_C",t."SOURCE_CHANNEL",t."SOURCE_NUMBER",t."TARGET_CHANNEL",t."TRANS_AMOUNT",t."TRANS_CITY",t."TRANS_COUNTRY",t."TRANS_CURR",t."TRANS_CURR_C",t."TRANS_DATE",t."DIR",t."OP_TYPE_CODE",t."OP_TYPE_NAME",t."SERVICE_CLASS",t."SIC_MCC",t."AMND_DATE",t."ID_D",t."TRANS_DETAILS",t."M_TRANS_AMOUNT",t."S_AMOUNT",t."S_FEE_AMOUNT",t."T_AMOUNT",t."T_FEE_AMOUNT",t."IIN", h.start_date
from (select t.*, o.iin
      from dwh_buffer.TRANSACTION_3 t
      left join dwh_buffer.OWS_CLIENT_BUF o
      on (o.ows_client_id = t.ows_client_id)) t
inner join H_201508_STEP6 h
on (h.client_id = t.ows_client_id or h.iin = t.iin);

