create or replace force view dwh_buffer.v_dm_cif_base as
select /*-- parallel(8) */
--- Таблица G_CLI
 c.ID ID,
 c.Dep_Id DEP_ID,
 c.id || '_' || c.dep_id IN_SOURCE_ID,
 c.code CLI_CODE,
 c.dreg DATE_OPEN,
 ch.correctdt DATE_UPDATE,

 to_char(ch.residfl) RESIDENT,
 ch.birdate DATE_BIRTH,
 ch.decease_date DATE_DEATH,
 ch.psex SEX,
 ch.taxcode IIN,
 ch.bin_iin RNN, -- вот такой вот лютый пипец

 substr(c.rolemask, 6, 1) IS_EMPL, -- Роль Сотрудник
 substr(c.rolemask, 19, 1) IS_AFFIL, -- Роль Аффилированное лицо
 substr(c.rolemask, 34, 1) IS_VIP, -- Роль VIP
 (select d.code || ' ' || d.longname from col_c_dep d where d.id = c.dep_id) FILIAL, -- подразделение привязки
 c.jurfl IS_UL, -- признак юр лица
 c.pboyulfl IS_IP, -- признак ИП -- существует так же в хистори

 ch.name      CLI_NAME,
 ch.longname  FULL_NAME,
 ch.llongname ENG_NAME,
 ch.plname2   FIRST_NAME,
 ch.plname1   LAST_NAME,
 ch.plname3   PARENT_NAME,

 ch.address FACT_ADDR_DEN,
 ch.addrjur REG_ADDR_DEN,
 ch.phone   PHONE_NUM_DEN,
 ch.email   EMAIL,
 ch.fax     PHONE_NUM_FAX,

 (select name from col_G_IDENTDOCDSC_STD where id = ch.passtyp_id) DOC_NAME,
 ch.passtyp_id DOC_TYPE,
 ch.passser DOC_SERIES,
 ch.passnum DOC_NUMBER,
 ch.passorg DOC_GIVEBY,
 ch.passdat DOC_GIVEDATE,
 ch.passfin DOC_FINISHDATE,

 ch.arestfl IS_ARRESTED,
 ch.sect_id SECTOR_ID,
 ch.regorg JUSTICE_REG_ORGAN,
 ch.licnum JUSTICE_REG_NUMBER,
 ch.REGFIN JUSTICE_DATE_END,
 ch.regdate JUSTICE_DATE_REG,
 ch.okpo OKPO,
 (select code from col_T_REG_STD where id = ch.reg_id) COUNTRY_REG,

 decode(s.name, 'Карточка открыта', 1, 0) CLI_STATE -- Состояние карточки,
 --2015 04 03
 --1.  Добавить поля ID_US, TUS_ID в таблицу DM_CIF_BASE (источник G_CLIHST)
,
 ch.ID_US,
 ch.TUS_ID
  from col_G_CLI          c,
       col_g_Clihst       ch,
       col_T_PROCMEM      m,
       col_t_Process      p,
       col_T_BOP_STAT_std s
 where ch.DEP_ID = c.DEP_ID
   and ch.ID = c.ID
   and sysdate between ch.FROMDATE and ch.TODATE
   and m.ORD_ID = c.ORD_ID
   and m.DEP_ID = c.DEP_ID
   and m.MAINFL = '1'
   and p.ID = m.ID
   and p.bop_id = 5563
   and S.ID = P.BOP_ID
   and S.NORD = P.NSTAT
--and substr(c.rolemask,34,1)='0'
;
grant select on DWH_BUFFER.V_DM_CIF_BASE to AIBEK_BE;
grant select on DWH_BUFFER.V_DM_CIF_BASE to DWH_PRIM;
grant select on DWH_BUFFER.V_DM_CIF_BASE to DWH_RISK;
grant select on DWH_BUFFER.V_DM_CIF_BASE to DWH_SALES;
grant select on DWH_BUFFER.V_DM_CIF_BASE to HEAD_DENIS_PL;
grant select on DWH_BUFFER.V_DM_CIF_BASE to HEAD_EVGENIY_PI;
grant select on DWH_BUFFER.V_DM_CIF_BASE to KRISTINA_KO;
grant select on DWH_BUFFER.V_DM_CIF_BASE to PROCESS_RISK;
grant select on DWH_BUFFER.V_DM_CIF_BASE to PROCESS_SALES;


