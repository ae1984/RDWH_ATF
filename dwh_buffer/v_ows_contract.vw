create or replace force view dwh_buffer.v_ows_contract as
select /*+ parallel(8) */
      /*-- parallel(16) DRIVING_SITE (ac,cst,sp,cur,acs,act,act2,br,f,atf) */
      /*--parallel 4*/
     -- : Chshuka Dmitriy September 18, 2015 10:25 AM хинт не оптимален  *+parallel 4  DRIVING_SITE (ac, cst, sp, cur, acs, act, act2, br, f, atf)  * вернуть хинт *+parallel 4*
     -- хинт не оптимальный Chshuka Dmitriy September 17, 2015 5:11 PM *+parallel 4*
        ac.amnd_date,
       ac.id ows_contract_id,
       ac.con_cat,
       ac.contract_number,
       ac.CONTRACT_NAME,
       ac.comment_text,
       ac.client__id ows_client_id,
       ac.ACNT_CONTRACT__OID,
       ac.AUTH_LIMIT_AMOUNT,
       ac.BASE_AUTH_LIMIT,
       ac.LIAB_BALANCE,
       ac.LIAB_BLOCKED,
       ac.OWN_BALANCE,
       ac.OWN_BLOCKED,
       ac.SUB_BALANCE,
       ac.SUB_BLOCKED,
       ac.TOTAL_BALANCE,
       ac.TOTAL_BLOCKED,
       ac.SHARED_BALANCE,
       ac.SHARED_BLOCKED,
       ac.AMOUNT_AVAILABLE,
       ac.DATE_OPEN,
       ac.DATE_EXPIRE,
       ac.LAST_BILLING_DATE,
       ac.NEXT_BILLING_DATE,
       ac.LAST_SCAN,
       ac.CARD_EXPIRE,
       ac.RBS_NUMBER,
       ac.LIMIT_IS_ACTIVE,
       ac.IS_READY,
       ac.BILLING_CONTRACT,
       cst.name contract_status,
       sp.name service_pack_name,
       sp.code service_pack_code,
       cur.code currency_code,
       cur.name currency_name,
       acs.code scheme_code,
       acs.scheme_name scheme_name,
       act.INTEREST_RATE L_interest_rate,
       act2.INTEREST_RATE interest_rate,
       br.name branch_name,
       br.code branch_code,

       f.name filial_name,
       f.id filial_id,
       case when ac.con_cat='C'
        then DECODE (SUBSTR (AC.CONTRACT_NUMBER, 1, 6),
                  '405258', 'Chip Electron Visa',
                  '479068', 'Electron Visa',
                  '405255', 'Chip Classic Visa',
                  '433317', 'Classic Visa',
                  '405256', 'Chip Gold Visa',
                  '433318', 'Gold Visa',
                  '405257', 'Business Visa',
                  '427764', 'Business Visa',
                  '431879', 'Chip Platinum Visa',
                  '431253', 'Chip Revolver Visa',
                  '423208', 'Chip Infinite Visa',
                  '426668', 'Virtuon Visa',
                  '679999', 'Cirrus Corp',
                  '677252', 'Cirrus/Maestro',
                  '553107', 'MC Business',
                  '405263', 'Commercial Revolver Visa',
                  '484197', 'Visa Instant',
                  '512769', 'MC Gold',
                  '512095', 'MC Standart',
                  '603245 ','ATF ALTYN',
                  AC.CONTRACT_NUMBER)
            end           plastic_type,
       atf.name web_banking,

       CASE
             WHEN ows.evnt.GET_ACTIVE_EVENT_BY_CODE@rpt('SMS_ON', ac.ID) IS NOT NULL
             THEN
                'SMS'
             ELSE
                CASE
                   WHEN ows.evnt.GET_ACTIVE_EVENT_BY_CODE@rpt('SMSP_ON', ac.ID)
                           IS NOT NULL
                   THEN
                      'SMSP'
                   ELSE
                      ''
                END
          END
           --cast(null as varchar2(20))
           AS SMS_notify,
          CASE
                     WHEN acs.scheme_name LIKE '%Rev%'
                     THEN
                        'REVOLVER'
                     ELSE
                        CASE
                           WHEN acs.scheme_name LIKE '%Cred%'
                           THEN
                              'REVOLVER'
                           ELSE
                              CASE
                                 WHEN acs.scheme_name LIKE '%Cink%'
                                 THEN
                                    'SALARY KAZZINK'
                                 ELSE
                                    CASE
                                       WHEN acs.scheme_name LIKE '%Stan%'
                                       THEN
                                          'STANDART'
                                       ELSE
                                          CASE
                                             WHEN acs.scheme_name LIKE
                                                     '%Vklad%'
                                             THEN
                                                'VKLAD'
                                             ELSE
                                                CASE
                                                   WHEN acs.scheme_name LIKE
                                                           '%Staf%'
                                                   THEN
                                                      'STAFF'
                                                   ELSE
                                                      CASE
                                                         WHEN acs.scheme_name LIKE
                                                                 '%Sal%'
                                                         THEN
                                                            'SALARY'
                                                         ELSE
                                                            CASE
                                                               WHEN acs.scheme_name LIKE
                                                                       '%Infinite%'
                                                               THEN
                                                                  'INFINITE'
                                                               ELSE
                                                                  CASE
                                                                     WHEN acs.scheme_name LIKE
                                                                             '%Podarok%'
                                                                     THEN
                                                                        'GIFT'
                                                                     ELSE
                                                                        CASE
                                                                           WHEN acs.scheme_name LIKE
                                                                                   '%NO INTERE%'
                                                                           THEN
                                                                              'BEZPROCENT'
                                                                           ELSE
                                                                              CASE
                                                                                 WHEN acs.scheme_name LIKE
                                                                                         '%Corp%'
                                                                                 THEN
                                                                                    'CORPORATE'
                                                                                 ELSE
                                                                                    ''
                                                                              END
                                                                        END
                                                                  END
                                                            END
                                                      END
                                                END
                                          END
                                    END
                              END
                        END
                  END acc_scheme_type,
                  ac.CCAT,
                  ac.PCAT
FROM ows.acnt_contract@rpt ac
inner join ows.CONTR_STATUS@rpt CST
on AC.CONTR_STATUS = CST.ID
  AND CST.AMND_STATE = 'A'

left join ows.SERV_PACK@rpt sp
on SP.ID = AC.SERV_PACK__ID
   AND SP.AMND_STATE = 'A'

left join OWS.currency@rpt cur
on ac.curr = cur.code
  and cur.amnd_state = 'A'

left join ows.acc_scheme@rpt acs
on acs.ID = AC.acc_scheme__ID
   AND acs.AMND_STATE = 'A'
--   and acs.ccat = 'P'

left join ows.ACC_TEMPL@rpt act
on act.code = 'L'
  AND act.amnd_state = 'A'
  and acs.ID = act.ACC_SCHEME__OID

LEFT JOIN ows.ACC_TEMPL@rpt act2
on act2.code = '!'
  AND act2.amnd_state = 'A'
  and acs.ID = act2.ACC_SCHEME__OID

left join ows.SERVICE_GROUP@rpt br
on br.amnd_state = 'A'
   AND br.code = ac.service_group
   and br.f_i=ac.f_i
   and ac.ccat=br.ccat
   and ac.pcat=br.pcat

left join ows.f_i@rpt f
on f.amnd_state = 'A'
  AND f.ID = ac.f_i

left join ows.TD_AUTH_SCH@rpt atf
on ac.id=atf.ACNT_CONTRACT__ID
  and atf.amnd_state = 'A'
  AND atf.name = 'Web Banking Static Password'
where 1=1
    and ac.amnd_state='A'
--    AND ac.PCAT NOT IN ('B', 'M')
--    AND ac.f_i NOT IN ('996', '1')
;
grant select on DWH_BUFFER.V_OWS_CONTRACT to AIBEK_BE;
grant select on DWH_BUFFER.V_OWS_CONTRACT to DWH_PRIM;
grant select on DWH_BUFFER.V_OWS_CONTRACT to DWH_RISK;
grant select on DWH_BUFFER.V_OWS_CONTRACT to DWH_SALES;
grant select on DWH_BUFFER.V_OWS_CONTRACT to HEAD_DENIS_PL;
grant select on DWH_BUFFER.V_OWS_CONTRACT to HEAD_EVGENIY_PI;
grant select on DWH_BUFFER.V_OWS_CONTRACT to KRISTINA_KO;
grant select on DWH_BUFFER.V_OWS_CONTRACT to PROCESS_RISK;
grant select on DWH_BUFFER.V_OWS_CONTRACT to PROCESS_SALES;


