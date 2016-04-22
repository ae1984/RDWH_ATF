create or replace force view dwh_risk.v_w_4_bal as
select
    --trunc(t.trans_date) as DT
    --,trunc(t.trans_date,'MM') as DT_MM
    trunc(t.POSTING_DB_DATE) as DT
    ,trunc(t.POSTING_DB_DATE,'MM') as DT_MM
    ,case when t.bal>0 then 1 else 0 end is_credit_trans
    ,t.bal*get_nbrk_curr(trunc(t.trans_date),t.currency_code,0) as AMT_KZT
    ,case when (
       select count(1) from W_4_BAL tt
       where tt.billing_contract = t.billing_contract
             and tt.trans_type in ('Payment Salary', 'Payment To Client Contract')
             and rownum <2
             --and tt.trans_date<=t.trans_date
     )>0 then 1 else 0 end as is_zp_prj
    ,case when t.bal>0 then t.bal*get_nbrk_curr(trunc(t.trans_date),t.currency_code,0) end prihod_kzt
    ,case when t.bal<=0 then t.bal*get_nbrk_curr(trunc(t.trans_date),t.currency_code,0) end rashod_kzt
    ,cl.agr_id
    ,t."TRANS_FROM",t."TRANS_TO",t."SOURCE_CONTRACT",t."TARGET_CONTRACT",t."TRANS_TYPE",t."POSTING_DB_DATE",t."TRANS_DATE",t."TRANS_CURR",t."CURRENCY_CODE",t."DIRECTION",t."BAL",t."SOURCE_NUMBER",t."TARGET_NUMBER",t."OWS_CLIENT_ID",t."W4_CONTRACT",t."BILLING_CONTRACT"
from W_4_BAL t
join dwh_buffer.CLIENT_MAP cl on cl.client_src = t.ows_client_id
--join dwh_buffer.CLIENT_MAP cl1 on cl1.agr_id = cl.agr_id and cl1.src = 'W'
;

