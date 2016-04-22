CREATE OR REPLACE FORCE VIEW DWH_BUFFER.V_TRANS AS
SELECT /*+ parallel(8) DRIVING_SITE (doc,tt,mt) */
         /*--use_nl(doc,mt) */
          doc.POSTING_DATE,
          doc.target_number,
          (SELECT ac.client__id ows_client_id
             FROM ows.client@rpt c, ows.acnt_contract@rpt ac
            WHERE     c.amnd_state = 'A'
                  AND ac.amnd_state = 'A'
                  AND c.ID = ac.client__id
                  AND ac.contract_number = target_number
                  AND ROWNUM < 2)
             ows_client_id,
          SETTL_AMOUNT,
          (SELECT FULL_NAME
             FROM OWS.currency@rpt
            WHERE amnd_state = 'A' AND doc.SETTL_CURR = code)
            SETTL_CURR,
          SETTL_CURR SETTL_CURR_C,
          SOURCE_CHANNEL,
          SOURCE_NUMBER,
          TARGET_CHANNEL,
          doc.TRANS_AMOUNT,
          TRANS_CITY,
          TRANS_COUNTRY,
          (SELECT FULL_NAME
             FROM OWS.currency@rpt
            WHERE amnd_state = 'A' AND doc.trans_curr = code)
            trans_curr,
          doc.TRANS_CURR TRANS_CURR_C,
          TRANS_DATE TRANS_DATE,
          MT.DIRECTION DIR,
          TRANS_TYPE OP_TYPE_CODE,
          tt.name OP_TYPE_NAME,
          doc.service_class,
          DOC.SIC_CODE SIC_MCC,
          doc.AMND_DATE,
          doc.ID ID_D,
          doc.trans_details,
          mt.trans_amount m_trans_amount,
          mt.s_amount s_amount,
          mt.s_fee_amount s_fee_amount,
          mt.t_amount t_amount,
          mt.t_fee_amount t_fee_amount,
          mt.m_transaction__oid
     FROM ows.doc@rpt doc
     inner join ows.trans_type@rpt tt
     on tt.id = DOC.trans_type
     inner join ows.m_transaction@rpt mt
     on doc.id = MT.DOC__OID
    WHERE MT.posting_status = 'P'            -- and mt.service_class = 'T'
          AND doc.amnd_state = 'A'
          AND DOC.is_authorization = 'N'
          AND DOC.posting_status = 'P'
          AND tt.amnd_state = 'A'
    --and mt.m_transaction__oid is null
;
grant select on DWH_BUFFER.V_TRANS to AIBEK_BE;
grant select on DWH_BUFFER.V_TRANS to DWH_PRIM;
grant select on DWH_BUFFER.V_TRANS to DWH_RISK;
grant select on DWH_BUFFER.V_TRANS to DWH_SALES;
grant select on DWH_BUFFER.V_TRANS to HEAD_DENIS_PL;
grant select on DWH_BUFFER.V_TRANS to HEAD_EVGENIY_PI;
grant select on DWH_BUFFER.V_TRANS to KRISTINA_KO;
grant select on DWH_BUFFER.V_TRANS to PROCESS_RISK;
grant select on DWH_BUFFER.V_TRANS to PROCESS_SALES;


