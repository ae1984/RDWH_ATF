create or replace force view dwh_risk.rep_resp as
select "CAMPAIGN_CODE","OFFER_TYPE","CHANNEL_PATH","REGION","COMMENT_EXT","OFFER_OPEN_DTTM","CNT_OFR","IS_SMS_DELIVERED","IS_CALL_GOT_THROUGH","IS_CALL_WRONG_NUMBER","IS_CALL_ACCEPT","IS_CALL_ACCEPT_MAYBE","CNT_APP_DIR","CNT_APP_CAN","CNT_APP_ATT","CNT_DEAL_DIR","CNT_DEAL_CAN","CNT_DEAL_ATT","SUM_DEAL_DIR","CNT_APP_DIR_7","CNT_APP_DIR_14","CNT_APP_DIR_21" from DWH_BUFFER.REP_RESP;

