create or replace package body dwh_buffer.ETL_20151220 is
gc_bulk_limit constant integer:=200000;
gc_Running constant varchar2(50 char):='RUNNING';
gc_Completed constant varchar2(50 char):='COMPLETED';
gc_Failed constant varchar2(50 char):='FAILED';
gv_start number;
gv_err_count number:=0;
gc_Msg_tbl_info varchar2(100 char):='';
procedure SetColvirNlsParams -- Можно работать с данными nls параметрами, это нам погоды не сделает
  as
BEGIN
  dbms_session.Set_Nls('nls_language', 'RUSSIAN');
  dbms_session.Set_NLS ('nls_territory','CIS');
  dbms_session.Set_NLS ('nls_numeric_characters','''.,''');
  dbms_session.Set_NLS ('nls_date_format','''DD.MM.RR''');
  dbms_session.Set_NLS ('nls_sort','BINARY');
  commit;
END;
procedure SetDwhNlsParams
  as
BEGIN
  dbms_session.Set_Nls('nls_language', 'RUSSIAN');
  dbms_session.Set_NLS ('nls_territory','CIS');
  dbms_session.Set_NLS ('nls_numeric_characters',''',''');
  dbms_session.Set_NLS ('nls_date_format','''DD.MM.RR''');
  dbms_session.Set_NLS ('nls_sort','BINARY');
  commit;
END;
procedure Truncate_Table(p_table_name in varchar2, p_owner in varchar2 default 'DWH_BUFFER')
  is
begin
  execute immediate ('truncate table '||p_owner||'.'||p_table_name);
exception
  when others then
    RAISE;
end;
procedure RUN_JOB(p_job_name in varchar2)
  is
begin
  dbms_scheduler.run_job(job_name => p_job_name ,use_current_session => FALSE);
exception
  when others then
    null;
end;
procedure ImportToDWH_PRIM(p_tablename in varchar2)
is
begin
  execute immediate ('grant select on '||p_tablename||' to DWH_PRIM') ;
  DWH_PRIM.TOOLS.ExportToDWH_PRIM(p_tablename,'DWH_BUFFER');
end;
function Fill_Info(
                       p_errcode in number default null,
                       p_errmsg in varchar2 default null,
                       p_err_stack in varchar2 default null,
                       p_err_call_st in varchar2 default null,
                       p_err_backtr in varchar2 default null
                       ) return xmltype deterministic parallel_enable
 is
l_result xmltype;
begin
  select
  XMLROOT(
   xmlelement("root",
    xmlelement("action"
     ,case when p_errcode is not null then
      xmlelement("error",xmlattributes(p_errcode as "sqlcode",p_errmsg as "sqlerrm")
       ,xmlelement("stacktrace",p_err_stack)
       ,xmlelement("callstack",p_err_call_st)
       ,xmlelement("backtrace",p_err_backtr)
      )
      end
    )
   )
  ,VERSION '1.0', STANDALONE YES)
  into l_result
  from dual
  ;
  return l_result;
end;
procedure Update_Etl_action(p_act_id in number,p_state in varchar2,p_duration in number,p_info in xmltype default null)
  is
 PRAGMA AUTONOMOUS_TRANSACTION;
begin
  update etl_actions_log e
  set e.state=p_state,
      e.duration=p_duration,
      e.updated=sysdate,
      e.info=p_info
  where
  e.id=p_act_id
  ;
  commit;
end;
procedure Store_Etl_Action(p_action in varchar2,p_act_id out number)
  is
 PRAGMA AUTONOMOUS_TRANSACTION;
 l_act_id etl_actions_log.id%type;
begin
  insert into etl_actions_log(id,action_name,created,updated,state,duration)
  values (etl_actions_log_seq.nextval,p_action,sysdate,null,gc_Running,null)
  returning id into l_act_id
  ;
  p_act_id:=l_act_id;
  commit;
end;
procedure Store_Etl_Tables(p_act_id in number,p_tbl_name etl_tables_log.table_name%type)
  is
 --PRAGMA AUTONOMOUS_TRANSACTION;
  k integer;
  cSQL_command VARCHAR(1000);
  st number;
begin
  st:=dbms_utility.get_time;
  cSQL_command := 'select /*+ parallel(8) */ count(1) from '||p_tbl_name;
  execute immediate cSQL_command into k;
  insert into ETL_TABLES_LOG(ID,ETL_LOG_ID,TABLE_NAME,CREATED, NUM_ROWS)
  values(ETL_TABLES_LOG_SEQ.NEXTVAL,p_act_id,upper(p_tbl_name),sysdate,k);
  commit;
  st:= (dbms_utility.get_time-st)/100;
  save_debug_log('Store_Etl_Tables. '||upper(p_tbl_name)||' run='||st);
end;
function Check_Etl_Tables(p_tbl_name etl_tables_log.table_name%type) return boolean
   is
 k_cur  integer;
 k_new  integer;
 i integer;
begin
  k_cur := 1;
  k_new := 100;
  ---begin evseev-------
  select count(*) into i from
         (select l.num_rows,trunc(l.created) created,
           ROW_NUMBER () OVER (order by created desc, id desc) AS nm
           from ETL_TABLES_LOG l
          where table_name = upper(p_tbl_name)
         ) t where  t.nm = 2;
  if i > 0 then
      select t.num_rows into k_cur from
             (select l.num_rows,trunc(l.created) created,
               ROW_NUMBER () OVER (order by created desc, id desc) AS nm
               from ETL_TABLES_LOG l
              where table_name = upper(p_tbl_name)
             ) t where  t.nm = 2;
  end if;
  select count(*) into i from
         (select l.num_rows,trunc(l.created) created,
           ROW_NUMBER () OVER (order by created desc, id desc) AS nm
           from ETL_TABLES_LOG l
          where table_name = upper(p_tbl_name)
                and trunc(l.created) = trunc(sysdate)
         ) t where  t.nm = 1;
  if i > 0 then
      select t.num_rows into k_new from
             (select l.num_rows,trunc(l.created) created,
               ROW_NUMBER () OVER (order by created desc, id desc) AS nm
               from ETL_TABLES_LOG l
              where table_name = upper(p_tbl_name)
                    and trunc(l.created) = trunc(sysdate)
             ) t where  t.nm = 1;
  end if;
  ---end evseev---------
if abs(k_cur-k_new)/k_cur*100<5 then
   return TRUE;
    else
   return FALSE;
 end if;
end;
function get_etl_log_clob(p_date in date) return clob
   is
   l_d constant varchar2(10):=' - ';
   cursor c is
   select 'action: '||e.action_name||l_d||'created: '||e.created||l_d||'updated: '||e.updated||l_d||'state: '||e.state||l_d||'dur.: '||e.duration||chr(13)||chr(10) as txt
   from etl_actions_log e
   where
   trunc(e.created)=trunc(p_date)
   order by
   e.id
   ;
   type t_tab is table of c%rowtype;
   l_t t_tab;
   l_res clob;
 begin
   open c;
   fetch c bulk collect into l_t;
   close c;
   dbms_lob.createtemporary(l_res,false,dbms_lob.call);
   for i in l_t.first..l_t.last loop
     dbms_lob.writeappend(l_res,length(l_t(i).txt),l_t(i).txt);
   end loop;
   return l_res;
 exception
   when others then
     if c%isopen then close c; end if;
     return null;
 end;
procedure Send_Etl_Results(p_date in date, success in boolean)
  is
 p_to smtp_mail.t_email_tab;
 p_cc smtp_mail.t_email_tab;
 p_attachmentlist smtp_mail.t_attachmentsclob_tab;
 p_attach smtp_mail.t_attachmentClob;
 l_er varchar2(32767);
begin
  p_to(1):='daniil.sokolov@atfbank.kz';
  --p_to(2):='Yevgenii.Pimenov@atfbank.kz';
  --p_to(3):='Laura.Sevostyanova@atfbank.kz';
  p_to(2):='Alexey.Yevseyev@atfbank.kz';
  p_to(3):='Yuriy.Khramtsov@atfbank.kz';
  p_to(4):='Denis.Pluzhnikov@atfbank.kz';
  p_attach.p_attach_name:='etl_log_'||to_char(p_date,'DD-MM-YYYY')||'.txt';
  p_attach.p_attach_mime:='text/plain';
  p_attach.p_attach_clob:=get_etl_log_clob(p_date);
  p_attachmentlist(1):=p_attach;
  smtp_mail.send_mail_clob(p_to => p_to,
                           p_from => 'DWH@atfbank.kz',
                           p_subject => 'ETL Process '||to_char(p_date,'DD-MM-YYYY'),
                           p_text_msg => 'ETL завершился '||case success when true then 'успешно' else 'НЕУСПЕШНО!' end ||' Лог во вложении.'||gc_Msg_tbl_info,
                           p_cc => p_cc,
                           p_failure => l_er,
                           p_attachmentlist => p_attachmentlist,
                           p_auto_text => 1);
end;
procedure Send_Etl_Results2(p_date in date, success in boolean)
  is
 p_to smtp_mail.t_email_tab;
 p_cc smtp_mail.t_email_tab;
 p_attachmentlist smtp_mail.t_attachmentsclob_tab;
 p_attach smtp_mail.t_attachmentClob;
 l_er varchar2(32767);
begin
  p_to(1):='daniil.sokolov@atfbank.kz';
  --p_to(2):='Yevgenii.Pimenov@atfbank.kz';
  --p_to(3):='Laura.Sevostyanova@atfbank.kz';
  p_to(2):='Alexey.Yevseyev@atfbank.kz';
  p_to(3):='Yuriy.Khramtsov@atfbank.kz';
  p_to(4):='Denis.Pluzhnikov@atfbank.kz';
  --p_to(4):='Zhanna.Akhilbaeva@atfbank.kz';
  --p_to(5):='Anelya.Orazalieva@atfbank.kz';
  --p_to(6):='Evgeniy.Shulyndin@atfbank.kz';
  p_attach.p_attach_name:='etl_log_'||to_char(p_date,'DD-MM-YYYY')||'.txt';
  p_attach.p_attach_mime:='text/plain';
  p_attach.p_attach_clob:=get_etl_log_clob(p_date);
  p_attachmentlist(1):=p_attach;
  smtp_mail.send_mail_clob(p_to => p_to,
                           p_from => 'DWH@atfbank.kz',
                           p_subject => 'ETL Process '||to_char(p_date,'DD-MM-YYYY'),
                           p_text_msg => 'ETL завершился '||case success when true then 'успешно' else 'НЕУСПЕШНО!' end ||' Лог во вложении.'||gc_Msg_tbl_info,
                           p_cc => p_cc,
                           p_failure => l_er,
                           p_attachmentlist => p_attachmentlist,
                           p_auto_text => 1);
end;
procedure Execute_Colvir_DDL_Cmd_Safe(p_cmd in varchar2)
  is
BEGIN
  colvir.etl_dwh.execute_ddl_cmd@reps(p_cmd);
Exception
  when others then
    null;
END;
function check_sysdate_state( p_proc_name ETL_ACTIONS_LOG.ACTION_NAME%type ) return ETL_ACTIONS_LOG.STATE%type
   is
  begin
    for r in
    (select l.state
     from ETL_ACTIONS_LOG l
     where trunc(l.created) = trunc(sysdate)
           and l.action_name =  upper(p_proc_name)
           and l.state<>'FAILED'
           and l.state<>'STOPPED'
    ) loop
       return r.state;
    end loop;
    return null;
  end;
----------------------------------------------------------------------------------------------------------------------------
--начало обработка
----------------------------------------------------------------------------------------------------------------------------
procedure Fill_DM_LOAN_BASE -- заполнение справочника кредитов +  DWH_PRIM
 is
  CURSOR dlb_cur IS
  SELECT *
  from colvir.etl_dm_loan_base@reps
  ;
  type t_dlb_cur_tab is table of dlb_cur%rowtype;
  l_data t_dlb_cur_tab;
  l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_DM_LOAN_BASE');
  l_action  etl_actions_log.id%type;
  i number;
begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  execute immediate ('truncate table DM_LOAN_BASE');
  open dlb_cur;
   loop
     fetch dlb_cur bulk collect into l_data limit gc_bulk_limit;
     exit when l_data.count=0;
     forall i in indices of l_data
     insert  into DM_LOAN_BASE values (
      l_data(i).ID,
      l_data(i).DEP_ID,
      l_data(i).CLI_ID,
      l_data(i).CLI_DEP_ID,
      l_data(i).CONTRACT_NUM,
      l_data(i).VAL_ID,
      l_data(i).VAL_CODE,
      l_data(i).PRD_CODE,
      l_data(i).PRD_NAME,
      l_data(i).PRD_TERM,
      l_data(i).TERM_TYPE,
      l_data(i).TERM_CNT,
      l_data(i).FROMDATE,
      l_data(i).TODATE,
      l_data(i).STATE,
      l_data(i).FIL_CODE,
      l_data(i).FIL_NAME,
      l_data(i).SUM_FULL,
      l_data(i).REFER_WH,
      l_data(i).RATE,
      l_data(i).ACC_ID,
      l_data(i).ACC_DEP_ID,
      l_data(i).ACC_PR_ID,
      l_data(i).ACC_PR_DEP_ID,
      l_data(i).SELL_DEP_ID,
      l_data(i).CSLN_FROMDATE,
      l_data(i).OBJ_ID
      );
      commit;
   end loop;
   commit;
   close dlb_cur;
   Store_Etl_Tables(l_action,'DM_LOAN_BASE');
 --Store_Etl_Tables(l_action,'DM_BAL_SNAP');
   Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    if dlb_cur%isopen then close dlb_cur; end if;
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
procedure Fill_Dep --справочник подразделений +   DWH_PRIM
  is
 cursor c_dep_cur is
 select *
 from colvir.c_dep@reps
 ;
 type t_c_dep_cur_tab is table of c_dep_cur%rowtype;
 l_dep_cur_recs t_c_dep_cur_tab;
 l_act_name constant etl_actions_log.action_name%type:=Upper('FILL_DEP');
 l_action  etl_actions_log.id%type;
begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  execute immediate ('truncate table c_dep');
  open c_dep_cur;
  loop
    fetch c_dep_cur bulk collect into l_dep_cur_recs limit gc_bulk_limit;
    exit when l_dep_cur_recs.count=0;
    forall i in indices of l_dep_cur_recs
    insert
    into c_dep
      (id,
       ID_HI,
       CODE,
       GROUPFL,
       NLEVEL,
       ARCFL,
       ARESTFL,
       CORRECTDT,
       ID_US,
       LONGNAME,
       PRIM,
       USERFL,
       OBJECTFL,
       BALFL,
       REMOTEFL,
       BUDGETFL,
       PAYFL,
       EXPENDFL,
       INCOMSFL,
       TAX_SER,
       TAX_NUM,
       TAX_DATE,
       TAX_INIT)
    values
      (l_dep_cur_recs(i).id,
       l_dep_cur_recs(i).ID_HI,
       l_dep_cur_recs(i).CODE,
       l_dep_cur_recs(i).GROUPFL,
       l_dep_cur_recs(i).NLEVEL,
       l_dep_cur_recs(i).ARCFL,
       l_dep_cur_recs(i).ARESTFL,
       l_dep_cur_recs(i).CORRECTDT,
       l_dep_cur_recs(i).ID_US,
       l_dep_cur_recs(i).LONGNAME,
       l_dep_cur_recs(i).PRIM,
       l_dep_cur_recs(i).USERFL,
       l_dep_cur_recs(i).OBJECTFL,
       l_dep_cur_recs(i).BALFL,
       l_dep_cur_recs(i).REMOTEFL,
       l_dep_cur_recs(i).BUDGETFL,
       l_dep_cur_recs(i).PAYFL,
       l_dep_cur_recs(i).EXPENDFL,
       l_dep_cur_recs(i).INCOMSFL,
       l_dep_cur_recs(i).TAX_SER,
       l_dep_cur_recs(i).TAX_NUM,
       l_dep_cur_recs(i).TAX_DATE,
       l_dep_cur_recs(i).TAX_INIT)
    ;
    commit;
  end loop;
  commit;
  close c_dep_cur;
  Store_Etl_Tables(l_action,'c_dep');
  Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    if c_dep_cur%isopen then close c_dep_cur; end if;
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
procedure Fill_DM_CIF_BASE -- Заполнение справочника клиентов. +   DWH_PRIM
  is
    CURSOR dcb_cur IS
    SELECT *
    from v_Dm_Cif_Base_20151027
    ;
    type t_dcb_tab is table of dcb_cur%rowtype index by pls_integer;
    l_data t_dcb_tab;
    l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_DM_CIF_BASE');
    l_action  etl_actions_log.id%type;
begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  execute immediate ('truncate table DM_CIF_BASE');
  open dcb_cur;
  loop
   fetch dcb_cur bulk collect into l_data limit gc_bulk_limit;
   exit when l_data.count=0;
   forall i in indices of l_data
   insert into DM_CIF_BASE AA (
    AA.ID,
    AA.DEP_ID,
    AA.IN_SOURCE_ID,
    AA.CLI_CODE,
    AA.DATE_OPEN,
    AA.DATE_UPDATE,
    AA.RESIDENT,
    AA.DATE_BIRTH,
    AA.DATE_DEATH,
    AA.SEX,
    AA.IIN,
    AA.RNN,
    AA.IS_EMPL,
    AA.IS_AFFIL,
    AA.IS_VIP,
    AA.FILIAL,
    AA.IS_UL,
    AA.IS_IP,
    AA.CLI_NAME,
    AA.FULL_NAME,
    AA.ENG_NAME,
    AA.FIRST_NAME,
    AA.LAST_NAME,
    AA.PARENT_NAME,
    AA.FACT_ADDR_DEN,
    AA.REG_ADDR_DEN,
    AA.PHONE_NUM_DEN,
    AA.EMAIL,
    AA.PHONE_NUM_FAX,
    AA.DOC_NAME,
    AA.DOC_TYPE,
    AA.DOC_SERIES,
    AA.DOC_NUMBER,
    AA.DOC_GIVEBY,
    AA.DOC_GIVEDATE,
    AA.DOC_FINISHDATE,
    AA.IS_ARRESTED,
    AA.SECTOR_ID,
    AA.JUSTICE_REG_ORGAN,
    AA.JUSTICE_REG_NUMBER,
    AA.JUSTICE_DATE_END,
    AA.JUSTICE_DATE_REG,
    AA.OKPO,
    AA.COUNTRY_REG,
    AA.CLI_STATE,
    AA.ID_US,
    AA.TUS_ID
    )
   values (
    l_data(i).ID,
    l_data(i).DEP_ID,
    l_data(i).IN_SOURCE_ID,
    l_data(i).CLI_CODE,
    l_data(i).DATE_OPEN,
    l_data(i).DATE_UPDATE,
    l_data(i).RESIDENT,
    l_data(i).DATE_BIRTH,
    l_data(i).DATE_DEATH,
    l_data(i).SEX,
    l_data(i).IIN,
    l_data(i).RNN,
    l_data(i).IS_EMPL,
    l_data(i).IS_AFFIL,
    l_data(i).IS_VIP,
    l_data(i).FILIAL,
    l_data(i).IS_UL,
    l_data(i).IS_IP,
    l_data(i).CLI_NAME,
    l_data(i).FULL_NAME,
    l_data(i).ENG_NAME,
    l_data(i).FIRST_NAME,
    l_data(i).LAST_NAME,
    l_data(i).PARENT_NAME,
    l_data(i).FACT_ADDR_DEN,
    l_data(i).REG_ADDR_DEN,
    l_data(i).PHONE_NUM_DEN,
    l_data(i).EMAIL,
    l_data(i).PHONE_NUM_FAX,
    l_data(i).DOC_NAME,
    l_data(i).DOC_TYPE,
    l_data(i).DOC_SERIES,
    l_data(i).DOC_NUMBER,
    l_data(i).DOC_GIVEBY,
    l_data(i).DOC_GIVEDATE,
    l_data(i).DOC_FINISHDATE,
    l_data(i).IS_ARRESTED,
    l_data(i).SECTOR_ID,
    l_data(i).JUSTICE_REG_ORGAN,
    l_data(i).JUSTICE_REG_NUMBER,
    l_data(i).JUSTICE_DATE_END,
    l_data(i).JUSTICE_DATE_REG,
    l_data(i).OKPO,
    l_data(i).COUNTRY_REG,
    l_data(i).CLI_STATE,
    l_data(i).ID_US,
    l_data(i).TUS_ID
    );
    commit;
  end loop;
  commit;
  close dcb_cur;
  Store_Etl_Tables(l_action,'DM_CIF_BASE');
  Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    if dcb_cur%isopen then close dcb_cur; end if;
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
procedure Fill_CS_CLI_RM_VCC ---+
  is
 cursor cs_cli_cur is
  select *
  from colvir.etl_CS_CLI_RM_VCC@reps
  ;
  type t_cs_cli_cur_table is table of cs_cli_cur%rowtype;
  l_cs_cli_cur_recs t_cs_cli_cur_table;
  l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_CS_CLI_RM_VCC');
  l_action  etl_actions_log.id%type;
begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  execute immediate ('truncate table CS_CLI_RM_VCC');
  open cs_cli_cur;
  loop
    fetch cs_cli_cur bulk collect into l_cs_cli_cur_recs limit gc_bulk_limit;
    exit when l_cs_cli_cur_recs.count=0;
    forall i in indices of l_cs_cli_cur_recs
     insert
     into CS_CLI_RM_VCC(ID,DEP_ID,VCC,RMCODE)
     values (l_cs_cli_cur_recs(i).ID,l_cs_cli_cur_recs(i).DEP_ID,l_cs_cli_cur_recs(i).VCC,l_cs_cli_cur_recs(i).RMCODE)
    ;
    forall i in indices of l_cs_cli_cur_recs
    update DM_CIF_BASE d
     set d.vcc=l_cs_cli_cur_recs(i).VCC
     where
     d.id=l_cs_cli_cur_recs(i).ID
     and d.dep_id=l_cs_cli_cur_recs(i).DEP_ID
    ;
    commit;
  end loop;
  commit;
  close cs_cli_cur;
  Store_Etl_Tables(l_action,'CS_CLI_RM_VCC');
  Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    if cs_cli_cur%isopen then close cs_cli_cur; end if;
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
procedure Fill_OWS_CLIENT_BUF --Обновление справочника клиентов WAY4 OWS_CLIENT_BUF +
  is
 cursor W4_Client_cur is
  SELECT  cl.id ows_client_id,
      cl.amnd_date,
      cl.CLIENT_NUMBER cli_code,
                  cl.ADDRESS_LINE_3 RNN,
                  cl.itn IIN,
                  cl.LAST_NAM LAST_NAME,
                  cl.FIRST_NAM FIRST_NAME,
                  cl.FATHER_S_NAM MIDDLE_NAME,
                  cl.BIRTH_DATE BIRTH_DATE,
                  cl.f_i,
                  f.NAME filial_name,
                  CL.COMPANY_NAM COMPANY_NAME,
                  cl.ADDRESS_LINE_1 address,
                  cl.PHONE,
                  cl.PHONE_H,
                  cl.PHONE_M,
                  ca.ADDRESS_ZIP as sms_phone,
                  cl.e_mail,
                  cl.tr_last_nam tr_last_name,
                  cl.tr_first_nam tr_first_name
             FROM ows.client@rpt cl
             join ows.f_i@rpt f on cl.f_i=f.id
             left join (select t.CLIENT__OID,t.ADDRESS_ZIP,row_number() over (partition by t.CLIENT__OID order by t.amnd_date desc) k
                        from ows.CLIENT_ADDRESS@rpt t where t.AMND_STATE = 'A' and t.ADDRESS_TYPE = '3') ca on cl.id=ca.CLIENT__OID and k=1
            WHERE
            cl.amnd_state = 'A' --фильтр на актуальное состояние
            AND cl.f_i NOT IN (1055, 996)
   ;
  type t_W4_Client_cur_tab is table of W4_Client_cur%rowtype;
  l_w4_client_recs t_W4_Client_cur_tab;
  l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_OWS_CLIENT_BUF');
  l_action  etl_actions_log.id%type;
begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  execute immediate ('truncate table OWS_CLIENT_BUF');
  open W4_Client_cur;
  loop
    fetch W4_Client_cur bulk collect into l_w4_client_recs limit gc_bulk_limit;
    exit when l_w4_client_recs.count=0;
    forall i in indices of l_w4_client_recs
    insert
    into OWS_CLIENT_BUF
      (OWS_CLIENT_ID,
       AMND_DATE,
       CLI_CODE,
       RNN,
       IIN,
       LAST_NAME,
       FIRST_NAME,
       MIDDLE_NAME,
       BIRTH_DATE,
       F_I,
       FILIAL_NAME,
       COMPANY_NAME,
       ADDRESS,
       PHONE,
       PHONE_H,
       PHONE_M,
       SMS_PHONE,
       E_MAIL,
       TR_LAST_NAME,
       TR_FIRST_NAME)
    values
      (l_w4_client_recs(i).ows_client_id,
       l_w4_client_recs(i).amnd_date,
       l_w4_client_recs(i).cli_code,
       l_w4_client_recs(i).RNN,
       l_w4_client_recs(i).IIN,
       l_w4_client_recs(i).LAST_NAME,
       l_w4_client_recs(i).FIRST_NAME,
       l_w4_client_recs(i).MIDDLE_NAME,
       l_w4_client_recs(i).BIRTH_DATE,
       l_w4_client_recs(i).f_i,
       l_w4_client_recs(i).filial_name,
       l_w4_client_recs(i).COMPANY_NAME,
       l_w4_client_recs(i).address,
       l_w4_client_recs(i).PHONE,
       l_w4_client_recs(i).PHONE_H,
       l_w4_client_recs(i).PHONE_M,
       l_w4_client_recs(i).sms_phone,
       l_w4_client_recs(i).e_mail,
       l_w4_client_recs(i).tr_last_name,
       l_w4_client_recs(i).tr_first_name)
    ;
    commit;
  end loop;
  commit;
  close W4_Client_cur;
  Store_Etl_Tables(l_action,'OWS_CLIENT_BUF');
  Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    if W4_Client_cur%isopen then close W4_Client_cur; end if;
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
procedure Fill_Addr --Обновление справочника адресов COLVIR dm_cif_addr +
  is
l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_Addr');
l_action  etl_actions_log.id%type;
begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  execute immediate ('truncate table dm_cif_addr');
    insert /*-- parallel(b,4) Append */
    into dm_cif_addr b
    select
    coalesce(a.CLI_CODE,b.CLI_CODE) CLI_CODE ,
    coalesce(a.id,b.id) CLI_ID ,
    coalesce(a.DEP_ID,b.DEP_ID) DEP_ID,
    a.POST_INDEX R_POST_INDEX,
    a.STRANA R_STRANA,
    a.OBL R_OBL,
    a.OBL_T R_OBL_T,
    a.DISTRICT R_DISTRICT,
    a.DISTRICT_T R_DISTRICT_T,
    a.CITY R_CITY,
    a.CITY_T R_CITY_T,
    a.TOWN R_TOWN,
    a.TOWN_T R_TOWN_T,
    a.CITY2 R_CITY2,
    a.CITY2_T R_CITY2_T,
    a.MK R_MK,
    a.MT_T R_MT_T,
    a.STREET R_STREET,
    a.STREET_T R_STREET_T,
    a.HOUSE R_HOUSE,
    a.HOUSE_T R_HOUSE_T,
    a.APT R_APT,
    a.APT_T R_APT_T,
    b.POST_INDEX F_POST_INDEX,
    b.STRANA F_STRANA,
    b.OBL F_OBL,
    b.OBL_T F_OBL_T,
    b.DISTRICT F_DISTRICT,
    b.DISTRICT_T F_DISTRICT_T,
    b.CITY F_CITY,
    b.CITY_T F_CITY_T,
    b.TOWN F_TOWN,
    b.TOWN_T F_TOWN_T,
    b.CITY2 F_CITY2,
    b.CITY2_T F_CITY2_T,
    b.MK F_MK,
    b.MT_T F_MT_T,
    b.STREET F_STREET,
    b.STREET_T F_STREET_T,
    b.HOUSE F_HOUSE,
    b.HOUSE_T F_HOUSE_T,
    b.APT F_APT,
    b.APT_T F_APT_T
    from (select * from colvir.etl_dm_cif_addr_tmp@reps where addr_type='002') a --адрес регистрации
    full outer join (select * from colvir.etl_dm_cif_addr_tmp@reps where addr_type='003') b -- фактический
    on a.id=b.id
      and a.dep_id=b.dep_id
      and a.cli_code=b.cli_code
    ;
  commit;
  Store_Etl_Tables(l_action,'dm_cif_addr');
  Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
procedure FIll_DM_CIF_PHONE_NORMAL --Обновление справочника телефонов COLVIR DM_CIF_PHONE_NORMAL +
  is
 l_act_name constant etl_actions_log.action_name%type:=Upper('FIll_DM_CIF_PHONE_NORMAL');
 l_action  etl_actions_log.id%type;
begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  execute immediate ('truncate table DM_CIF_PHONE_NORMAL');
  insert /*-- parallel(a,8) Append */
  into DM_CIF_PHONE_NORMAL a
  select distinct coalesce(a.cli_id,c.cli_id) cli_id,
          coalesce(a.dep_id,c.dep_id) dep_id,
          coalesce(a.cli_code,c.cli_code) cli_code,
          a.rab,
          a.dom,
          c.mob
    from (
    select distinct coalesce(a.cli_id,b.cli_id) cli_id,
          coalesce(a.dep_id,b.dep_id) dep_id,
          coalesce(a.cli_code,b.cli_code) cli_code,
          a.rab,
          b.dom
    from
    (select c.id cli_id,
          c.dep_id,
          c.code CLI_CODE,
          LISTAGG(t.pnum,', ') WITHIN GROUP (order by nvl(t.basfl,0), nvl(correctdt,to_date('01.01.1900','dd.mm.yyyy')))  rab
    from colvir.G_CLIPHONE@reps t,
    colvir.g_cli@reps c
    where c.id = t.id
    and c.dep_id = t.dep_id
    and t.arcfl = 0
    and t.ptype in ('0'-- рабочий
                    --,'1'-- домашний
                    --,'3' -- мобильный
                    )
    and t.pnum is not null
    group by c.id,
          c.dep_id,
          c.code) a
    full outer join
    (select c.id cli_id,
          c.dep_id,
          c.code CLI_CODE,
          LISTAGG(t.pnum,', ') WITHIN GROUP (order by nvl(t.basfl,0), nvl(correctdt,to_date('01.01.1900','dd.mm.yyyy')))  dom
    from colvir.G_CLIPHONE@reps t,
    colvir.g_cli@reps c
    where c.id = t.id
    and c.dep_id = t.dep_id
    and t.arcfl = 0
    and t.ptype in (--'0'-- рабочий
                    --,
                    '1'-- домашний
                    --,'3' -- мобильный
                    )
    and t.pnum is not null
    group by c.id,
          c.dep_id,
          c.code) b
    on a.cli_id=b.cli_id
      and a.dep_id=b.dep_id
      and a.cli_code=b.cli_code
    ) a
    full outer join
    (select c.id cli_id,
          c.dep_id,
          c.code CLI_CODE,
          LISTAGG(t.pnum,', ') WITHIN GROUP (order by nvl(t.basfl,0), nvl(correctdt,to_date('01.01.1900','dd.mm.yyyy')))  mob
    from colvir.G_CLIPHONE@reps t,
    colvir.g_cli@reps c
    where c.id = t.id
    and c.dep_id = t.dep_id
    and t.arcfl = 0
    and t.ptype in (--'0'-- рабочий
                    --,'1'-- домашний
                    --,
                    '3' -- мобильный
                    )
    and t.pnum is not null
    group by c.id,
          c.dep_id,
          c.code) c
    on a.cli_id=c.cli_id
      and a.dep_id=c.dep_id
      and a.cli_code=c.cli_code
   ;
   commit;
   Store_Etl_Tables(l_action,'DM_CIF_PHONE_NORMAL');
   Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
procedure Fill_dm_acc_base --Обновление справочника счетов COLVIR dm_acc_base +
  is
 CURSOR dab_cur IS
  SELECT *
  from V_DM_ACC_BASE_20151027
  ;
 type t_dab_cur_table is table of dab_cur%rowtype;
 l_data t_dab_cur_table;
 l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_dm_acc_base');
 l_action  etl_actions_log.id%type;
begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  save_debug_log('Fill_dm_acc_base.  1.');
  execute immediate ('truncate table DM_ACC_BASE');
  save_debug_log('Fill_dm_acc_base.  2.');
  open dab_cur;
  loop
   fetch dab_cur bulk collect into l_data limit gc_bulk_limit;
   exit when l_data.count=0;
   forall i in indices of l_data
   insert /*+ parallel(16) append*/
   into DM_ACC_BASE values (
    l_data(i).ID,
    l_data(i).DEP_ID,
    l_data(i).IN_SOURCE_ID,
    l_data(i).ID_BAL,
    l_data(i).CLI_ID,
    l_data(i).CLI_DEP_ID,
    l_data(i).CLI_CODE,
    l_data(i).ACC_CODE,
    l_data(i).BAL_CODE,
    l_data(i).BAL3,
    l_data(i).ACC_NAME,
    nvl(l_data(i).VAL_ID,1),
    nvl(l_data(i).VAL_CODE,'KZT'),
    l_data(i).ACC_STATE,
    l_data(i).STATE_ID,
    l_data(i).LAST_TRN,
    l_data(i).DATE_OPEN,
    l_data(i).DATE_CLOSE)
    ;
  end loop;
  commit;
  save_debug_log('Fill_dm_acc_base.  3.');
  Store_Etl_Tables(l_action,'DM_ACC_BASE');
  save_debug_log('Fill_dm_acc_base.  4.');
  Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
procedure Fill_DM_DELAY_CURR --Обновление справочника текущей просрочки COLVIR DM_DELAY_CURR +
  is
 l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_DM_DELAY_CURR');
 l_action  etl_actions_log.id%type;
begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  execute immediate ('truncate table DM_DELAY_CURR');
  insert /*-- parallel(a,8) Append*/
  into DM_DELAY_CURR a
  /* изменилась структура в колвире, тупо добавил имена столбцов 22.10.2014 */
    select
    q_id        ,
  dea_refer    ,
  id          ,
  c.dep_id       ,
  c.cli_id       ,
  c.cli_dep_id   ,
  bal_od_num   ,
  bal_od_sum   ,
  bal_od_code  ,
  bal_prc_num  ,
  bal_prc_sum  ,
  bal_prc_code ,
  off_od_num   ,
  off_od_sum   ,
  off_od_code  ,
  off_prc_num  ,
  off_prc_sum  ,
  off_prc_code ,
  dpr          ,
  dod          ,
  max_delay    ,
  is_restr     ,
  datefrom     ,
  is_collector
    from DM_LOAN_BASE d
    inner join collie.tmp_atf_prosr_dea@reps c
    on d.contract_id=c.id
   ;
  commit;
  Store_Etl_Tables(l_action,'DM_DELAY_CURR');
  Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
procedure Fill_DM_BAL_SNAP --Обновление текущих остатков COLVIR DM_BAL_SNAP +
  is
 l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_DM_BAL_SNAP');
 l_action  etl_actions_log.id%type;
 i number;
begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  execute immediate ('truncate table T_BAL_tmp_2');
  insert /*+ parallel (b,4) append */
  into T_BAL_tmp_2
  select /*--parallel (b,4) append*/
         b.*,
         LEAD(fromdate, 1) over(partition by DEP_ID, ID, VAL_ID, FLZO, PLANFL order by fromdate) todate,
         lag(fromdate, 1) over(partition by DEP_ID, ID, VAL_ID, FLZO, PLANFL order by fromdate) beforedate
    from colvir.T_BAL@reps b
   where 1 = 1
     and b.fromdate >= trunc(sysdate, 'mm')
     and b.fromdate < add_months(trunc(sysdate, 'mm'), 1)
  ;
  commit;
  Store_Etl_Tables(l_action,'T_BAL_tmp_2');
  execute immediate ('truncate table DM_BAL_SNAP_TMP');
  insert /*+ parallel(8) append */ /*-- parallel(b,8) Append*/
  into DM_BAL_SNAP_TMP b
  select val_id,
         DEP_ID,
         acc_id,
         sum(nvl(BAL_OUT, 0)) BAL_OUT,
         trunc(sysdate - 1) SNAP_date
    from (select val_id, DEP_ID, id acc_id, flzo, PLANFL, BAL_OUT
            from T_BAL_tmp_2 a
           where 1 = 1
             and a.TODATE is null
          union
          select val_id, DEP_ID, acc_id, flzo, PLANFL, BAL_OUT
            from DM_ALL_BAL_AGG d
           where 1 = 1
             and d.MONTH_YEAR = add_months(trunc(sysdate, 'mm'), -1)
             and not exists (select 1
                    from T_BAL_tmp_2 a
                   where 1 = 1
                     and a.TODATE is null
                     and a.val_id = d.val_id
                     and a.id = d.acc_id
                     and a.DEP_ID = d.DEP_ID
                     and a.flzo = d.flzo
                     and a.PLANFL = d.PLANFL))
   group by
   val_id, DEP_ID, acc_id, trunc(sysdate - 1)
   ;
  commit;
  Store_Etl_Tables(l_action,'DM_BAL_SNAP_TMP');
  select /*+ parallel(8) */ count(1) into i from DM_BAL_SNAP_TMP;
  if i>0 then
      execute immediate ('alter table DM_BAL_SNAP drop constraint PK_BAL_SNAP cascade');
      execute immediate ('truncate table DM_BAL_SNAP');
      --execute immediate ('ALTER INDEX PK_BAL_SNAP REBUILD');
      insert /*+ parallel(8) append*/   /*-- parallel(b,8) Append*/
      into DM_BAL_SNAP
      select * from DM_BAL_SNAP_TMP
      ;
      commit;
      execute immediate ('
          alter table DM_BAL_SNAP
            add constraint PK_BAL_SNAP primary key (ACC_ID, VAL_ID)
            using index
            tablespace DWH_BUFFER
            pctfree 10
            initrans 2
            maxtrans 255
            storage
            (
              initial 50M
              next 10M
              minextents 1
              maxextents unlimited
            )
      ');
  end if;
 Store_Etl_Tables(l_action,'DM_BAL_SNAP');
 Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
procedure Fill_dm_dep_base --Обновление справочника депозитов COLVIR dm_dep_base +
  is
 l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_dm_dep_base');
 l_action  etl_actions_log.id%type;
begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  merge /*-- parallel(t,8) */
  into dm_dep_base t
  using
  (
  select d.prc,d.clc_id,d.prc_id,d.bop_id,d.id,d.dep_id,d.cli_id,d.cli_dep_id,d.acc_id,
        d.acc_dep_id, d.first_fromdate,d.fromdate,d.todate,
        d.prd_code,d.prd_name,d.prd_term,d.term_type,d.term_cnt,d.val_code,d.cnt_prolong,
        d.state,d.state_cat,d.fil_code,d.fil_name,d.amount,d.SELL_DEP_ID
  from colvir.etl_dep_base_2@reps d
         ) a
  on (t.ID=a.id
      and t.dep_id=a.dep_id)
  when matched then update set
  t.CLC_ID=a.CLC_ID,
  t.PRC_ID=a.PRC_ID,
  t.BOP_ID=a.BOP_ID,
  t.CLI_ID=a.CLI_ID,
  t.CLI_DEP_ID=a.CLI_DEP_ID,
  t.ACC_ID=a.ACC_ID,
  t.ACC_DEP_ID=a.ACC_DEP_ID,
  t.FIRST_FROMDATE=a.FIRST_FROMDATE,
  t.FROMDATE=a.FROMDATE,
  t.TODATE=a.TODATE,
  t.PRD_CODE=a.PRD_CODE,
  t.PRD_NAME=a.PRD_NAME,
  t.PRD_TERM=a.PRD_TERM,
  t.TERM_TYPE=a.TERM_TYPE,
  t.TERM_CNT=a.TERM_CNT,
  t.VAL_CODE=a.VAL_CODE,
  t.CNT_PROLONG=a.CNT_PROLONG,
  t.STATE=a.STATE,
  t.STATE_CAT=a.STATE_CAT,
  t.FIL_CODE=a.FIL_CODE,
  t.FIL_NAME=a.FIL_NAME,
  t.amount=a.amount,
  t.SELL_DEP_ID = a.SELL_DEP_ID
  when not matched then insert
  (t.PRC,
  t.CLC_ID,
  t.PRC_ID,
  t.BOP_ID,
  t.ID,
  t.DEP_ID,
  t.CLI_ID,
  t.CLI_DEP_ID,
  t.ACC_ID,
  t.ACC_DEP_ID,
  t.FIRST_FROMDATE,
  t.FROMDATE,
  t.TODATE,
  t.PRD_CODE,
  t.PRD_NAME,
  t.PRD_TERM,
  t.TERM_TYPE,
  t.TERM_CNT,
  t.VAL_CODE,
  t.CNT_PROLONG,
  t.STATE,
  t.STATE_CAT,
  t.FIL_CODE,
  t.FIL_NAME,
  t.amount,
  t.Sell_Dep_Id)
  values
  (a.PRC,
  a.CLC_ID,
  a.PRC_ID,
  a.BOP_ID,
  a.ID,
  a.DEP_ID,
  a.CLI_ID,
  a.CLI_DEP_ID,
  a.ACC_ID,
  a.ACC_DEP_ID,
  a.FIRST_FROMDATE,
  a.FROMDATE,
  a.TODATE,
  a.PRD_CODE,
  a.PRD_NAME,
  a.PRD_TERM,
  a.TERM_TYPE,
  a.TERM_CNT,
  a.VAL_CODE,
  a.CNT_PROLONG,
  a.STATE,
  a.STATE_CAT,
  a.FIL_CODE,
  a.FIL_NAME,
  a.amount,
  a.sell_dep_id)
  ;
 commit;
 Store_Etl_Tables(l_action,'dm_dep_base');
 Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
procedure Fill_Client_all ---+
  is
type t_client_map_tab is table of CLIENT_MAP%rowtype;
l_client_map_recs t_client_map_tab;
l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_Client_all');
l_action  etl_actions_log.id%type;
begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  save_debug_log('Fill_Client_all 1');
  execute immediate ('alter table CLIENT_ALL drop constraint PK_KSSS cascade');
  insert /*--parallel(8) append*/
  into client_all
  select client_seq.NEXTVAL ksss_id,
         ows_client_id client_src,
         'W' src,
         cli_code,
         case when length(regexp_replace(iin, '[^0-9]', '')) = 12 then regexp_replace(iin, '[^0-9]', '') else null end iin,
         case when length(regexp_replace(rnn, '[^0-9]', '')) = 12 then regexp_replace(rnn, '[^0-9]', '') else null end rnn
  from OWS_CLIENT_BUF a
  where not exists (select 1 from client_all b where 1 = 1 and b.client_src = a.ows_client_id and b.src = 'W')
  ;
  insert /*-- parallel(8) append*/
  into client_all
  select client_seq.NEXTVAL ksss_id,
         id client_src,
         'C' src,
         cli_code,
         case when length(regexp_replace(iin, '[^0-9]', '')) = 12 then regexp_replace(iin, '[^0-9]', '') else null end iin,
         case when length(regexp_replace(rnn, '[^0-9]', '')) = 12 then regexp_replace(rnn, '[^0-9]', '') else null end rnn
  from dm_cif_base a
  where not exists (select 1 from client_all b where 1 = 1 and b.client_src = a.id and b.src = 'C')
  ;
  commit;
  execute immediate (
  'alter table CLIENT_ALL
    add constraint PK_KSSS primary key (KSSS_ID)
    using index
    tablespace DWH_BUFFER
    pctfree 10
    initrans 2
    maxtrans 255
    storage
    (
      initial 10M
      next 20M
      minextents 1
      maxextents unlimited
    )'
  );
  save_debug_log('Fill_Client_all 2');
  execute immediate ('truncate table client_iin_clear');
  save_debug_log('Fill_Client_all 3');
  insert /*-- parallel(8) append*/
  into client_iin_clear
  select iin, count(*) cnt from client_all
  where iin is not null
  GROUP BY iin
  ;
  execute immediate ('truncate table client_rnn_clear');
  insert /*-- parallel(8) append*/
  into client_rnn_clear
  select rnn, count(*) cnt
  from client_all
  where rnn is not null
  GROUP BY rnn
  ;
  execute immediate ('truncate table client_cli_code_clear');
  insert /*-- parallel(8) append*/
  into client_cli_code_clear
  select cli_code, count(*) cnt
  from client_all
  where cli_code is not null
  GROUP BY cli_code
  ;
  with client_map_1 as (
     select ksss_id,
         case when i.iin is not null then min(ksss_id) over (partition by i.iin) else ksss_id end iin_ksss_id
         ,case when r.rnn is not null then min(ksss_id) over (partition by r.rnn) else ksss_id end rnn_ksss_id
         ,case when c.cli_code is not null then min(ksss_id) over (partition by c.cli_code) else ksss_id end cli_code_ksss_id
         ,least(case when i.iin is not null then min(ksss_id) over (partition by i.iin) else ksss_id end,
                case when r.rnn is not null then min(ksss_id) over (partition by r.rnn) else ksss_id end,
                case when c.cli_code is not null then min(ksss_id) over (partition by c.cli_code)
                     else ksss_id end) min_ksss_id
     from client_all ca
     left join client_iin_clear i on i.iin = ca.iin and i.cnt<=6
     left join client_rnn_clear r on r.rnn = ca.rnn and r.cnt<=6
     left join client_cli_code_clear c on c.cli_code = ca.cli_code and c.cnt<=6
  )
  select cm.KSSS_ID,
         least(min(min_ksss_id) over(partition by iin_ksss_id),
               min(min_ksss_id) over(partition by rnn_ksss_id),
               min(min_ksss_id) over(partition by cli_code_ksss_id)) agr_id,
         ca.CLIENT_SRC,
         ca.SRC
  bulk collect into l_client_map_recs
  from client_map_1 cm
  inner join client_all ca on cm.ksss_id = ca.ksss_id
  ;
  execute immediate ('truncate table CLIENT_MAP');
  forall i in indices of l_client_map_recs
  insert  into CLIENT_MAP values l_client_map_recs(i)
  ;
  commit;
  save_debug_log('Fill_Client_all 4');
  execute immediate ('drop index IX_CLIENT_AGR_ID');
  execute immediate ('drop index IX_CLIENT_CLI_ID');
  execute immediate ('truncate table client');
  save_debug_log('Fill_Client_all 5');
  insert /*-- parallel(16) append*/  /*-- paralle(8) Append */
  into client
  select distinct
     cm.agr_id,
     first_value(c.id) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) cli_id,
     first_value(c.dep_id) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) dep_id,
     first_value(c.cli_code) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) cli_code,
     first_value(c.date_open) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) date_open,
     first_value(c.DATE_UPDATE) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) DATE_UPDATE_C,
     first_value(w.ows_client_id) over(partition by cm.AGR_ID order by w.amnd_date desc nulls last) ows_client_id,
     first_value(w.amnd_date) over(partition by cm.AGR_ID order by w.amnd_date desc nulls last) DATE_UPDATE_W,
     first_value(w.company_name) over(partition by cm.AGR_ID order by w.amnd_date desc nulls last) company_name,
     first_value(c.resident) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) resident,
     first_value(c.date_birth) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) birth_date,
     first_value(c.date_death) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) death_date,
     first_value(c.sex) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) sex,
     first_value(case
                   when length(regexp_replace(nvl(c.iin, w.iin), '[^0-9]', '')) = 12
                   then regexp_replace(nvl(c.iin, w.iin), '[^0-9]', '')
                   else null
                 end)
           over(partition by cm.AGR_ID order by regexp_replace(nvl(c.iin, w.iin), '[^0-9]', '') desc nulls last
                , nvl(c.DATE_UPDATE, w.amnd_date) desc nulls last) iin,
     first_value(case
                   when length(regexp_replace(nvl(c.rnn, w.rnn), '[^0-9]', '')) = 12
                   then regexp_replace(nvl(c.rnn, w.rnn), '[^0-9]', '')
                   else null
                 end)
         over(partition by cm.AGR_ID order by regexp_replace(nvl(c.rnn, w.rnn), '[^0-9]', '') desc nulls last
              , nvl(c.DATE_UPDATE, w.amnd_date) desc nulls last) rnn,
     first_value(c.is_empl) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) is_empl,
     first_value(c.is_affil) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) is_affil,
     first_value(c.is_vip) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) is_vip,
     first_value(c.is_ul) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) is_ul,
     first_value(c.is_ip) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) is_ip,
     first_value(trim(upper(regexp_replace(c.cli_name,'[ ]+',' '))))
                 over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) short_name,
     first_value(trim(upper(regexp_replace(c.full_name,'[ ]+',' '))))
                 over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) full_name,
     first_value(trim(upper(regexp_replace(c.eng_name,'[ ]+',' '))))
                 over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) eng_name,
     first_value(trim(upper(regexp_replace(w.tr_last_name,'[ ]+',' '))))
                 over(partition by cm.AGR_ID order by w.amnd_date desc nulls last) tr_last_name,
     first_value(trim(upper(regexp_replace(w.tr_first_name,'[ ]+',' '))))
                 over(partition by cm.AGR_ID order by w.amnd_date desc nulls last) tr_first_name,
     first_value(trim(upper(regexp_replace(c.first_name,'[ ]+',' '))))
                 over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) first_name,
     first_value(trim(upper(regexp_replace(c.parent_name,'[ ]+',' '))))
                 over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) middle_name,
     first_value(trim(upper(regexp_replace(c.last_name,'[ ]+',' '))))
                 over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) last_name,
     first_value(c.doc_type) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) doc_type,
     first_value(c.doc_series) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) doc_series,
     first_value(c.doc_number) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) doc_number,
     first_value(trim(upper(c.doc_giveby))) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) doc_giveby,
     first_value(c.doc_givedate) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) doc_givedate,
     first_value(c.doc_finishdate) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) doc_finishdate,
     first_value(c.is_arrested) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) is_arrested,
     first_value(c.okpo) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) okpo,
     first_value(c.country_reg) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) country_reg,
     first_value(c.cli_state) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) cli_state,
     first_value(c.vcc) over(partition by cm.AGR_ID order by c.DATE_UPDATE desc nulls last) vcc
  from CLIENT_MAP cm
  left join dm_cif_base c on c.id = cm.client_src and cm.src = 'C'
  left join OWS_CLIENT_BUF w on w.ows_client_id = cm.client_src and cm.src = 'W'
  ;
  commit;
  save_debug_log('Fill_Client_all 6');
  execute immediate ('
        create unique index IX_CLIENT_AGR_ID on CLIENT (AGR_ID)
            tablespace DWH_BUFFER
            pctfree 10
            initrans 2
            maxtrans 255
            storage
            (
              initial 10M
              next 20M
              minextents 1
              maxextents unlimited
            )
    ');
  execute immediate ('
        create unique index IX_CLIENT_CLI_ID on CLIENT (CLI_ID, DEP_ID)
          tablespace DWH_BUFFER
          pctfree 10
          initrans 2
          maxtrans 255
          storage
          (
            initial 10M
            next 20M
            minextents 1
            maxextents unlimited
          )
    ');
  Store_Etl_Tables(l_action,'client_all');
  Store_Etl_Tables(l_action,'CLIENT_MAP');
  Store_Etl_Tables(l_action,'client');
  Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
procedure Fill_Delay_Regular ---+
  is
l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_Delay_Regular');
l_action  etl_actions_log.id%type;
begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
 delete from DM_DELAY_HIST
  where month_year = add_months(trunc(sysdate, 'mm'), -1)
 ;
 insert
 into DM_DELAY_HIST
  SELECT c.DEP_ID,
    c.DEA_ID,
    c.DCL_ID,
    c.CLI_DEP_ID,
    c.CLI_ID,
    c.VAL_ID,
    c.MAX_DELAY,
    c.MAX_DELAY_DATE,
    c.EXP,
    c.LLP_FOR_ISL_PROV,
    c.PD,
    c.LGD_T_EOP,
    c.LLP,
    c.LLP2,
    c.NORD,
    c.STAT,
    c.ERR,
    c.EXP_NAT,
    c.RESTRUK,
    c.RESTRUK_DATE,
    c.OBJ_ID,
    trunc(c.DOPER,'mm'),
    c.L_DEP_ID,
    c.L_DEA_ID,
    c.CODE,
    c.CODE_CLI,
    c.FROMDATE,
    c.TODATE,
    c.APRVALUE,
    c.CR_INTER,
    c.CSLN_TYPE,
    c.INDUSTRIES,
    c.RESTRUK_TAB,
    c.DELAY_TAB,
    c.RESTRUK_CODE,
    c.LGD_UNSEC,
    c.LLP_BAL,
    c.REFER,
    c.OD_SUM,
    c.PRC_SUM,
    c.OD_SUM_NAT,
    c.PRC_SUM_NAT,
    c.TYP
  FROM colvir.ATF_IFRS_L_DEA_ARC@reps c
  inner join DM_LOAN_BASE d
  on d.CONTRACT_ID=c.dea_id
  where 1=1
      and max_delay>0
      and trunc(c.DOPER,'mm')=add_months(trunc(sysdate,'mm'),-1)
  ;
  commit;
  Store_Etl_Tables(l_action,'DM_DELAY_HIST');
  Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
/*
procedure Fill_W4_Contract ---+
is
  CURSOR w4_cur IS SELECT * from v_ows_contract;
  type t_w4_cur_table is table of w4_cur%rowtype;
  l_w4_recs t_w4_cur_table;
  l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_W4_Contract');
  l_action  etl_actions_log.id%type;
  i integer;
begin
\*  select count(*) into i from ETL_ACTIONS_LOG t where t.action_name = 'FILL_W4_CONTRACT'
               and trunc(t.created) = trunc(sysdate)
               and t.state='FAILED';
  if i > 0 then
     dbms_lock.sleep(300);
  end if;    *\
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  execute immediate ('truncate table ows_contract_buf');
  open w4_cur;
  loop
    fetch w4_cur bulk collect into l_w4_recs limit gc_bulk_limit;
    exit when l_w4_recs.count=0;
    forall i in indices of l_w4_recs
    insert into ows_contract_buf values
    (l_w4_recs(i).AMND_DATE,
    l_w4_recs(i).OWS_CONTRACT_ID,
    l_w4_recs(i).CON_CAT,
    l_w4_recs(i).CONTRACT_NUMBER,
    l_w4_recs(i).CONTRACT_NAME,
    l_w4_recs(i).COMMENT_TEXT,
    l_w4_recs(i).OWS_CLIENT_ID,
    l_w4_recs(i).ACNT_CONTRACT__OID,
    l_w4_recs(i).AUTH_LIMIT_AMOUNT,
    l_w4_recs(i).BASE_AUTH_LIMIT,
    l_w4_recs(i).LIAB_BALANCE,
    l_w4_recs(i).LIAB_BLOCKED,
    l_w4_recs(i).OWN_BALANCE,
    l_w4_recs(i).OWN_BLOCKED,
    l_w4_recs(i).SUB_BALANCE,
    l_w4_recs(i).SUB_BLOCKED,
    l_w4_recs(i).TOTAL_BALANCE,
    l_w4_recs(i).TOTAL_BLOCKED,
    l_w4_recs(i).SHARED_BALANCE,
    l_w4_recs(i).SHARED_BLOCKED,
    l_w4_recs(i).AMOUNT_AVAILABLE,
    l_w4_recs(i).DATE_OPEN,
    l_w4_recs(i).DATE_EXPIRE,
    l_w4_recs(i).LAST_BILLING_DATE,
    l_w4_recs(i).NEXT_BILLING_DATE,
    l_w4_recs(i).LAST_SCAN,
    l_w4_recs(i).CARD_EXPIRE,
    l_w4_recs(i).RBS_NUMBER,
    l_w4_recs(i).LIMIT_IS_ACTIVE,
    l_w4_recs(i).IS_READY,
    l_w4_recs(i).BILLING_CONTRACT,
    l_w4_recs(i).CONTRACT_STATUS,
    l_w4_recs(i).SERVICE_PACK_NAME,
    l_w4_recs(i).SERVICE_PACK_CODE,
    l_w4_recs(i).CURRENCY_CODE,
    l_w4_recs(i).CURRENCY_NAME,
    l_w4_recs(i).SCHEME_CODE,
    l_w4_recs(i).SCHEME_NAME,
    l_w4_recs(i).L_INTEREST_RATE,
    l_w4_recs(i).INTEREST_RATE,
    l_w4_recs(i).BRANCH_NAME,
    l_w4_recs(i).BRANCH_CODE,
    l_w4_recs(i).FILIAL_NAME,
    l_w4_recs(i).FILIAL_ID,
    l_w4_recs(i).PLASTIC_TYPE,
    l_w4_recs(i).WEB_BANKING,
    l_w4_recs(i).SMS_NOTIFY,
    l_w4_recs(i).acc_scheme_type,
    l_w4_recs(i).CCAT,
    l_w4_recs(i).PCAT
    )
    ;
    commit;
  end loop;
  commit;
  close w4_cur;
  execute immediate ('truncate table ows_contract');
  insert \*-- parallel(bb,8) Append*\ into ows_contract bb
  select distinct trans_rec.AMND_DATE,
                  trans_rec.OWS_CONTRACT_ID,
                  trans_rec.CON_CAT,
                  trans_rec.CONTRACT_NUMBER,
                  trans_rec.CONTRACT_NAME,
                  trans_rec.COMMENT_TEXT,
                  trans_rec.OWS_CLIENT_ID,
                  trans_rec.ACNT_CONTRACT__OID,
                  trans_rec.AUTH_LIMIT_AMOUNT,
                  trans_rec.BASE_AUTH_LIMIT,
                  trans_rec.LIAB_BALANCE,
                  trans_rec.LIAB_BLOCKED,
                  trans_rec.OWN_BALANCE,
                  trans_rec.OWN_BLOCKED,
                  trans_rec.SUB_BALANCE,
                  trans_rec.SUB_BLOCKED,
                  trans_rec.TOTAL_BALANCE,
                  trans_rec.TOTAL_BLOCKED,
                  trans_rec.SHARED_BALANCE,
                  trans_rec.SHARED_BLOCKED,
                  trans_rec.AMOUNT_AVAILABLE,
                  trans_rec.DATE_OPEN,
                  trans_rec.DATE_EXPIRE,
                  trans_rec.LAST_BILLING_DATE,
                  trans_rec.NEXT_BILLING_DATE,
                  trans_rec.LAST_SCAN,
                  trans_rec.CARD_EXPIRE,
                  trans_rec.RBS_NUMBER,
                  trans_rec.LIMIT_IS_ACTIVE,
                  trans_rec.IS_READY,
                  trans_rec.BILLING_CONTRACT,
                  trans_rec.CONTRACT_STATUS,
                  trans_rec.SERVICE_PACK_NAME,
                  trans_rec.SERVICE_PACK_CODE,
                  trans_rec.CURRENCY_CODE,
                  trans_rec.CURRENCY_NAME,
                  trans_rec.SCHEME_CODE,
                  trans_rec.SCHEME_NAME,
                  trans_rec.L_INTEREST_RATE,
                  trans_rec.INTEREST_RATE,
                  first_value(trans_rec.BRANCH_NAME) over(partition by trans_rec.OWS_CONTRACT_ID order by trans_rec.BRANCH_CODE) BRANCH_NAME,
                  first_value(trans_rec.BRANCH_CODE) over(partition by trans_rec.OWS_CONTRACT_ID order by trans_rec.BRANCH_CODE) BRANCH_CODE,
                  trans_rec.FILIAL_NAME,
                  trans_rec.FILIAL_ID,
                  trans_rec.PLASTIC_TYPE,
                  trans_rec.WEB_BANKING,
                  trans_rec.SMS_NOTIFY,
                  trans_rec.acc_scheme_type,
                  trans_rec.CCAT,
                  trans_rec.PCAT
    from ows_contract_buf trans_rec
    ;
  --Added 09.09.2014 Chervoniy_y
  execute immediate ('truncate table ows_card_activation_2');
  insert \*-- parallel(a,8) Append*\ into ows_card_activation_2 a
  select CONTRACT_NUMBER, acnt_contract__oid, amnd_date, chng,amnd_officer
    from (SELECT AC.PRODUCTION_STATUS,
                 CONTRACT_NUMBER,
                 amnd_date,
                 ac.acnt_contract__oid,
                 AC.PRODUCTION_STATUS || '<-' ||
                 lead(AC.PRODUCTION_STATUS, 1) over(partition by CONTRACT_NUMBER, ac.acnt_contract__oid order by amnd_date desc) chng,
                 amnd_officer
            FROM OWS.ACNT_CONTRACT@rpt AC
           WHERE 1 = 1
             and con_cat = 'C'
           order by amnd_date
           )
  ;
 commit;
 Store_Etl_Tables(l_action,'ows_contract_buf');
 Store_Etl_Tables(l_action,'ows_contract');
 Store_Etl_Tables(l_action,'ows_card_activation_2');
 insert into OWS_CONTRACT_SNAP
 select t.*,sysdate as SDT  from OWS_CONTRACT t
 ;
 commit;
 Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
*/
procedure Fill_W4_Contract ---+
is
    CURSOR w4_cur IS SELECT /*+parallel(8)*/ * from v_ows_contract;
    type t_w4_cur_table is table of w4_cur%rowtype;
    l_w4_recs t_w4_cur_table;
    l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_W4_Contract');
    l_action  etl_actions_log.id%type;
    i integer;
begin
  /*  select count(*) into i from ETL_ACTIONS_LOG t where t.action_name = 'FILL_W4_CONTRACT'
  and trunc(t.created) = trunc(sysdate)
  and t.state='FAILED';
  if i > 0 then
  dbms_lock.sleep(300);
  end if;    */
if check_sysdate_state (l_act_name) is null then
BEGIN
    gv_start:=dbms_utility.get_time;
    Store_Etl_Action(l_act_name,l_action);
    save_debug_log('Fill_W4_Contract.  1.');
    execute immediate ('truncate table ows_contract_buf');
    save_debug_log('Fill_W4_Contract.  2.');
    open w4_cur;
    save_debug_log('Fill_W4_Contract.  2.1.');
    loop
    fetch w4_cur bulk collect into l_w4_recs limit 3000000; --gc_bulk_limit;
    exit when l_w4_recs.count=0;
    forall i in indices of l_w4_recs
                  insert /*+ append */
                  into ows_contract_buf values
                  (l_w4_recs(i).AMND_DATE,
                  l_w4_recs(i).OWS_CONTRACT_ID,
                  l_w4_recs(i).CON_CAT,
                  l_w4_recs(i).CONTRACT_NUMBER,
                  l_w4_recs(i).CONTRACT_NAME,
                  l_w4_recs(i).COMMENT_TEXT,
                  l_w4_recs(i).OWS_CLIENT_ID,
                  l_w4_recs(i).ACNT_CONTRACT__OID,
                  l_w4_recs(i).AUTH_LIMIT_AMOUNT,
                  l_w4_recs(i).BASE_AUTH_LIMIT,
                  l_w4_recs(i).LIAB_BALANCE,
                  l_w4_recs(i).LIAB_BLOCKED,
                  l_w4_recs(i).OWN_BALANCE,
                  l_w4_recs(i).OWN_BLOCKED,
                  l_w4_recs(i).SUB_BALANCE,
                  l_w4_recs(i).SUB_BLOCKED,
                  l_w4_recs(i).TOTAL_BALANCE,
                  l_w4_recs(i).TOTAL_BLOCKED,
                  l_w4_recs(i).SHARED_BALANCE,
                  l_w4_recs(i).SHARED_BLOCKED,
                  l_w4_recs(i).AMOUNT_AVAILABLE,
                  l_w4_recs(i).DATE_OPEN,
                  l_w4_recs(i).DATE_EXPIRE,
                  l_w4_recs(i).LAST_BILLING_DATE,
                  l_w4_recs(i).NEXT_BILLING_DATE,
                  l_w4_recs(i).LAST_SCAN,
                  l_w4_recs(i).CARD_EXPIRE,
                  l_w4_recs(i).RBS_NUMBER,
                  l_w4_recs(i).LIMIT_IS_ACTIVE,
                  l_w4_recs(i).IS_READY,
                  l_w4_recs(i).BILLING_CONTRACT,
                  l_w4_recs(i).CONTRACT_STATUS,
                  l_w4_recs(i).SERVICE_PACK_NAME,
                  l_w4_recs(i).SERVICE_PACK_CODE,
                  l_w4_recs(i).CURRENCY_CODE,
                  l_w4_recs(i).CURRENCY_NAME,
                  l_w4_recs(i).SCHEME_CODE,
                  l_w4_recs(i).SCHEME_NAME,
                  l_w4_recs(i).L_INTEREST_RATE,
                  l_w4_recs(i).INTEREST_RATE,
                  l_w4_recs(i).BRANCH_NAME,
                  l_w4_recs(i).BRANCH_CODE,
                  l_w4_recs(i).FILIAL_NAME,
                  l_w4_recs(i).FILIAL_ID,
                  l_w4_recs(i).PLASTIC_TYPE,
                  l_w4_recs(i).WEB_BANKING,
                  l_w4_recs(i).SMS_NOTIFY,
                  l_w4_recs(i).acc_scheme_type,
                  l_w4_recs(i).CCAT,
                  l_w4_recs(i).PCAT
                  )
                  ;
    end loop;
    commit;
    close w4_cur;
    save_debug_log('Fill_W4_Contract.  3.');
      execute immediate ('truncate table ows_contract');
      save_debug_log('Fill_W4_Contract.  4.');
      insert /*+ append*/
      into ows_contract bb
      select distinct trans_rec.AMND_DATE,
                        trans_rec.OWS_CONTRACT_ID,
                        trans_rec.CON_CAT,
                        trans_rec.CONTRACT_NUMBER,
                        trans_rec.CONTRACT_NAME,
                        trans_rec.COMMENT_TEXT,
                        trans_rec.OWS_CLIENT_ID,
                        trans_rec.ACNT_CONTRACT__OID,
                        trans_rec.AUTH_LIMIT_AMOUNT,
                        trans_rec.BASE_AUTH_LIMIT,
                        trans_rec.LIAB_BALANCE,
                        trans_rec.LIAB_BLOCKED,
                        trans_rec.OWN_BALANCE,
                        trans_rec.OWN_BLOCKED,
                        trans_rec.SUB_BALANCE,
                        trans_rec.SUB_BLOCKED,
                        trans_rec.TOTAL_BALANCE,
                        trans_rec.TOTAL_BLOCKED,
                        trans_rec.SHARED_BALANCE,
                        trans_rec.SHARED_BLOCKED,
                        trans_rec.AMOUNT_AVAILABLE,
                        trans_rec.DATE_OPEN,
                        trans_rec.DATE_EXPIRE,
                        trans_rec.LAST_BILLING_DATE,
                        trans_rec.NEXT_BILLING_DATE,
                        trans_rec.LAST_SCAN,
                        trans_rec.CARD_EXPIRE,
                        trans_rec.RBS_NUMBER,
                        trans_rec.LIMIT_IS_ACTIVE,
                        trans_rec.IS_READY,
                        trans_rec.BILLING_CONTRACT,
                        trans_rec.CONTRACT_STATUS,
                        trans_rec.SERVICE_PACK_NAME,
                        trans_rec.SERVICE_PACK_CODE,
                        trans_rec.CURRENCY_CODE,
                        trans_rec.CURRENCY_NAME,
                        trans_rec.SCHEME_CODE,
                        trans_rec.SCHEME_NAME,
                        trans_rec.L_INTEREST_RATE,
                        trans_rec.INTEREST_RATE,
                        first_value(trans_rec.BRANCH_NAME) over(partition by trans_rec.OWS_CONTRACT_ID order by trans_rec.BRANCH_CODE) BRANCH_NAME,
                        first_value(trans_rec.BRANCH_CODE) over(partition by trans_rec.OWS_CONTRACT_ID order by trans_rec.BRANCH_CODE) BRANCH_CODE,
                        trans_rec.FILIAL_NAME,
                        trans_rec.FILIAL_ID,
                        trans_rec.PLASTIC_TYPE,
                        trans_rec.WEB_BANKING,
                        trans_rec.SMS_NOTIFY,
                        trans_rec.acc_scheme_type,
                        trans_rec.CCAT,
                        trans_rec.PCAT
      from ows_contract_buf trans_rec;
      save_debug_log('Fill_W4_Contract.  5.');
      --Added 09.09.2014 Chervoniy_y
      execute immediate ('truncate table ows_card_activation_2');
      save_debug_log('Fill_W4_Contract.  6.');
      insert /*+ append*/
      into ows_card_activation_2 a
        select CONTRACT_NUMBER,
               acnt_contract__oid,
               amnd_date,
               chng,
               amnd_officer
          from (SELECT AC.PRODUCTION_STATUS,
                       CONTRACT_NUMBER,
                       amnd_date,
                       ac.acnt_contract__oid,
                       AC.PRODUCTION_STATUS || '<-' ||
                       lead(AC.PRODUCTION_STATUS, 1) over(partition by CONTRACT_NUMBER, ac.acnt_contract__oid order by amnd_date desc) chng,
                       amnd_officer
                  FROM OWS.ACNT_CONTRACT@rpt AC
                 WHERE 1 = 1
                   and con_cat = 'C'
                 order by amnd_date)
      ;
      commit;
      save_debug_log('Fill_W4_Contract.  7.');
      execute immediate ('truncate table ows_contract_changes');
      save_debug_log('Fill_W4_Contract.  8.');
      insert /*+ append */ into ows_contract_changes
        select 
         a.amnd_prev ows_contract_id,
         a.amnd_date,
         nvl(LEAD(a.amnd_date, 1)
             over(partition by a.amnd_prev order by a.amnd_date),
             to_date('31.12.2999')) todate,
         a.amnd_officer,
         a.id,
         a.acnt_contract__oid,
         a.date_expire,
         c.name contract_status,
         a.production_status,
         a.is_ready,
         a.f_i,
         a.service_group
        from ows.acnt_contract@rpt a
         inner join ows.CONTR_STATUS@rpt c on a.contr_status = c.id and c.amnd_state = 'A'
      ;
      commit;
      save_debug_log('Fill_W4_Contract.  9.');
      execute immediate ('truncate table ows_client_changes');
      save_debug_log('Fill_W4_Contract.  10.');
      insert /*+ append */ into ows_client_changes
        select 
         a.amnd_prev ows_client_id,
         a.amnd_date,
         nvl(LEAD(a.amnd_date, 1)
             over(partition by a.amnd_prev order by a.amnd_date),
             to_date('31.12.2999')) todate,
         a.amnd_officer,
         a.id,
         a.f_i,
         a.service_group,
         a.company_nam,
         a.client_number cli_code,
         a.is_ready,
         case
           when add_info_04 like '%<VCC>%' and
                regexp_like(substr(add_info_04, 6, 6), '[0-9]+') then
            substr(add_info_04, 6, 6)
         end vcc
      from ows.client@rpt a
      ;
      commit;
      save_debug_log('Fill_W4_Contract.  11.');
      Store_Etl_Tables(l_action,'ows_contract_buf');
      Store_Etl_Tables(l_action,'ows_contract');
      Store_Etl_Tables(l_action,'ows_card_activation_2');
      Store_Etl_Tables(l_action,'ows_client_changes');
      Store_Etl_Tables(l_action,'ows_contract_changes');
      save_debug_log('Fill_W4_Contract.  12.');
      --ExportToDWH_PRIM('ows_contract');
      --ExportToDWH_PRIM('ows_card_activation_2');
      insert /*+ append */
      into OWS_CONTRACT_SNAP
      select t.*,sysdate as SDT  from OWS_CONTRACT t
      ;
      commit;
      save_debug_log('Fill_W4_Contract.  13.');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      save_debug_log('Fill_W4_Contract.  14.');
      exception
      when others then
      rollback;
      gv_err_count:=gv_err_count+1;
      Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
      ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
      );
      END;
      end if;
end;
procedure Fill_Trans_new ---+
is
 CURSOR trans_buf_cur IS
   SELECT /*+ parallel(8) */
        POSTING_DATE,
        TARGET_NUMBER,
        ows_client_id,
        SETTL_AMOUNT,
        SETTL_CURR,
        SETTL_CURR_C,
        SOURCE_CHANNEL,
        SOURCE_NUMBER,
        TARGET_CHANNEL,
        TRANS_AMOUNT,
        TRANS_CITY,
        TRANS_COUNTRY,
        TRANS_CURR,
        TRANS_CURR_C,
        TRANS_DATE,
        DIR DIR,
        OP_TYPE_CODE OP_TYPE_CODE,
        OP_TYPE_NAME OP_TYPE_NAME,
        SERVICE_CLASS,
        SIC_MCC,
        AMND_DATE,
        ID_D,
        trans_details,
        m_trans_amount,
        s_amount,
        s_fee_amount,
        t_amount,
        t_fee_amount,
        o.m_transaction__oid
  FROM v_trans o
  where  1=1
         and  o.AMND_DATE >= trunc(sysdate,'dd')-5
         and  o.AMND_DATE < trunc(sysdate,'dd')
 ;
 type t_trans_buf_cur_table is table of trans_buf_cur%rowtype;
 l_trans_buf_recs t_trans_buf_cur_table;
 l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_Trans_New');
 l_action  etl_actions_log.id%type;
 num_rows number;
BEGIN
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  save_debug_log('Fill_Trans_new.  1.');
  execute immediate ('truncate table TRANS_BUFF_2');
  save_debug_log('Fill_Trans_new.  2.');
  open trans_buf_cur;
  loop
    fetch trans_buf_cur bulk collect into l_trans_buf_recs limit 1000000;--gc_bulk_limit;
    exit when l_trans_buf_recs.count=0;
    forall i in indices of l_trans_buf_recs
    insert /*+ append */
    into TRANS_BUFF_2
    values
      (
        l_trans_buf_recs(i).POSTING_DATE,
        l_trans_buf_recs(i).TARGET_NUMBER,
        l_trans_buf_recs(i).ows_client_id,
        l_trans_buf_recs(i).SETTL_AMOUNT,
        l_trans_buf_recs(i).SETTL_CURR,
        l_trans_buf_recs(i).SETTL_CURR_C,
        l_trans_buf_recs(i).SOURCE_CHANNEL,
        l_trans_buf_recs(i).SOURCE_NUMBER,
        l_trans_buf_recs(i).TARGET_CHANNEL,
        l_trans_buf_recs(i).TRANS_AMOUNT,
        l_trans_buf_recs(i).TRANS_CITY,
        l_trans_buf_recs(i).TRANS_COUNTRY,
        l_trans_buf_recs(i).TRANS_CURR,
        l_trans_buf_recs(i).TRANS_CURR_C,
        l_trans_buf_recs(i).TRANS_DATE,
        l_trans_buf_recs(i).DIR,
        l_trans_buf_recs(i).OP_TYPE_CODE,
        l_trans_buf_recs(i).OP_TYPE_NAME,
        l_trans_buf_recs(i).SERVICE_CLASS,
        l_trans_buf_recs(i).SIC_MCC,
        l_trans_buf_recs(i).AMND_DATE,
        l_trans_buf_recs(i).ID_D,
        l_trans_buf_recs(i).trans_details,
        l_trans_buf_recs(i).m_trans_amount,
        l_trans_buf_recs(i).s_amount,
        l_trans_buf_recs(i).s_fee_amount,
        l_trans_buf_recs(i).t_amount,
        l_trans_buf_recs(i).t_fee_amount,
        l_trans_buf_recs(i).m_transaction__oid
      )
     ;
  end loop;
  commit;
  save_debug_log('Fill_Trans_new.  3.');
  --код не оптимален
  --Chshuka Dmitriy  September 17, 2015 5:11 PM
  /*delete from TRANSACTION_3 t
   where exists (select 1 from TRANS_BUFF_2 p
                 where t.id_d=p.id_d and t.dir=p.dir
                    and p.m_transaction__oid is null
                )
  ;*/
  --Chshuka Dmitriy  September 17, 2015 5:11 PM
  --оптимальный код 5 строк ниже
  num_rows:=0;
  For rec in (select p.id_d,p.dir from TRANS_BUFF_2 p
                 where  p.m_transaction__oid is null) loop
      delete from TRANSACTION_3 t where t.id_d=rec.id_d and t.dir=rec.dir;
      num_rows:= num_rows+nvl(SQL%ROWCOUNT,0);
      /* ЗДЕСЬ ВОЗМОЖНО НУЖНО UPDATE  TRANS_BUFF_2 для того чтобы не бегать уже по удаленным*/
  end loop;
  commit;
  save_debug_log('Fill_Trans_new.  4. num_rows='||num_rows);
  insert /*+ parallel(16) append*/
  into "TRANSACTION_3"
  select /*--append */
     decode(t1.name, null, 'N/D', t1.name) || '->' ||
     decode(t2.name, null, 'N/D', t2.name) trans_dir_type,
     o.POSTING_DATE,
     o.TARGET_NUMBER,
     o.ows_client_id,
     o.SETTL_AMOUNT,
     o.SETTL_CURR,
     o.SETTL_CURR_C,
     o.SOURCE_CHANNEL,
     o.SOURCE_NUMBER,
     o.TARGET_CHANNEL,
     o.TRANS_AMOUNT,
     o.TRANS_CITY,
     o.TRANS_COUNTRY,
     o.TRANS_CURR,
     o.TRANS_CURR_C,
     o.TRANS_DATE,
     o.DIR,
     o.OP_TYPE_CODE,
     o.OP_TYPE_NAME,
     o.SERVICE_CLASS,
     o.SIC_MCC,
     o.AMND_DATE,
     o.ID_D,
     o.trans_details,
     sum(o.m_trans_amount) m_trans_amount,
     sum(o.s_amount) s_amount,
     sum(o.s_fee_amount) s_fee_amount,
     sum(o.t_amount) t_amount,
     sum(o.t_fee_amount) t_fee_amount
  from TRANS_BUFF_2 o
    left join OWS.MESS_CHANNEL@rpt t1 on o.source_channel = t1.code
    left join OWS.MESS_CHANNEL@rpt t2 on o.target_channel = t2.code
  where 1 = 1 and trans_date is not null and o.m_transaction__oid is null
  group by decode(t1.name, null, 'N/D', t1.name) || '->' ||
           decode(t2.name, null, 'N/D', t2.name),
           o.POSTING_DATE,
           o.TARGET_NUMBER,
           o.ows_client_id,
           o.SETTL_AMOUNT,
           o.SETTL_CURR,
           o.SETTL_CURR_C,
           o.SOURCE_CHANNEL,
           o.SOURCE_NUMBER,
           o.TARGET_CHANNEL,
           o.TRANS_AMOUNT,
           o.TRANS_CITY,
           o.TRANS_COUNTRY,
           o.TRANS_CURR,
           o.TRANS_CURR_C,
           o.TRANS_DATE,
           o.DIR,
           o.OP_TYPE_CODE,
           o.OP_TYPE_NAME,
           o.SERVICE_CLASS,
           o.SIC_MCC,
           o.AMND_DATE,
           o.ID_D,
           o.trans_details
  ;
  commit;
  save_debug_log('Fill_Trans_new.  5.');
  Store_Etl_Tables(l_action,'TRANS_BUFF_2');
  Store_Etl_Tables(l_action,'TRANSACTION_3');
  save_debug_log('Fill_Trans_new.  6.');
  Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
procedure Fill_PayRoll_List_New---+
  is
 l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_PayRoll_List_New');
 l_action  etl_actions_log.id%type;
begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  save_debug_log('Fill_PayRoll_List_New.  1.');
  execute immediate ('truncate table efee_list');
  save_debug_log('Fill_PayRoll_List_New.  2.');
  insert /*-- parallel(bb,8) */
  into efee_list bb
  select a.contract_number,
         a.contract_name,
         a.date_open,
         a.rbs_number,
         case
           when length(regexp_replace(b.itn, '[^0-9]', '')) = 12 then
            regexp_replace(b.itn, '[^0-9]', '')
         end bin,
         case
           when length(regexp_replace(nvl(address_line_3, b.reg_number),
                                      '[^0-9]',
                                      '')) = 12 then
            regexp_replace(nvl(address_line_3, b.reg_number), '[^0-9]', '')
         end rnn,
         b.id client_id_ows,
         b.CLIENT_NUMBER cli_code,
         c.NAME contract_status,
         sp.name service_pack_name,
         sp.code service_pack_code
    from ows.ACNT_CONTRACT@rpt a
   inner join ows.CONTR_STATUS@rpt c
      on A.CONTR_STATUS = C.ID
   inner join ows.client@rpt b
      on a.client__id = b.id
   inner join ows.SERV_PACK@rpt sp
      on SP.ID = a.SERV_PACK__ID
   where 1 = 1
     and contract_number like 'EFEE-%'
     and a.amnd_state = 'A'
     and b.amnd_state = 'A'
     and c.amnd_state = 'A'
     and SP.AMND_STATE = 'A'
  ;
  commit;
  save_debug_log('Fill_PayRoll_List_New.  3.');
  execute immediate('truncate table sal_trans');
  save_debug_log('Fill_PayRoll_List_New.  4.');
  insert
  into sal_trans s
  select  /*+ parallel (tr,2) parallel (cm,2) parallel (cl,2) parallel (ef,2) */
  coalesce(cl.iin,
   case
     when length(regexp_replace(b.itn, '[^0-9]', '')) = 12 then
      regexp_replace(b.itn, '[^0-9]', '')
   end) as iin_cl,
   tr.target_number,
   sp.code service_pack_code,
   sp.name service_pack_name,
   tr.posting_date,
   --tr.t_amount*decode(cont.curr,840,182,978,250,398,1),--валюта счета
   tr.t_amount*etl.Get_NBRK_Curr(trunc(sysdate),to_char(cont.curr),0),
   ef.bin,
   ef.CONTRACT_NAME,
   o."ТИП_СЧЕТОВОЙ" tp
    from transaction_3 tr
   inner join ows.ACNT_CONTRACT@rpt cont
      on tr.target_number = cont.contract_number
     and cont.amnd_state = 'A'
   inner join OWS.OPT_SCHEME_N@rpt o
      on cont.acc_scheme__id = o.id
   inner join ows.CONTR_STATUS@rpt c
      on cont.CONTR_STATUS = C.ID
     and c.amnd_state = 'A'
   inner join ows.client@rpt b
      on cont.client__id = b.id
     and b.amnd_state = 'A'
   left join client_map cm on cm.client_src=b.id and cm.src='W'
   left join client cl on cl.agr_id=cm.agr_id
   inner join ows.SERV_PACK@rpt sp
      on SP.ID = cont.SERV_PACK__ID
      and sp.amnd_state = 'A'
    left join efee_list ef
      on b.company_nam = ef.contract_number
   where 1 = 1
     and tr.op_type_name = 'Payment Salary'
     and tr.dir = 1
     --and trans_curr = 'TENGE'
     and cont.curr in (840,978,398) --'US DOLLAR','EURO','TENGE'
     and trans_date >= to_date('01.01.2013', 'dd.mm.yyyy')
   ;
   commit;
   save_debug_log('Fill_PayRoll_List_New.  5.');
   ---------LS 06112014--------------------
   delete from payroll_list_tmptt;
   commit;
   save_debug_log('Fill_PayRoll_List_New.  6.');
  insert into payroll_list_tmptt
   /* select cast(a.iin_cl as varchar2(12)) iin,
           1 as status
      from (select s.IIN_CL, s.target_number from sal_trans s
             where 1 = 1 and s.POSTING_DATE between sysdate - 40 and sysdate having
             sum(s.TRANS_AMOUNT) >= 25000
             group by s.IIN_CL, s.target_number) a
     where a.IIN_CL is not null
     group by a.iin_cl;   */
    --после встречи с Даниилом 13.10.15, убрать sysdate - 85
    select cast (a.iin_cl as varchar2(12)) iin,
           min(case when b.iin_cl is not null
                    then 1
                    else 2
                    end) status
    from
    (select s.IIN_CL,
            s.target_number
    from sal_trans s
    where 1=1
        and s.POSTING_DATE between sysdate-40 and sysdate
    having sum(s.TRANS_AMOUNT)>=25000
    group by s.IIN_CL,
             s.target_number
        ) a
    left join
    (select distinct s.IIN_CL,
                    s.target_number
    from sal_trans s
    where 1=1
        and s.POSTING_DATE < sysdate-85 --sysdate-85
        ) b
    on a.IIN_CL=b.IIN_CL
      and a.target_number=b.target_number
    where a.IIN_CL is not null
    group by a.iin_cl;
    commit;
    save_debug_log('Fill_PayRoll_List_New.  7.');
     Store_Etl_Tables(l_action,'payroll_list_tmptt'); --for test payroll_list_tmptt
     save_debug_log('Fill_PayRoll_List_New.  8.');
     if  Check_Etl_Tables('payroll_list_tmptt') then
        --  commit; ---'ok, data can be inserted'
        DBMS_MVIEW.REFRESH(LIST => 'payroll_list', METHOD => 'C');
        save_debug_log('Fill_PayRoll_List_New.  9.');
      else
       --   rollback;
         -- gv_err_count:=gv_err_count+1;
          gc_Msg_tbl_info := 'Необходимо проверить кол-во строк в payroll_list_tmptt!!!';
          Send_Etl_Results(sysdate,false);
          gc_Msg_tbl_info := '';
     end if;
      commit;
 ----------------
   save_debug_log('Fill_PayRoll_List_New.  10.');
   Store_Etl_Tables(l_action,'efee_list');
   Store_Etl_Tables(l_action,'sal_trans');
   save_debug_log('Fill_PayRoll_List_New.  11.');
   Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
procedure Fill_dm_loan_base_add_2---+
  is
 l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_dm_loan_base_add_2');
 l_action  etl_actions_log.id%type;
begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  merge
  into dm_loan_base_add d
  using (select   id,dep_id, dcl_id, product_code_atf, product_name_atf,
                  target_code_atf, target_name_atf, pcn_com,
                  pcn_rate, RESTRUCT_CODE_ATF, RESTRUCT_NAME_ATF,pcn_service,Effective_rate
  from colvir.etl_dm_loan_base_2@reps) a
  on (d.id=a.id)
  when matched then update set
  d.dep_id=a.dep_id,
  d.dcl_id=a.dcl_id,
  d.product_code_atf=a.product_code_atf,
  d.product_name_atf=a.product_name_atf,
  d.target_code_atf=a.target_code_atf,
  d.target_name_atf=a.target_name_atf,
  d.pcn_com=a.pcn_com,
  d.pcn_rate=a.pcn_rate,
  d.RESTRUCT_CODE_ATF=a.RESTRUCT_CODE_ATF,
  d.RESTRUCT_NAME_ATF=a.RESTRUCT_NAME_ATF,
  d.pcn_service=a.pcn_service,
  d.effective_rate=a.effective_rate
  when not matched then insert
  (
  d.id,
  d.dep_id,
  d.dcl_id,
  d.product_code_atf,
  d.product_name_atf,
  d.target_code_atf,
  d.target_name_atf,
  d.pcn_com,
  d.pcn_rate,
  d.RESTRUCT_CODE_ATF,
  d.RESTRUCT_NAME_ATF,
  d.pcn_service,
  d.effective_rate)
  values
  (
  a.id,
  a.dep_id,
  a.dcl_id,
  a.product_code_atf,
  a.product_name_atf,
  a.target_code_atf,
  a.target_name_atf,
  a.pcn_com,
  a.pcn_rate,
  a.RESTRUCT_CODE_ATF,
  a.RESTRUCT_NAME_ATF,
  a.pcn_service,
  a.effective_rate)
  ;
commit;
execute immediate ('truncate table insurance_buf');
insert into insurance_buf
select *
from colvir.etl_insurance_buf@reps;
merge into dm_loan_base_add dlba
using insurance_buf a
on (dlba.id=a.contract_id)
when MATCHED then update set
dlba.grandes_premium=a.grandes_premium,
dlba.apolis_premium=a.apolis_premium;
commit;
   Store_Etl_Tables(l_action,'dm_loan_base_add');
   Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
procedure Store_Phones_ETL(p_list in out nocopy source_cli_phones_tab,p_source in varchar2)---+
  is
l_dat source_cli_phones_tab;
begin
 select
 source_cli_phones_t(id_customer, phone_type, network_code, phone_number,full_number, like_mobile)
 bulk collect into l_dat
 from (
  select distinct
    cm.agr_id id_customer
    ,case when a.phone_type is null and a.like_mobile=1 then 98
          when a.phone_type is null and a.like_mobile=0 then 99
     else a.phone_type end as phone_type
    ,a.network_code
    ,a.phone_number
    ,a.full_number
    ,a.like_mobile
    ,row_number() over (partition by cm.agr_id,a.network_code,a.phone_number order by a.like_mobile desc,a.phone_type desc nulls last) k
    from table(p_list) a
    join client_map cm on cm.client_src=a.cli_id and cm.src=p_source
   ) e
   where
   k=1
   ;
  MERGE /*-- parallel(a,4) */
    INTO client_phones a
  USING (select
    a.cli_id id_customer
    ,a.phone_type
    ,'7' country_code
    ,a.network_code
    ,a.phone_number
    ,case when a.network_code is not null then
      (case  when a.phone_type in (3,9,98) and a.like_mobile=1 then 1
             when a.phone_type not in (3,9,98) and a.like_mobile=0 then 1
             else 0
       end)
    else 0 end as isacceptable
    ,1 isactive
    ,case when a.phone_type not in (3,9,98) and a.like_mobile=1 then 1
    else 0 end as need_manual
    from table(l_dat) a
   ) b
  ON (a.id_customer=b.id_customer and nvl(a.network_code,'N/A')=nvl(b.network_code,'N/A') and a.phone_number=b.phone_number)
  WHEN MATCHED THEN UPDATE
    set a.isacceptable=b.isacceptable
    ,a.need_manual=b.need_manual
    ,a.updated=sysdate
    ,a.updated_by='etl'
    ,a.country_code=b.country_code
    ,a.phone_type=b.phone_type
  WHEN NOT MATCHED THEN INSERT
    (a.id,a.id_customer,a.phone_type,a.country_code,a.network_code,a.phone_number,a.isacceptable,a.isactive,a.need_manual,a.created,a.created_by)
    values
    (client_phones_seq.nextval,b.id_customer,b.phone_type,b.country_code,b.network_code,b.phone_number,b.isacceptable,b.isactive,b.need_manual,sysdate,'etl')
  ;
end;
procedure Fill_Client_Phones_Colvir---+
  is
cursor c is
 select source_cli_phones_t(
  e.cli_id,e.phone_type,e.network_code,e.phone_number,e.full_number
  ,(case when mm.ph_code is not null then 1 else 0 end)
  )
  from (
  select /*+ driving_site(p) parallel(p,16)  */
  p.id cli_id
  ,m.id_type as phone_type
  ,substr(regexp_replace(p.pnum, '[^0-9]', ''),-10,3) as network_code
  ,nvl(substr(regexp_replace(p.pnum, '[^0-9]', ''),-7),p.pnum) as phone_number
  ,nvl(substr(regexp_replace(p.pnum, '[^0-9]', ''),-10),p.pnum) as full_number
  from colvir.G_CLIPHONE@reps p
  left join dict_phone_types_map_out m on m.system_code='C' and m.system_type_id=p.ptype
  where
  p.arcfl = 0
  and p.pnum is not null
  and length(regexp_replace(p.pnum, '[^0-9]', ''))>0
  ) e
  left join dict_mobiles_code mm on mm.ph_code=e.network_code
  ;
 l_dat source_cli_phones_tab;
 l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_Client_Phones_Colvir');
 l_action  etl_actions_log.id%type;
Begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  open c;
  loop
    fetch c bulk collect into l_dat limit 80000;
    exit when l_dat.count=0;
    Store_Phones_ETL(l_dat,'C');
  end loop;
  close c;
  Store_Etl_Tables(l_action,'client_phones');
  Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
procedure Fill_Client_Phones_W4--+
  is
cursor c is
 select /*+ parallel(4) */
  source_cli_phones_t(
  e.cli_id,e.phone_type,e.network_code,e.phone_number,e.full_number
  ,(case when mm.ph_code is not null then 1 else 0 end)
  )
  from (
    select
    p.ows_client_id cli_id
    ,m.id_type as phone_type
    ,substr(regexp_replace(p.phone_h, '[^0-9]', ''),-10,3) as network_code
    ,nvl(substr(regexp_replace(p.phone_h, '[^0-9]', ''),-7),p.phone_h) as phone_number
    ,nvl(substr(regexp_replace(p.phone_h, '[^0-9]', ''),-10),p.phone_h) as full_number
    from OWS_CLIENT_BUF p
    left join dict_phone_types_map_out m on m.system_code='W' and m.system_type_id=1
    where
    p.phone_h is not null
    and length(regexp_replace(p.phone_h, '[^0-9]', ''))>0
    and length(p.phone_h)<=50
    union all
    select
    p.ows_client_id cli_id
    ,m.id_type as phone_type
    ,substr(regexp_replace(p.phone_m, '[^0-9]', ''),-10,3) as network_code
    ,nvl(substr(regexp_replace(p.phone_m, '[^0-9]', ''),-7),p.phone_m) as phone_number
    ,nvl(substr(regexp_replace(p.phone_m, '[^0-9]', ''),-10),p.phone_m) as full_number
    from OWS_CLIENT_BUF p
    left join dict_phone_types_map_out m on m.system_code='W' and m.system_type_id=2
    where
    p.phone_m is not null
    and length(regexp_replace(p.phone_m, '[^0-9]', ''))>0
    and length(p.phone_m)<=50
    union all
    select
    p.CLIENT__OID cli_id
    ,m.id_type as phone_type
    ,substr(regexp_replace(p.ADDRESS_ZIP, '[^0-9]', ''),-10,3) as network_code
    ,substr(regexp_replace(p.ADDRESS_ZIP, '[^0-9]', ''),-7) as phone_number
    ,substr(regexp_replace(p.ADDRESS_ZIP, '[^0-9]', ''),-10) as full_number
    from ows.CLIENT_ADDRESS@rpt p
    left join dict_phone_types_map_out m on m.system_code='W' and m.system_type_id=p.ADDRESS_TYPE
    where
    p.AMND_STATE = 'A'
    and length(regexp_replace(p.ADDRESS_ZIP, '[^0-9]', ''))>=10
    and length(regexp_replace(p.ADDRESS_ZIP, '[^0-9]', ''))<=11
  ) e
  left join dict_mobiles_code mm on mm.ph_code=e.network_code
  ;
 l_dat source_cli_phones_tab;
 l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_Client_Phones_W4');
 l_action  etl_actions_log.id%type;
Begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  open c;
  loop
    fetch c bulk collect into l_dat limit 80000;
    exit when l_dat.count=0;
    Store_Phones_ETL(l_dat,'W');
  end loop;
  close c;
  Store_Etl_Tables(l_action,'client_phones');
  Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
 END;
 end if;
end;
procedure Fill_Client_Phones_Ekz---+
  is
cursor c is
 select /*+ parallel(4) */
 source_cli_phones_t(
  e.cli_id,e.phone_type,e.network_code,e.phone_number,e.full_number
  ,(case when mm.ph_code is not null then 1 else 0 end)
  )
  from (
  select
   db.id cli_id
   ,m.id_type as phone_type
   ,substr(regexp_replace(e.AC_PHONE_NUMBER, '[^0-9]', ''),-10,3) as network_code
   ,substr(regexp_replace(e.AC_PHONE_NUMBER, '[^0-9]', ''),-7) as phone_number
   ,substr(regexp_replace(e.AC_PHONE_NUMBER, '[^0-9]', ''),-10) as full_number
   from DM_CIF_BASE db
   inner join DWH.DM_EKZ_REQUESTS e on db.cli_code = e.client_id
   left join dict_phone_types_map_out m on m.system_code='E' and m.system_type_id=1
   where
   e.client_id <> 0
   and length(regexp_replace(e.AC_PHONE_NUMBER, '[^0-9]', '')) >= 10
  union all
  select
   db.id cli_id
   ,m.id_type as phone_type
   ,substr(regexp_replace(e.REG_PHONE_NUMBER, '[^0-9]', ''),-10,3) as network_code
   ,substr(regexp_replace(e.REG_PHONE_NUMBER, '[^0-9]', ''),-7) as phone_number
   ,substr(regexp_replace(e.REG_PHONE_NUMBER, '[^0-9]', ''),-10) as full_number
   from DM_CIF_BASE db
   inner join DWH.DM_EKZ_REQUESTS e on db.cli_code = e.client_id
   left join dict_phone_types_map_out m on m.system_code='E' and m.system_type_id=2
   where
   e.client_id <> 0
   and length(regexp_replace(e.REG_PHONE_NUMBER, '[^0-9]', '')) >= 10
  ) e
  left join dict_mobiles_code mm on mm.ph_code=e.network_code
  ;
 l_dat source_cli_phones_tab;
 l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_Client_Phones_EKZ');
 l_action  etl_actions_log.id%type;
Begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  open c;
  loop
    fetch c bulk collect into l_dat limit 80000;
    exit when l_dat.count=0;
    Store_Phones_ETL(l_dat,'C');
  end loop;
  close c;
  Store_Etl_Tables(l_action,'client_phones');
  Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
procedure Collaterals_Refresh---+
  is
 l_act_name constant etl_actions_log.action_name%type:=Upper('Collaterals_Refresh');
 l_action  etl_actions_log.id%type;
begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  DBMS_MVIEW.REFRESH(LIST => 'MV_LOANS_COLLATERALS', METHOD => 'C');
  Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
  commit;
exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
procedure Application_Refresh---+
  is
 l_act_name constant etl_actions_log.action_name%type:=Upper('Application_Refresh');
 l_action  etl_actions_log.id%type;
begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  DBMS_MVIEW.REFRESH(LIST => 'loan_request,loan_request_CLNT', METHOD => 'C');
  Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
  commit;
exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
procedure Dash_Board_Update----+
is
   l_act_name constant etl_actions_log.action_name%type:=Upper('Dash_Board_Update');
   l_action  etl_actions_log.id%type;
begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  Truncate_Table('loan_buf');
  save_debug_log('Dash_Board_Update  1');
  insert into loan_buf
  select distinct
        e.PROCESS_GUID,
        e.AGR_ID,
        e.START_DATE,
        e.BRANCH_ID,
        e.TITLE,
        e.ISLOYAL,
        e.SALARYFLAG,
        e.BRANCH_NAME,
        e.SUM_FULL,
        e.FROMDATE,
        e.CONTRACT_ID,
        e.EFFECTIVE_RATE,
        e.WT_EFFECTIVE_RATE,
        case when con.agr_id is not null then 'X-Sell' else 'Walk-In' end as client_type_lb,
        e.DEP_NAME,
        e.DEP_id
  from (
        select distinct
               first_value(lrc.process_guid) over (partition by dl.contract_id order by decode(dl.contract_num,lr.registration_number,0,1),trunc(dl.FROMDATE)-trunc(FINISH_DATE)) process_guid,
               first_value(lrc.agr_id) over (partition by dl.contract_id order by decode(dl.contract_num,lr.registration_number,0,1),trunc(dl.FROMDATE)-trunc(FINISH_DATE)) agr_id,
               first_value(lr.START_DATE) over (partition by dl.contract_id order by decode(dl.contract_num,lr.registration_number,0,1),trunc(dl.FROMDATE)-trunc(FINISH_DATE)) START_DATE,
               first_value(lr.BRANCH_ID) over (partition by dl.contract_id order by decode(dl.contract_num,lr.registration_number,0,1),trunc(dl.FROMDATE)-trunc(FINISH_DATE)) BRANCH_ID,
               first_value(lr.TITLE) over (partition by dl.contract_id order by decode(dl.contract_num,lr.registration_number,0,1),trunc(dl.FROMDATE)-trunc(FINISH_DATE)) TITLE,
               first_value(lr.isloyal) over (partition by dl.contract_id order by decode(dl.contract_num,lr.registration_number,0,1),trunc(dl.FROMDATE)-trunc(FINISH_DATE)) isloyal,
               first_value(lr.salaryflag) over (partition by dl.contract_id order by decode(dl.contract_num,lr.registration_number,0,1),trunc(dl.FROMDATE)-trunc(FINISH_DATE)) salaryflag,
               first_value(nvl(dbe.branch_name,lr.branch_name)) over (partition by dl.contract_id order by decode(dl.contract_num,lr.registration_number,0,1),trunc(dl.FROMDATE)-trunc(FINISH_DATE)) branch_name,
               --dl.sum_full*decode(dl.val_id,21,182,421,250,1) sum_full,
               dl.sum_full*etl.Get_NBRK_Curr(trunc(sysdate),'',dl.val_id) sum_full,
               dl.FROMDATE,
               dl.contract_id,
               coalesce(to_number(replace(da.effective_rate,',','.'))/100,der.effective_rate) effective_rate,
               --dl.sum_full*decode(dl.val_id,21,182,421,250,1)*coalesce(to_number(replace(da.effective_rate,',','.'))/100,der.effective_rate) wt_effective_rate,
               dl.sum_full*etl.Get_NBRK_Curr(trunc(sysdate),'',dl.val_id)*coalesce(to_number(replace(da.effective_rate,',','.'))/100,der.effective_rate) wt_effective_rate,
               first_value(nvl(dbe.dep_name,lr.dep_name)) over (partition by dl.contract_id order by decode(dl.contract_num,lr.registration_number,0,1),trunc(dl.FROMDATE)-trunc(FINISH_DATE)) dep_name,
               first_value(nvl(dbe.dep_id,lr.dep_id)) over (partition by dl.contract_id order by decode(dl.contract_num,lr.registration_number,0,1),trunc(dl.FROMDATE)-trunc(FINISH_DATE)) dep_id
        from DM_LOAN_BASE dl
            inner join dm_loan_base_add da on dl.CONTRACT_ID=da.id
            left join DICT_EFFECTIVE_RATE der
                  on der.term=least(greatest(round(decode(term_type,null,months_between(todate,fromdate),term_cnt/decode(term_type,'M',1,'D',30.4167,'Y',1/12))),1),180)
                    and der.rate=least(greatest(round(coalesce(dl.rate,pcn_rate,0)*2)/2,0),50)
                    and der.COMM=least(greatest(round(coalesce(pcn_com,0)*2)/2,0),20)
            inner join DM_CIF_BASE dcb on dl.cli_id=dcb.id
            inner join client_map cm on cm.client_src=dcb.id and cm.src='C'
            inner join loan_request_CLNT lrc on lrc.agr_id=cm.agr_id
            inner join loan_request lr on lrc.process_guid=lr.process_guid
                                           and trunc(dl.FROMDATE)-trunc(coalesce(FINISH_DATE,decode(AGREEMENT_DATE,to_date('01.01.1900','dd.mm.yyyy'),FINISH_DATE,AGREEMENT_DATE),trunc(sysdate-1))) between -150 and 31
            left join dict_dep_ekz dbe on lr.branch_id=dbe.branch_id and lr.dep_id=dbe.dep_id
        where 1=1
              and dl.fromdate>='01.01.2014'
              and dl.STATE  in ('Актуален','Погашен')
              and dcb.vcc in ('107320',
                              '107329',
                              '107330',
                              '107340',
                              '107390',
                              '999992')
  ) e
    left join contact con on con.agr_id=e.agr_id and trunc(con.contact_creation_dttm)<=trunc(e.START_DATE)
  ;
  commit;
  save_debug_log('Dash_Board_Update  2');
  Truncate_Table('dash_board_tmp');
  insert into dash_board_tmp
  select /*+parallel(4) */
         a.dt,
         a.week_begin,
         a.month_begin,
         a.BRANCH_ID,
         a.BRANCH_NAME,
         a.title,
         a.segm,
         a.product_group,
         a.cli_type,
         cast (null as number) calls_count, --v_c.calls_count,
         cast (null as number) called_clients, --v_c.called_clients,
         cast (null as number) RPC_Clients, --v_c.RPC_Clients,
         cast (null as number) letters_count, --v_l.letters_count,
         cast (null as number) posted_clients, --v_l.posted_clients,
         cast (null as number) letters_delivered, --v_l.letters_delivered,
         cast (null as number) sms_count, --v_s.sms_count,
         cast (null as number) sms_clients, --v_s.sms_clients,
         cast (null as number) sms_delivered, --v_s.sms_delivered,
         app.cnt_app,
         app.cnt_app_approved,
         app.cnt_app_reject_scoring,
         app.cnt_app_reject,
         app.cnt_app_reject_verifier,
         app.cnt_app_cancel,
         app.cnt_app_cancel_cl,
         app.cnt_app_expert,
         app.cnt_app_verifier,
         app.cnt_app_deal_prepare,
         app.cnt_app_else,
         b.cnt_deal,
         b.cnt_deal_0,
         b.cnt_deal_1,
         b.cnt_deal_2,
         b.cnt_deal_3,
         b.cnt_deal_4,
         b.cnt_deal_5,
         b.cnt_deal_6,
         b.cnt_deal_7_14,
         b.cnt_deal_14_21,
         b.cnt_deal_21_99,
         b.sum_deal,
         b.sum_deal_0,
         b.sum_deal_1,
         b.sum_deal_2,
         b.sum_deal_3,
         b.sum_deal_4,
         b.sum_deal_5,
         b.sum_deal_6,
         b.sum_deal_7_14,
         b.sum_deal_14_21,
         b.sum_deal_21_99,
         c.cnt_deal_cascade,
         b.wt_effective_rate,
         b.effective_rate,
         a.dep_ID,
         a.dep_NAME,
         app.cnt_cl_app
  from (select dt,
               week_begin,
               month_begin,
               dbe.BRANCH_ID,
               dbe.BRANCH_NAME,
               dbe.dep_id,
               dbe.dep_name,
               title,
               SEGM,
               product_group,
               cl_t.cli_type
        from calendar c
            inner join dict_dep_ekz dbe on 1 = 1
            inner join (select '1. ЗАЕМЩИКИ' SEGM from dual
                        union
                        select '2. ЗАРПЛАТНИКИ' SEGM from dual
                        union
                        select '3. MASS' SEGM from dual) on 1 = 1
            inner join (select distinct
                               title,
                               case
                                 when title like '%Автокредитование%' or
                                      title = 'Тулпар' then
                                  'Авто'
                                 when title like '%Ипотека%' then
                                  'Ипотека'
                                 when title like '%Легкий%' or lower(title) like('%кредадмин%') then
                                  'Легкий'
                                 when title =
                                      'Потребительское кредитование' or
                                      lower(title) = '%залог%' then
                                  'Под залог'
                                 when title like
                                      '%Револьверное кредитование%' then
                                  'Револьверное кредитование'
                                 else
                                  title
                               end product_group
                        from loan_request
                        where title is not null and branch_id in (select branch_id from dict_branch_ekz)
                              and start_date >= '01.01.2014') on 1 = 1
            inner join (select 'X-Sell' as cli_type from dual union all select 'Walk-In' from dual) cl_t on 1=1
        where 1 = 1
              and c.dt >= '01.01.2014'
              and c.dt < trunc(sysdate)
       ) a
  left join (select dt,
                    week_begin,
                    month_begin,
                    dbe.BRANCH_ID,
                    dbe.BRANCH_NAME,
                    dbe.dep_id,
                    dbe.dep_name,
                    lr.title,
                    CASE
                      WHEN isloyal = 1 THEN
                       '1. ЗАЕМЩИКИ'
                      WHEN SALARYFLAG = 1 THEN
                       '2. ЗАРПЛАТНИКИ'
                      ELSE
                       '3. MASS'
                    END SEGM,
                    case
                      when title like '%Автокредитование%' or
                           title = 'Тулпар' then
                       'Авто'
                      when title like '%Ипотека%' then
                       'Ипотека'
                      when title = 'Потребительское кредитование' or
                           lower(title) = '%залог%' then
                       'Под залог'
                      when title like '%Легкий%' or lower(title) like('%кредадмин%') then
                       'Легкий'
                      when title like '%Револьверное кредитование%' then
                       'Револьверное кредитование'
                      else
                       title
                    end product_group,
                    count(distinct lr.process_guid) cnt_app,
                    count(distinct lr.iin) cnt_cl_app,
                    count(distinct case
                            when request_state_code = 'Finished' or
                    PR_STATUS in ('Завершено',
                                 'Отправка досье ПКАФ',
                                 'Запрос на принятие заявки ПКАФ',
                                 'Отправка досье в ПКАФ',
                                 'Запрос на принятие заявки для ПКАФ',
                                 'Досье возвращено консультанту',
                                 'Досье осталось у ПКАФ',
                                 'Подтверждение получения досье ПКАФ',
                                 'Подготовка распоряжения',
                                 'Передача досье в Архив',
                                 'Досье возвращено ПКАФ',
                                 'Запрос на принятие заявки Архив',
                                 'Запрос на принятие заявки Архивом',
                                 'Завершен')
                                 then
                             lr.process_guid
                          end) cnt_app_approved,
                    count(distinct case
                            when PR_STATUS = 'Отклонена - Скоринговое решение' then
                             lr.process_guid
                          end) cnt_app_reject_scoring,
                    count(distinct case
                            when request_state_code = 'Rejected' then
                             lr.process_guid
                          end) cnt_app_reject,
                    count(distinct case
                            when PR_STATUS like '%Отменена – Верификация%' then
                             lr.process_guid
                          end) cnt_app_reject_verifier,
                    count(distinct case
                            when PR_STATUS like '%Отменена %' and
                                 PR_STATUS not like '%Отменена – Верификация%' and
                                 PR_STATUS not like '%Отменена  Клиентом%' and
                                 PR_STATUS not like '%Отменена Клиентом%' or
                                 request_state_code = 'Canceled' then
                             lr.process_guid
                          end) cnt_app_cancel,
                    count(distinct case
                            when PR_STATUS like '%Отменена  Клиентом%'
                                or PR_STATUS like '%Отменена Клиентом%' then
                             lr.process_guid
                          end) cnt_app_cancel_cl,
                    count(distinct case
                            when request_state_code = 'Expertise' then
                             lr.process_guid
                          end) cnt_app_expert,
                    count(distinct case
                            when request_state_code = 'AcceptQueryVerifier' or
                                 PR_STATUS = 'Ожидание верификации' or
                                 PR_STATUS = 'Верификация' then
                             lr.process_guid
                          end) cnt_app_verifier,
                    count(distinct case
                            when PR_STATUS in ('Сбор подписей и подготовка к выдаче','Открытие текущего счета') then
                             lr.process_guid
                          end) cnt_app_deal_prepare,
                    count(distinct lr.process_guid)
                    - count(distinct case
                              when request_state_code = 'Finished' or
                    PR_STATUS in ('Завершено',
                                 'Отправка досье ПКАФ',
                                 'Запрос на принятие заявки ПКАФ',
                                 'Отправка досье в ПКАФ',
                                 'Запрос на принятие заявки для ПКАФ',
                                 'Досье возвращено консультанту',
                                 'Досье осталось у ПКАФ',
                                 'Подтверждение получения досье ПКАФ',
                                 'Подготовка распоряжения',
                                 'Передача досье в Архив',
                                 'Досье возвращено ПКАФ',
                                 'Запрос на принятие заявки Архив',
                                 'Запрос на принятие заявки Архивом',
                                 'Завершен')
                                   then
                               lr.process_guid
                            end)
                    - count(distinct case
                              when PR_STATUS = 'Отклонена - Скоринговое решение' then
                               lr.process_guid
                            end)
                    - count(distinct case
                              when request_state_code = 'Rejected' then
                               lr.process_guid
                            end)
                    - count(distinct case
                              when PR_STATUS like '%Отменена – Верификация%' then
                               lr.process_guid
                            end)
                    - count(distinct case
                              when PR_STATUS like '%Отменена %' and
                                   PR_STATUS not like '%Отменена – Верификация%' and
                                   PR_STATUS not like '%Отменена  Клиентом%' and
                                   PR_STATUS not like '%Отменена Клиентом%' or
                                   request_state_code = 'Canceled' then
                               lr.process_guid
                            end)
                    - count(distinct case
                              when PR_STATUS like '%Отменена  Клиентом%'
                                or PR_STATUS like '%Отменена Клиентом%' then
                               lr.process_guid
                            end)
                    - count(distinct case
                              when request_state_code = 'Expertise' then
                               lr.process_guid
                            end)
                    - count(distinct case
                              when request_state_code = 'AcceptQueryVerifier' or
                                   PR_STATUS = 'Ожидание верификации' or
                                   PR_STATUS = 'Верификация' then
                               lr.process_guid
                            end)
                    - count(distinct case
                              when PR_STATUS in ('Сбор подписей и подготовка к выдаче','Открытие текущего счета') then
                               lr.process_guid
                            end) cnt_app_else,
                    case when con.agr_id is not null then 'X-Sell' else 'Walk-In' end as client_type_app
             from calendar c
                 inner join dict_dep_ekz dbe on 1 = 1
                 left join loan_request lr on c.dt = trunc(lr.start_date)
                                              and lr.branch_id = dbe.branch_id
                                              and lr.dep_id = dbe.dep_id
                                              -- Added 14.10.2014 Request by Pimenov
                                              and lr.DEP_NAME is not null
                                              and lr.BRANCH_NAME is not null
                                              --
                 left join loan_request_clnt lrc on lrc.process_guid=lr.process_guid
                 left join contact con on con.agr_id=lrc.agr_id and trunc(con.contact_creation_dttm)<=trunc(lr.start_date)
             where 1 = 1
                   and c.dt >= to_date('01.01.2014','dd.mm.yyyy')
                   and c.dt < trunc(sysdate)
             group by dt,
                      week_begin,
                      month_begin,
                      dbe.BRANCH_ID,
                      dbe.BRANCH_NAME,
                      dbe.dep_id,
                      dbe.dep_name,
                      lr.title,
                      CASE
                        WHEN isloyal = 1 THEN
                         '1. ЗАЕМЩИКИ'
                        WHEN SALARYFLAG = 1 THEN
                         '2. ЗАРПЛАТНИКИ'
                        ELSE
                         '3. MASS'
                      END,
                      case
                        when title like '%Автокредитование%' or
                             title = 'Тулпар' then
                         'Авто'
                        when title like '%Ипотека%' then
                         'Ипотека'
                        when title = 'Потребительское кредитование' or
                             lower(title) = '%залог%' then
                         'Под залог'
                        when title like '%Легкий%' or lower(title) like('%кредадмин%') then
                         'Легкий'
                        when title like '%Револьверное кредитование%' then
                         'Револьверное кредитование'
                        else
                         title
                      end,
                      case when con.agr_id is not null then 'X-Sell' else 'Walk-In' end
            ) app on a.dt = app.dt
                     and a.week_begin = app.week_begin
                     and a.month_begin = app.month_begin
                     and a.BRANCH_ID = app.BRANCH_ID
                     and a.BRANCH_NAME = app.BRANCH_NAME
                     and a.dep_ID = app.dep_ID
                     and a.dep_NAME = app.dep_NAME
                     and a.title = app.title
                     and a.segm = app.segm
                     and a.product_group = app.product_group
                     and a.cli_type=app.client_type_app
  left join (select trunc(fromdate, 'dd') dt,
                    trunc(fromdate, 'iw') week_begin,
                    trunc(fromdate, 'mm') month_begin,
                    lb.BRANCH_ID,
                    lb.BRANCH_NAME,
                    lb.dep_id,
                    lb.dep_name,
                    lb.title,
                    CASE
                      WHEN isloyal = 1 THEN
                       '1. ЗАЕМЩИКИ'
                      WHEN SALARYFLAG = 1 THEN
                       '2. ЗАРПЛАТНИКИ'
                      ELSE
                       '3. MASS'
                    END SEGM,
                    case
                      when title like '%Автокредитование%' or
                           title = 'Тулпар' then
                       'Авто'
                      when title like '%Ипотека%' then
                       'Ипотека'
                      when title = 'Потребительское кредитование' or
                           lower(title) = '%залог%' then
                       'Под залог'
                      when title like '%Легкий%' or lower(title) like('%кредадмин%') then
                       'Легкий'
                      when title like '%Револьверное кредитование%' then
                       'Револьверное кредитование'
                      else
                       title
                    end product_group,
                    count(lb.contract_id) cnt_deal,
                    count(case
                            when trunc(start_date) = fromdate then
                             lb.contract_id
                          end) cnt_deal_0,
                    count(case
                            when trunc(start_date) = fromdate - 1 then
                             lb.contract_id
                          end) cnt_deal_1,
                    count(case
                            when trunc(start_date) = fromdate - 2 then
                             lb.contract_id
                          end) cnt_deal_2,
                    count(case
                            when trunc(start_date) = fromdate - 3 then
                             lb.contract_id
                          end) cnt_deal_3,
                    count(case
                            when trunc(start_date) = fromdate - 4 then
                             lb.contract_id
                          end) cnt_deal_4,
                    count(case
                            when trunc(start_date) = fromdate - 5 then
                             lb.contract_id
                          end) cnt_deal_5,
                    count(case
                            when trunc(start_date) = fromdate - 6 then
                             lb.contract_id
                          end) cnt_deal_6,
                    count(case
                            when trunc(start_date) between fromdate - 13 and
                                 fromdate - 7 then
                             lb.contract_id
                          end) cnt_deal_7_14,
                    count(case
                            when trunc(start_date) between fromdate - 20 and
                                 fromdate - 14 then
                             lb.contract_id
                          end) cnt_deal_14_21,
                    count(case
                            when trunc(start_date) <= fromdate - 21 then
                             lb.contract_id
                          end) cnt_deal_21_99,
                    sum(lb.wt_effective_rate) wt_effective_rate,
                    sum(lb.effective_rate) effective_rate,
                    sum(lb.sum_full) sum_deal,
                    sum(case
                          when trunc(start_date) = fromdate then
                           lb.sum_full
                        end) sum_deal_0,
                    sum(case
                          when trunc(start_date) = fromdate - 1 then
                           lb.sum_full
                        end) sum_deal_1,
                    sum(case
                          when trunc(start_date) = fromdate - 2 then
                           lb.sum_full
                        end) sum_deal_2,
                    sum(case
                          when trunc(start_date) = fromdate - 3 then
                           lb.sum_full
                        end) sum_deal_3,
                    sum(case
                          when trunc(start_date) = fromdate - 4 then
                           lb.sum_full
                        end) sum_deal_4,
                    sum(case
                          when trunc(start_date) = fromdate - 5 then
                           lb.sum_full
                        end) sum_deal_5,
                    sum(case
                          when trunc(start_date) = fromdate - 6 then
                           lb.sum_full
                        end) sum_deal_6,
                    sum(case
                          when trunc(start_date) between fromdate - 13 and
                               fromdate - 7 then
                           lb.sum_full
                        end) sum_deal_7_14,
                    sum(case
                          when trunc(start_date) between fromdate - 20 and
                               fromdate - 14 then
                           lb.sum_full
                        end) sum_deal_14_21,
                    sum(case
                          when trunc(start_date) <= fromdate - 21 then
                           lb.sum_full
                        end) sum_deal_21_99,
                    lb.client_type_lb
             from loan_buf lb
             group by trunc(fromdate, 'dd'),
                      trunc(fromdate, 'iw'),
                      trunc(fromdate, 'mm'),
                      lb.BRANCH_ID,
                      lb.BRANCH_NAME,
                      lb.dep_id,
                      lb.dep_name,
                      lb.title,
                      CASE
                        WHEN isloyal = 1 THEN
                         '1. ЗАЕМЩИКИ'
                        WHEN SALARYFLAG = 1 THEN
                         '2. ЗАРПЛАТНИКИ'
                        ELSE
                         '3. MASS'
                      END,
                      case
                        when title like '%Автокредитование%' or
                             title = 'Тулпар' then
                         'Авто'
                        when title like '%Ипотека%' then
                         'Ипотека'
                        when title = 'Потребительское кредитование' or
                             lower(title) = '%залог%' then
                         'Под залог'
                        when title like '%Легкий%' or lower(title) like('%кредадмин%') then
                         'Легкий'
                        when title like '%Револьверное кредитование%' then
                         'Револьверное кредитование'
                        else
                         title
                      end,
                      lb.client_type_lb
            ) b on a.dt = b.dt
                   and a.week_begin = b.week_begin
                   and a.month_begin = b.month_begin
                   and a.BRANCH_ID = b.BRANCH_ID
                   and a.BRANCH_NAME = b.BRANCH_NAME
                   and a.dep_ID = b.dep_ID
                   and a.dep_NAME = b.dep_NAME
                   and a.title = b.title
                   and a.segm = b.segm
                   and a.product_group = b.product_group
                   and a.cli_type=b.client_type_lb
  left join (select trunc(start_date, 'dd') dt,
                    trunc(start_date, 'iw') week_begin,
                    trunc(start_date, 'mm') month_begin,
                    lb.BRANCH_ID,
                    lb.BRANCH_NAME,
                    lb.dep_ID,
                    lb.dep_NAME,
                    lb.title,
                    CASE
                      WHEN isloyal = 1 THEN
                       '1. ЗАЕМЩИКИ'
                      WHEN SALARYFLAG = 1 THEN
                       '2. ЗАРПЛАТНИКИ'
                      ELSE
                       '3. MASS'
                    END SEGM,
                    case
                      when title like '%Автокредитование%' or
                           title = 'Тулпар' then
                       'Авто'
                      when title like '%Ипотека%' then
                       'Ипотека'
                      when title = 'Потребительское кредитование' or
                           lower(title) = '%залог%' then
                       'Под залог'
                      when title like '%Легкий%' or lower(title) like('%кредадмин%') then
                       'Легкий'
                      when title like '%Револьверное кредитование%' then
                       'Револьверное кредитование'
                      else
                       title
                    end product_group,
                    count(lb.contract_id) cnt_deal_cascade,
                    lb.client_type_lb
             from loan_buf lb
             group by trunc(start_date, 'dd'),
                      trunc(start_date, 'iw'),
                      trunc(start_date, 'mm'),
                      lb.BRANCH_ID,
                      lb.BRANCH_NAME,
                      lb.dep_ID,
                      lb.dep_NAME,
                      lb.title,
                      CASE
                        WHEN isloyal = 1 THEN
                         '1. ЗАЕМЩИКИ'
                        WHEN SALARYFLAG = 1 THEN
                         '2. ЗАРПЛАТНИКИ'
                        ELSE
                         '3. MASS'
                      END,
                      case
                        when title like '%Автокредитование%' or
                             title = 'Тулпар' then
                         'Авто'
                        when title like '%Ипотека%' then
                         'Ипотека'
                        when title = 'Потребительское кредитование' or
                             lower(title) = '%залог%' then
                         'Под залог'
                         when title like '%Легкий%' or lower(title) like('%кредадмин%') then
                          'Легкий'
                        when title like '%Револьверное кредитование%' then
                         'Револьверное кредитование'
                        else
                         title
                      end,
                      lb.client_type_lb
            ) c on a.dt = c.dt
                   and a.week_begin = c.week_begin
                   and a.month_begin = c.month_begin
                   and a.BRANCH_ID = c.BRANCH_ID
                   and a.BRANCH_NAME = c.BRANCH_NAME
                   and a.dep_ID = c.dep_ID
                   and a.dep_NAME = c.dep_NAME
                   and a.title = c.title
                   and a.segm = c.segm
                   and a.product_group = c.product_group
                   and a.cli_type=c.client_type_lb
    ;
    commit;
    save_debug_log('Dash_Board_Update  3');
    Truncate_Table('dash_board');
    insert into dash_board
    select *  from DASH_BOARD_tmp
    where coalesce(CALLS_COUNT,
                    CALLED_CLIENTS,
                    RPC_CLIENTS,
                    LETTERS_COUNT,
                    POSTED_CLIENTS,
                    LETTERS_DELIVERED,
                    SMS_COUNT,
                    SMS_CLIENTS,
                    SMS_DELIVERED,
                    CNT_APP,
                    CNT_APP_APPROVED,
                    CNT_APP_REJECT_SCORING,
                    CNT_APP_REJECT,
                    CNT_APP_REJECT_VERIFIER,
                    CNT_APP_CANCEL,
                    CNT_APP_CANCEL_CL,
                    CNT_APP_EXPERT,
                    CNT_APP_VERIFIER,
                    CNT_APP_DEAL_PREPARE,
                    CNT_APP_ELSE,
                    CNT_DEAL,
                    CNT_DEAL_0,
                    CNT_DEAL_1,
                    CNT_DEAL_2,
                    CNT_DEAL_3,
                    CNT_DEAL_4,
                    CNT_DEAL_5,
                    CNT_DEAL_6,
                    CNT_DEAL_7_14,
                    CNT_DEAL_14_21,
                    CNT_DEAL_21_99,
                    SUM_DEAL,
                    SUM_DEAL_0,
                    SUM_DEAL_1,
                    SUM_DEAL_2,
                    SUM_DEAL_3,
                    SUM_DEAL_4,
                    SUM_DEAL_5,
                    SUM_DEAL_6,
                    SUM_DEAL_7_14,
                    SUM_DEAL_14_21,
                    SUM_DEAL_21_99,
                    CNT_DEAL_CASCADE,
                    WT_EFFECTIVE_RATE,
                    EFFECTIVE_RATE,-1)<>-1
    ;
    commit;
    Truncate_Table('dash_board_tmp');
    Truncate_Table('app_response_tmp');
    insert into app_response_tmp
    select /*+ parallel(4) */
          distinct --response_id,
          cast(null as number) response__oid,
          '1' response_type,
          case
            when lower(lr.title) like '%легкий%' or lower(lr.title) like('%кредадмин%') then
             '1. direct'
            when lower(lr.title) not like '%легкий%' and
                 lower(lr.title) not like '%револьверн%' then
             '2. cannibal'
            else
             '3. attendant'
          end resp_type,
          lr.start_date resp_date,
          first_value(c.offer_id) over(partition by lr.PROCESS_GUID order by c.CONTACT_OPEN_DTTM desc) offer_id,
          lrc.agr_id,
          lr.PROCESS_GUID,
          cast(null as number) contract_id,
          lr.registration_number
          ,lr.branch_name
          ,lr.dep_name
    from offer o
       inner join contact c on o.offer_id = c.offer_id
       inner join loan_request_clnt lrc on o.AGR_ID = lrc.AGR_ID
       inner join loan_request lr on lr.START_DATE between c.contact_open_dttm
                                     and c.contact_open_dttm + 7 * 6 -- Переделал на 6 недель "ловли"
                                     and lrc.PROCESS_GUID = lr.PROCESS_GUID
                                     and title is not null
       inner join dict_branch_ekz dbe on lr.branch_id = dbe.branch_id
    ;
    commit;
    truncate_table('deal_response_tmp');
    insert into deal_response_tmp
    select /*+ parallel(4) */
           distinct --response_id,
           '2' response_type,
           a.resp_type,
           FIRST_VALUE(dl.FROMDATE) over(partition by a.offer_id order by decode(dl.contract_num, lr.registration_number, 0, 1), trunc(dl.FROMDATE) - trunc(FINISH_DATE)) resp_date,
           a.offer_id,
           a.agr_id,
           FIRST_VALUE(a.PROCESS_GUID) over(partition by a.offer_id order by decode(dl.contract_num, lr.registration_number, 0, 1), trunc(dl.FROMDATE) - trunc(FINISH_DATE)) PROCESS_GUID,
           FIRST_VALUE(dl.contract_id) over(partition by a.offer_id order by decode(dl.contract_num, lr.registration_number, 0, 1), trunc(dl.FROMDATE) - trunc(FINISH_DATE)) contract_id
    from app_response_tmp a
       inner join LOAN_REQUEST lr on a.PROCESS_GUID = lr.PROCESS_GUID
       inner join client_map cm on a.agr_id = cm.agr_id
       inner join DM_LOAN_BASE dl on cm.client_src = dl.cli_id and cm.src = 'C'
                                     and trunc(dl.FROMDATE) - trunc(lr.FINISH_DATE) between - 1 and 31
    ;
    commit;
    merge into inferred_response ir
      using app_response_tmp a on (ir.PROCESS_GUID = a.PROCESS_GUID and ir.response_type = '1')
      when MATCHED then
        update
           set ir.resp_type           = a.resp_type,
               ir.offer_id            = a.offer_id,
               ir.agr_id              = a.agr_id,
               ir.resp_date           = a.resp_date,
               ir.registration_number = a.registration_number
      when not matched then
        insert
          (ir.response_id,
           ir.response__oid,
           ir.response_type,
           ir.resp_type,
           ir.resp_date,
           ir.offer_id,
           ir.agr_id,
           ir.PROCESS_GUID,
           ir.contract_id,
           ir.registration_number
           ,ir.branch_name
           ,ir.dep_name
           )
        values
          (response_seq.nextval,
           a.response__oid,
           a.response_type,
           a.resp_type,
           a.resp_date,
           a.offer_id,
           a.agr_id,
           a.PROCESS_GUID,
           a.contract_id,
           a.registration_number
           ,a.branch_name
           ,a.dep_name
           )
    ;
    commit;
    merge into inferred_response ir
      using (select a.*, b.response_id response__oid, b.registration_number
                    ,b.branch_name
                    ,b.dep_name
             from deal_response_tmp a
                 inner join inferred_response b on a.process_guid = b.process_guid
                                                    and b.response_type = '1'
                                                    and a.RESP_TYPE = b.RESP_TYPE
                                                    and a.offer_id = b.offer_id
            ) a on (ir.contract_id = a.contract_id and ir.response_type = '2'
                   and ir.resp_type = a.resp_type and ir.response__oid = a.response__oid)
      when MATCHED then
        update
           set ir.agr_id              = a.agr_id,
               ir.resp_date           = a.resp_date,
               ir.registration_number = a.registration_number
      when not matched then
        insert
          (ir.response_id,
           ir.response__oid,
           ir.response_type,
           ir.resp_type,
           ir.resp_date,
           ir.offer_id,
           ir.agr_id,
           ir.PROCESS_GUID,
           ir.contract_id,
           ir.registration_number
           ,ir.branch_name
           ,ir.dep_name
           )
        values
          (response_seq.nextval,
           a.response__oid,
           a.response_type,
           a.resp_type,
           a.resp_date,
           a.offer_id,
           a.agr_id,
           a.PROCESS_GUID,
           a.contract_id,
           a.registration_number
           ,a.branch_name
           ,a.dep_name
          )
    ;
    commit;
    truncate_table('offer_for_rep');
    insert into offer_for_rep
    select /*+ parallel(4) */
           o.offer_id,
           o.agr_id,
           o.dep_id,
           o.campaign_code,
           o.offer_type,
           o.comment_ext,
           case
             when br.longname_hi in ('Закрытые подразделения') then
              'Закрытые подразделения'
             when br.longname_hi in ('АО АТФБАНК') then
              br.longname
             else
              br.longname_hi
           end region,
           max(case
                 when contact_status_code = '001' then
                  c.contact_id
               end) is_sms_delivered,
           max(case
                 when contact_status_code in ('003','004','005','006','007','010','011','012') then
                  c.contact_id
               end) is_call_got_through,
           max(case
                 when contact_status_code in ('005') then
                  c.contact_id
               end) is_call_wrong_number,
           max(case
                 when contact_status_code in ('003') then
                  c.contact_id
               end) is_call_accept,
           max(case when contact_status_code in ('010')
                  then c.contact_id
                end) is_call_accept_maybe, --Added
           greatest(o.offer_open_dttm, min(c.contact_open_dttm)) offer_open_dttm,
           LISTAGG(c.channel, ' - ') WITHIN GROUP(ORDER BY c.interraction_phase,c.contact_open_dttm ) channel_path
    from offer o
        inner join contact c on o.offer_id = c.offer_id
        left join reestr_sms rs on c.contact_id = rs.contact_id
        left join reestr_cc rc on c.contact_id = rc.contact_id
        left join REESTR_POST rp -- Добавил почту
                                on c.contact_id = rp.contact_id
        INNER JOIN (select c.id,
                           c.code,
                           c.LONGNAME,
                           c.id_hi,
                           c2.code     code_HI,
                           c2.LONGNAME LONGNAME_HI
                    from c_dep c
                       left join c_dep c2 on c.ID_HI = c2.id
                    WHERE 1 = 1
                    --AND c2.LONGNAME NOT IN ('Закрытые подразделения','АО АТФБАНК')
                   ) br on br.id = o.dep_id
    where 1 = 1
          and o.offer_status_code in ('301', '302', '303')
          and coalesce(rs.contact_id, rc.contact_id, rp.contact_id) is not null
    group by o.offer_id,
             o.agr_id,
             o.dep_id,
             o.campaign_code,
             o.offer_type,
             o.comment_ext,
             case
               when br.longname_hi in ('Закрытые подразделения') then
                'Закрытые подразделения'
               when br.longname_hi in ('АО АТФБАНК') then
                br.longname
               else
                br.longname_hi
             end,
             o.offer_open_dttm
    ;
    commit;
    truncate_table('rep_resp');
    insert into rep_resp
    select /*+ parallel(4) */
           o.campaign_code,
           o.offer_type,
           o.channel_path,
           o.region,
           o.comment_ext,
           o.offer_open_dttm,
           count(distinct o.offer_id) cnt_ofr,
           count(distinct o.is_sms_delivered) is_sms_delivered,
           count(distinct o.is_call_got_through) is_call_got_through,
           count(distinct o.is_call_wrong_number) is_call_wrong_number,
           count(distinct o.is_call_accept) is_call_accept,
           count(distinct o.is_call_accept_maybe) is_call_accept_maybe,
           count(distinct case
                   when ir1.resp_type = '1. direct' then
                    o.offer_id
                 end) cnt_app_dir,
           count(distinct case
                   when ir1.resp_type = '2. cannibal' then
                    o.offer_id
                 end) cnt_app_can,
           count(distinct case
                   when ir1.resp_type = '3. attendant' then
                    o.offer_id
                 end) cnt_app_att,
           count(distinct case
                   when ir2.resp_type = '1. direct' then
                    o.offer_id
                 end) cnt_deal_dir,
           count(distinct case
                   when ir2.resp_type = '2. cannibal' then
                    o.offer_id
                 end) cnt_deal_can,
           count(distinct case
                   when ir2.resp_type = '3. attendant' then
                    o.offer_id
                 end) cnt_deal_att,
           sum(distinct case
                 when ir2.resp_type = '1. direct' then
                  ir2.response_id * 1000000000 +
                  --nvl(dlb.sum_full * decode(dlb.val_id, 21, 182, 421, 250, 1), 0)
                  nvl(dlb.sum_full * etl.Get_NBRK_Curr(trunc(sysdate),'',dlb.val_id), 0)
                 else
                  0
               end) - sum(distinct case
                            when ir2.resp_type = '1. direct' then
                             ir2.response_id * 1000000000
                            else
                             0
                          end) sum_deal_dir,
           count(distinct case
                   when ir1.resp_type = '1. direct' and
                        trunc(ir1.resp_date) - o.offer_open_dttm < 7 then
                    o.offer_id
                 end) cnt_app_dir_7,
           count(distinct case
                   when ir1.resp_type = '1. direct' and
                        trunc(ir1.resp_date) - o.offer_open_dttm < 14 then
                    o.offer_id
                 end) cnt_app_dir_14,
           count(distinct case
                   when ir1.resp_type = '1. direct' and
                        trunc(ir1.resp_date) - o.offer_open_dttm < 21 then
                    o.offer_id
                 end) cnt_app_dir_21
    from offer_for_rep o
        left join inferred_response ir1 on o.offer_id = ir1.offer_id and ir1.response_type = '1'
        left join inferred_response ir2 on o.offer_id = ir2.offer_id
                                           and ir2.response_type = '2'
                                           and ir1.resp_type = ir2.resp_type
                                           and ir1.process_guid = ir2.process_guid
        left join dm_loan_base dlb on ir2.contract_id = dlb.contract_id
    group by o.campaign_code,
             o.offer_type,
             o.channel_path,
             o.region,
             o.comment_ext,
             o.offer_open_dttm
    ;
    commit;
    Store_Etl_Tables(l_action,'loan_buf');
    Store_Etl_Tables(l_action,'dash_board');
    Store_Etl_Tables(l_action,'app_response_tmp');
    Store_Etl_Tables(l_action,'deal_response_tmp');
    Store_Etl_Tables(l_action,'inferred_response');
    Store_Etl_Tables(l_action,'offer_for_rep');
    Store_Etl_Tables(l_action,'rep_resp');
    Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
procedure fill_ekz_reject_reason----+
  is
 l_act_name constant etl_actions_log.action_name%type:=Upper('fill_ekz_reject_reason');
 l_action  etl_actions_log.id%type;
 cursor c_cur is
 select
                        To_Char(m."PROCESS_GUID") as PROCESS_GUID,
                        (m."Rejectreason") reject_reason
    from V_EKZ_SALARY m
    ;
   type t_c_tab is table of c_cur%rowtype;
   l_dat t_c_tab;
begin
 if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  Truncate_Table('ekz_reject_reason');
   open c_cur;
   loop
     fetch c_cur bulk collect into l_dat limit gc_bulk_limit;
     exit when l_dat.count=0;
     forall i in indices of l_dat
     insert into ekz_reject_reason(process_guid,reject_reason)
     values (to_char(l_dat(i).process_guid),trim(l_dat(i).reject_reason))
     ;
   end loop;
    commit;
    Store_Etl_Tables(l_action,'ekz_reject_reason');
    Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
procedure Fill_LOYAL_New---+
  is
 l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_LOYAL_NEW');
 l_action  etl_actions_log.id%type;
 num_rows number;
BEGIN
if check_sysdate_state (l_act_name) is null then
BEGIN
/*
Условие
05.11.2015

Лояльные клиенты АО «АТФБанк»  – физические лица, соответствующие всем следующим минимальным требованиям:
-  срок обслуживания займа в АО «АТФБанк» (как действующего, так и погашенного) не менее  6 (шести) месяцев;
-  отсутствие на момент рассмотрения заявки просрочки по действующим займам АО «АТФБанк»;
-  погашенная просрочка не более 30 (тридцати) дней и не более 1 (одного) раза за последние 6 (шесть) 
   месяцев обслуживания займа в АО «АТФБанк»;
-  давность погашения займа не более 24 (двадцати четырех) месяцев на момент подачи заявления.

*/
 gv_start:=dbms_utility.get_time;
 Store_Etl_Action(l_act_name,l_action);
 save_debug_log('Fill_LOYAL_New.  1.');
 Truncate_Table('dm_loan_acc');
 save_debug_log('Fill_LOYAL_New.  2.');
 insert /*+ append */
 into dm_loan_acc
  select
         l.id          contract_id,
         l.dep_id,
         acc.acc_id,
         acc.accdep_id,
         acc.code      acc_type_code,
         acc.longname  acc_type_name,
         acc.acc_code,
         anlcode
    from colvir.l_dea@reps l
   inner join colvir.t_dea@reps d
      on l.id = d.id
     and d.dep_id = l.dep_id
   inner join colvir.q_dea@reps qd
      on qd.refer = d.refer
   inner join (select
                      qa.obj_id,
                      qa.acc_id,
                      qa.accdep_id,
                      typ.code,
                      typ.longname,
                      qa.code acc_code,
                      typ.anlcode
                 from colvir.q_acc@reps qa, colvir.Q_ENTACC_std@reps typ
                where typ.id = qa.entacc_id
                  and sysdate between qa.fromdate and qa.todate) acc
      on acc.obj_id = qd.id
   where
   acc.code <> 'CR_EXP_IN'
   ;
   num_rows:= nvl(SQL%ROWCOUNT,0);
   commit;
   save_debug_log('Fill_LOYAL_New.  2. num_rows= '||num_rows);
  delete from dm_loan_acc a
   where (acc_id, acc_type_code) in
         (select acc_id, max(acc_type_code) acc_type_code
            from dm_loan_acc
           where ACC_TYPE_CODE not in ('КФ04_П', 'CR_EXP_IN')
           group by acc_id
          having count(*) > 1)
   ;
   num_rows:= nvl(SQL%ROWCOUNT,0);
   commit;
   save_debug_log('Fill_LOYAL_New.  3. num_rows= '||num_rows);
   colvir.ETL_DWH.run_thread_5@reps; --data for LOYAL
   save_debug_log('Fill_LOYAL_New.  4.');
   truncate_table('bal_loan_ovd');
   save_debug_log('Fill_LOYAL_New.  5.');
   insert /*+ append */ into bal_loan_ovd
   select * from colvir.etl_bal_loan_ovd@reps;
   num_rows:= nvl(SQL%ROWCOUNT,0);
   commit;
   save_debug_log('Fill_LOYAL_New.  6. num_rows= '||num_rows);
   truncate_table('dm_loan_BAL_ovd');
   save_debug_log('Fill_LOYAL_New.  7.');
   insert /*+ parallel(8) append */
   into dm_loan_bal_ovd
   select /*-- parallel(8) */
     a.*,
     LEAD(a.fromdate, 1) over(partition by a.DEP_ID, a.acc_id, a.VAL_ID order by a.fromdate) todate,
     lag(a.fromdate, 1) over(partition by a.DEP_ID, a.acc_id, a.VAL_ID order by a.fromdate) beforedate
      from (select distinct a.val_id,
                            a.dep_id,
                            a.id acc_id,
                            a.fromdate,
                            a.bal_in,
                            a.bal_out,
                            a.natval_in,
                            a.natval_out,
                            first_value(nvl(b.bal_in, 0)) over(partition by a.id, a.val_id, a.fromdate order by b.fromdate desc nulls last) bal_in_flzo,
                            first_value(nvl(b.bal_out, 0)) over(partition by a.id, a.val_id, a.fromdate order by b.fromdate desc nulls last) bal_out_flzo,
                            first_value(nvl(b.natval_in, 0)) over(partition by a.id, a.val_id, a.fromdate order by b.fromdate desc nulls last) natval_in_flzo,
                            first_value(nvl(b.natval_out, 0)) over(partition by a.id, a.val_id, a.fromdate order by b.fromdate desc nulls last) natval_out_flzo
              from bal_loan_ovd a
              left join bal_loan_ovd b
                on a.id = b.id
               and a.val_id = b.val_id
               and b.flzo = 1
               and b.fromdate <= a.fromdate
             where a.flzo = 0
               and a.anlcode in ('CR_EXP_PD', 'CR_WR_PD')) a
   ;
   num_rows:= nvl(SQL%ROWCOUNT,0);
   commit;
   --save_debug_log('Fill_LOYAL_New.  8.');
   --убрать сбор статистики Chshuka Dmitriy September 17, 2015 5:11 PM
   --DBMS_STATS.GATHER_TABLE_STATS(ownname=>'DWH_BUFFER',tabname=>'DM_LOAN_BAL_OVD',cascade=>true);
   save_debug_log('Fill_LOYAL_New.  9. num_rows= '||num_rows);
   truncate_table('DM_LOAN_BAL_OVD_1');
   save_debug_log('Fill_LOYAL_New.  10.');
   insert /*+ parallel(8) append */
   into DM_LOAN_BAL_OVD_1
    select /*-- parallel(8) */
           a.val_id,
           a.DEP_ID,
           a.acc_id,
           acc.CONTRACT_ID,
           a.FROMDATE,
           nvl(a.TODATE, to_date('31.12.2999', 'dd.mm.yyyy')) TODATE,
           a.BEFOREDATE,
           a.BAL_in + a.BAL_IN_FLZO bal_in,
           a.BAL_OUT + a.BAL_out_FLZO bal_out,
           a.natval_in + a.natval_IN_FLZO natval_in,
           a.natval_OUT + a.natval_out_FLZO natval_out
      from dm_loan_BAL_OVD a
     inner join dm_loan_acc acc
        on a.ACC_ID = acc.ACC_ID
       and acc.ACC_TYPE_CODE = 'КФ04_ОД'
   ;
   num_rows:= nvl(SQL%ROWCOUNT,0);
   commit;
   save_debug_log('Fill_LOYAL_New.  11. num_rows= '||num_rows);
   truncate_table('DM_LOAN_BAL_OVD_2');
   save_debug_log('Fill_LOYAL_New.  12.');
   insert /*+ parallel(8) append */
   into DM_LOAN_BAL_OVD_2
    select /*-- parallel(8) */
           a.val_id,
           a.DEP_ID,
           a.acc_id,
           acc.CONTRACT_ID,
           a.FROMDATE,
           nvl(a.TODATE, to_date('31.12.2999', 'dd.mm.yyyy')) TODATE,
           a.BEFOREDATE,
           a.BAL_in + a.BAL_IN_FLZO bal_in,
           a.BAL_OUT + a.BAL_out_FLZO bal_out,
           a.natval_in + a.natval_IN_FLZO natval_in,
           a.natval_OUT + a.natval_out_FLZO natval_out
      from dm_loan_BAL_OVD a
     inner join dm_loan_acc acc
        on a.ACC_ID = acc.ACC_ID
       and acc.ACC_TYPE_CODE = 'CR_WR_PD'
    ;
    num_rows:= nvl(SQL%ROWCOUNT,0);
    commit;
    save_debug_log('Fill_LOYAL_New.  13. num_rows= '||num_rows);
    truncate_table('DM_LOAN_BAL_OVD_3');
    save_debug_log('Fill_LOYAL_New.  14.');
    insert /*+ parallel(8) append */
    into DM_LOAN_BAL_OVD_3
    select /*-- parallel(8) */
    distinct val_id, CONTRACT_ID, FROMDATE
      from (select a.val_id, acc.CONTRACT_ID, a.FROMDATE
              from dm_loan_BAL_OVD a
             inner join dm_loan_acc acc
                on a.ACC_ID = acc.ACC_ID
               and acc.ACC_TYPE_CODE = 'КФ04_ОД'
            union
            select a.val_id, acc.CONTRACT_ID, a.FROMDATE
              from dm_loan_BAL_OVD a
             inner join dm_loan_acc acc
                on a.ACC_ID = acc.ACC_ID
               and acc.ACC_TYPE_CODE = 'CR_WR_PD')
     ;
     num_rows:= nvl(SQL%ROWCOUNT,0);
     commit;
     save_debug_log('Fill_LOYAL_New.  15. num_rows= '||num_rows);
     --убрать сбор статистики Chshuka Dmitriy September 17, 2015 5:11 PM
     --DBMS_STATS.GATHER_TABLE_STATS(ownname=>'DWH_BUFFER',tabname=>'DM_LOAN_BAL_OVD_1',cascade=>true);
     --DBMS_STATS.GATHER_TABLE_STATS(ownname=>'DWH_BUFFER',tabname=>'DM_LOAN_BAL_OVD_2',cascade=>true);
     --DBMS_STATS.GATHER_TABLE_STATS(ownname=>'DWH_BUFFER',tabname=>'DM_LOAN_BAL_OVD_3',cascade=>true);
     --save_debug_log('Fill_LOYAL_New.  16.');
     truncate_table('DM_LOAN_BAL_OVD_tmp_1');
     save_debug_log('Fill_LOYAL_New.  17.');
     /* код не оптимален  Chshuka Dmitriy September 17, 2015 5:11 PM
        код оптимален Chshuka Dmitriy September 18, 2015 11:24 AM
     */
     insert /*+ parallel(8) append */
     into DM_LOAN_BAL_OVD_tmp_1
     select /*-- parallel(8) */
      distinct a.val_id,
               a.CONTRACT_ID,
               a.FROMDATE,
               first_value(b.bal_in) over(partition by a.val_id, a.CONTRACT_ID, a.FROMDATE order by b.FROMDATE desc) ovd_bal_in,
               first_value(b.bal_out) over(partition by a.val_id, a.CONTRACT_ID, a.FROMDATE order by b.FROMDATE desc) ovd_bal_out,
               first_value(b.natval_in) over(partition by a.val_id, a.CONTRACT_ID, a.FROMDATE order by b.FROMDATE desc) ovd_natval_in,
               first_value(b.natval_out) over(partition by a.val_id, a.CONTRACT_ID, a.FROMDATE order by b.FROMDATE desc) ovd_natval_out
        from DM_LOAN_BAL_OVD_3 a
        left join DM_LOAN_BAL_OVD_1 b
          on a.CONTRACT_ID = b.CONTRACT_ID
         and a.VAL_ID = b.VAL_ID
         and b.FROMDATE <= a.FROMDATE
      ;
      num_rows:= nvl(SQL%ROWCOUNT,0);
      --оптимальный код 13строк ниже
      --Chshuka Dmitriy September 17, 2015 5:11 PM
      --код не оптимален Chshuka Dmitriy September 18, 2015 11:24 AM
      /*
      INSERT INTO DM_LOAN_BAL_OVD_TMP_1
      SELECT *+ parallel(8) USE_NL (B) *
         DISTINCT
            A.VAL_ID
            , A.CONTRACT_ID
            , A.FROMDATE
            , FIRST_VALUE(B.BAL_IN) OVER(PARTITION BY A.VAL_ID, A.CONTRACT_ID, A.FROMDATE ORDER BY B.FROMDATE DESC) OVD_BAL_IN
            , FIRST_VALUE(B.BAL_OUT) OVER(PARTITION BY A.VAL_ID, A.CONTRACT_ID, A.FROMDATE ORDER BY B.FROMDATE DESC) OVD_BAL_OUT
            , FIRST_VALUE(B.NATVAL_IN) OVER(PARTITION BY A.VAL_ID, A.CONTRACT_ID, A.FROMDATE ORDER BY B.FROMDATE DESC) OVD_NATVAL_IN
            , FIRST_VALUE(B.NATVAL_OUT) OVER(PARTITION BY A.VAL_ID, A.CONTRACT_ID, A.FROMDATE ORDER BY B.FROMDATE DESC) OVD_NATVAL_OUT
      FROM DM_LOAN_BAL_OVD_3 A
      LEFT JOIN DM_LOAN_BAL_OVD_1 B ON A.CONTRACT_ID = B.CONTRACT_ID AND A.VAL_ID = B.VAL_ID AND B.FROMDATE <= A.FROMDATE
      ;*/
      commit;
      save_debug_log('Fill_LOYAL_New.  18. num_rows= '||num_rows);
      truncate_table('DM_LOAN_BAL_OVD_tmp_2');
      save_debug_log('Fill_LOYAL_New.  19.');
      insert /*+ parallel(8) append */
      into DM_LOAN_BAL_OVD_tmp_2
      select /*-- parallel(8) */
       a.val_id,
       a.CONTRACT_ID,
       a.FROMDATE,
       LEAD(a.fromdate, 1) over(partition by a.CONTRACT_ID, a.VAL_ID order by a.fromdate) todate,
       lag(a.fromdate, 1) over(partition by a.CONTRACT_ID, a.VAL_ID order by a.fromdate) beforedate,
       a.ovd_bal_in,
       a.ovd_bal_out,
       a.ovd_natval_in,
       a.ovd_natval_out,
       a.ow_bal_in,
       a.ow_bal_out,
       a.ow_natval_in,
       a.ow_natval_out
        from (select distinct a.val_id,
                              a.CONTRACT_ID,
                              a.FROMDATE,
                              a.ovd_bal_in,
                              a.ovd_bal_out,
                              a.ovd_natval_in,
                              a.ovd_natval_out,
                              first_value(c.bal_in) over(partition by a.val_id, a.CONTRACT_ID, a.FROMDATE order by c.FROMDATE desc) ow_bal_in,
                              first_value(c.bal_out) over(partition by a.val_id, a.CONTRACT_ID, a.FROMDATE order by c.FROMDATE desc) ow_bal_out,
                              first_value(c.natval_in) over(partition by a.val_id, a.CONTRACT_ID, a.FROMDATE order by c.FROMDATE desc) ow_natval_in,
                              first_value(c.natval_out) over(partition by a.val_id, a.CONTRACT_ID, a.FROMDATE order by c.FROMDATE desc) ow_natval_out
                from DM_LOAN_BAL_OVD_tmp_1 a
                left join DM_LOAN_BAL_OVD_2 c
                  on a.CONTRACT_ID = c.CONTRACT_ID
                 and a.VAL_ID = c.VAL_ID
                 and c.FROMDATE <= a.FROMDATE) a
     ;
     num_rows:= nvl(SQL%ROWCOUNT,0);
     commit;
     save_debug_log('Fill_LOYAL_New.  20. num_rows= '||num_rows);
     truncate_table('dm_overdue');
     save_debug_log('Fill_LOYAL_New.  21.');
     insert /*+ parallel(8) append */
     into dm_overdue
     select /*-- parallel(8) */
       a.val_id,
       a.contract_id,
       min(a.fromdate) dt_start,
       decode(a.dt_end, null, trunc(sysdate), a.dt_end) dt_end,
       max(nvl(a.ovd_bal_out, 0) + nvl(a.ow_bal_out, 0)) max_overdue_sum,
       min(case
             when nvl(a.ovd_bal_out, 0) + nvl(a.ow_bal_out, 0) > 0 then
              nvl(a.ovd_bal_out, 0) + nvl(a.ow_bal_out, 0)
           end) min_overdue_sum,
       sum((nvl(a.ovd_bal_out, 0) + nvl(a.ow_bal_out, 0)) *
           (nvl(todate, trunc(sysdate - 1)) - a.fromdate)) /
       decode((decode(a.dt_end, null, trunc(sysdate), a.dt_end) -
              min(a.fromdate)),
              0,
              1,
              (decode(a.dt_end, null, trunc(sysdate), a.dt_end) -
              min(a.fromdate))) avg_overdue_sum,
       decode(a.dt_end, null, trunc(sysdate), a.dt_end) - min(a.fromdate) term,
       case
         when a.dt_end is null then
          1
         else
          0
       end is_current
        from (select distinct a.val_id,
                              a.contract_id,
                              a.fromdate,
                              a.todate,
                              a.beforedate,
                              a.ovd_bal_in,
                              a.ovd_bal_out,
                              a.ovd_natval_in,
                              a.ovd_natval_out,
                              a.ow_bal_in,
                              a.ow_bal_out,
                              a.ow_natval_in,
                              a.ow_natval_out,
                              first_value(b.fromdate) over(partition by a.contract_id, a.val_id, a.fromdate order by b.fromdate nulls last) dt_end
                from DM_LOAN_BAL_OVD_tmp_2 a
               inner join dm_loan_base dlb
                  on a.contract_id = dlb.contract_id
                 and a.val_id = dlb.val_id
                left join DM_LOAN_BAL_OVD_tmp_2 b
                  on a.contract_id = b.contract_id
                 and a.val_id = b.val_id
                 and b.fromdate >= a.fromdate
                 and nvl(b.ovd_bal_out, 0) + nvl(b.ow_bal_out, 0) = 0
               where 1 = 1
              --    and dla.acc_type_code='КФ04_ОД'
              --    and a.val_id=21
               order by a.fromdate) a
      having max(nvl(a.ovd_bal_out, 0) + nvl(a.ow_bal_out, 0)) > 0
       group by a.val_id,
                a.contract_id,
                decode(a.dt_end, null, trunc(sysdate), a.dt_end),
                case
                  when a.dt_end is null then
                   1
                  else
                   0
                end
    ;
    num_rows:= nvl(SQL%ROWCOUNT,0);
    commit;
    --save_debug_log('Fill_LOYAL_New.  22.');
    --убрать сбор статистики Chshuka Dmitriy September 17, 2015 5:11 PM
    --DBMS_STATS.GATHER_TABLE_STATS(ownname=>'DWH_BUFFER',tabname=>'DM_OVERDUE',cascade=>true);
    save_debug_log('Fill_LOYAL_New.  23. num_rows= '||num_rows);
    truncate_table('loan_bal_tmp_1');
    save_debug_log('Fill_LOYAL_New.  24.');
    insert /*+ parallel(8) append */
    into loan_bal_tmp_1
    select /*-- parallel(8) */
    distinct
      a.val_id
     ,a.id acc_id
     ,a.FROMDATE
      from BAL_LOAN_OVD a
     where 1 = 1
       and flzo in (1, 0)
       and planfl in (1, 0)
       and a.ANLCODE = 'CR_BAL'
    ;
    num_rows:= nvl(SQL%ROWCOUNT,0);
    commit;
    save_debug_log('Fill_LOYAL_New.  25. num_rows= '||num_rows);
    truncate_table('loan_bal_tmp_2');
    save_debug_log('Fill_LOYAL_New.  26.');
    /* код не оптимален Chshuka Dmitriy September 17, 2015 5:11 PM
       код оптимален Chshuka Dmitriy September 18, 2015 11:24 AM
    */
    insert /*+ parallel(8) append */
    into loan_bal_tmp_2
    select /*-- parallel(8) */
     distinct a.val_id,
             a.acc_id,
             a.FROMDATE,
             first_value(b.bal_in) over(partition by a.val_id, a.acc_id, a.FROMDATE order by b.FROMDATE desc) bal_in,
             first_value(b.bal_out) over(partition by a.val_id, a.acc_id, a.FROMDATE order by b.FROMDATE desc) bal_out,
             first_value(b.natval_in) over(partition by a.val_id, a.acc_id, a.FROMDATE order by b.FROMDATE desc) natval_in,
             first_value(b.natval_out) over(partition by a.val_id, a.acc_id, a.FROMDATE order by b.FROMDATE desc) natval_out
      from loan_bal_tmp_1 a
      left join BAL_LOAN_OVD b
        on a.acc_id = b.id
       and a.VAL_ID = b.VAL_ID
       and b.FROMDATE <= a.FROMDATE
       and b.ANLCODE = 'CR_BAL'
       and b.flzo = 0
       and b.planfl = 0
    ;
    num_rows:= nvl(SQL%ROWCOUNT,0);
    --оптимальный код 14 строк ниже
    --Chshuka Dmitriy September 17, 2015 5:11 PM
    --код не оптимален Chshuka Dmitriy September 18, 2015 11:24 AM
    /*INSERT INTO LOAN_BAL_TMP_2
    SELECT \*+ parallel(8) USE_NL (B) *\
       DISTINCT
       A.VAL_ID
       , A.ACC_ID
       , A.FROMDATE
       , FIRST_VALUE(B.BAL_IN) OVER(PARTITION BY A.VAL_ID, A.ACC_ID, A.FROMDATE ORDER BY B.FROMDATE DESC) BAL_IN
       , FIRST_VALUE(B.BAL_OUT) OVER(PARTITION BY A.VAL_ID, A.ACC_ID, A.FROMDATE ORDER BY B.FROMDATE DESC) BAL_OUT
       , FIRST_VALUE(B.NATVAL_IN) OVER(PARTITION BY A.VAL_ID, A.ACC_ID, A.FROMDATE ORDER BY B.FROMDATE DESC) NATVAL_IN
       , FIRST_VALUE(B.NATVAL_OUT) OVER(PARTITION BY A.VAL_ID, A.ACC_ID, A.FROMDATE ORDER BY B.FROMDATE DESC) NATVAL_OUT
    FROM LOAN_BAL_TMP_1 A
    LEFT JOIN BAL_LOAN_OVD B ON A.ACC_ID = B.ID AND A.VAL_ID = B.VAL_ID AND B.FROMDATE <= A.FROMDATE AND B.ANLCODE = 'CR_BAL'
             AND B.FLZO = 0 AND B.PLANFL = 0
    ;*/
    commit;
    save_debug_log('Fill_LOYAL_New.  27. num_rows= '||num_rows);
    truncate_table('loan_bal_tmp_3');
    save_debug_log('Fill_LOYAL_New.  28.');
    insert /*+ parallel(8) append */
    into loan_bal_tmp_3
    select /*-- parallel(8) */
    distinct a.val_id,
             a.acc_id,
             a.FROMDATE,
             a.bal_in,
             a.bal_out,
             a.natval_in,
             a.natval_out,
             first_value(b.bal_in) over(partition by a.val_id, a.acc_id, a.FROMDATE order by b.FROMDATE desc) bal_in_flzo,
             first_value(b.bal_out) over(partition by a.val_id, a.acc_id, a.FROMDATE order by b.FROMDATE desc) bal_out_flzo,
             first_value(b.natval_in) over(partition by a.val_id, a.acc_id, a.FROMDATE order by b.FROMDATE desc) natval_in_flzo,
             first_value(b.natval_out) over(partition by a.val_id, a.acc_id, a.FROMDATE order by b.FROMDATE desc) natval_out_flzo
      from loan_bal_tmp_2 a
      left join BAL_LOAN_OVD b
        on a.acc_id = b.id
       and a.VAL_ID = b.VAL_ID
       and b.FROMDATE <= a.FROMDATE
       and b.ANLCODE = 'CR_BAL'
       and b.flzo = 1
       and b.planfl = 0
    ;
    num_rows:= nvl(SQL%ROWCOUNT,0);
    commit;
    save_debug_log('Fill_LOYAL_New.  29. num_rows= '||num_rows);
    truncate_table('loan_bal_tmp_4');
    save_debug_log('Fill_LOYAL_New.  30.');
    insert /*+ parallel(8) append */
    into loan_bal_tmp_4
    select /*-- parallel(8) */
    distinct a.val_id,
             a.acc_id,
             a.FROMDATE,
             a.bal_in,
             a.bal_out,
             a.natval_in,
             a.natval_out,
             a.bal_in_flzo,
             a.bal_out_flzo,
             a.natval_in_flzo,
             a.natval_out_flzo,
             first_value(b.bal_in) over(partition by a.val_id, a.acc_id, a.FROMDATE order by b.FROMDATE desc) bal_in_planfl,
             first_value(b.bal_out) over(partition by a.val_id, a.acc_id, a.FROMDATE order by b.FROMDATE desc) bal_out_planfl,
             first_value(b.natval_in) over(partition by a.val_id, a.acc_id, a.FROMDATE order by b.FROMDATE desc) natval_in_planfl,
             first_value(b.natval_out) over(partition by a.val_id, a.acc_id, a.FROMDATE order by b.FROMDATE desc) natval_out_planfl
      from loan_bal_tmp_3 a
      left join BAL_LOAN_OVD b
        on a.acc_id = b.id
       and a.VAL_ID = b.VAL_ID
       and b.FROMDATE <= a.FROMDATE
       and b.ANLCODE = 'CR_BAL'
       and b.flzo = 0
       and b.planfl = 1
     ;
     num_rows:= nvl(SQL%ROWCOUNT,0);
     commit;
     save_debug_log('Fill_LOYAL_New.  31. num_rows= '||num_rows);
     truncate_table('loan_bal_tmp_5');
     save_debug_log('Fill_LOYAL_New.  32.');
     insert /*+ parallel(8) append */
     into loan_bal_tmp_5
      select /*-- parallel(8) */
      distinct a.val_id,
               a.acc_id,
               a.FROMDATE,
               a.bal_in,
               a.bal_out,
               a.natval_in,
               a.natval_out,
               a.bal_in_flzo,
               a.bal_out_flzo,
               a.natval_in_flzo,
               a.natval_out_flzo,
               a.bal_in_planfl,
               a.bal_out_planfl,
               a.natval_in_planfl,
               a.natval_out_planfl,
               first_value(b.bal_in) over(partition by a.val_id, a.acc_id, a.FROMDATE order by b.FROMDATE desc) bal_in_flzo_planfl,
               first_value(b.bal_out) over(partition by a.val_id, a.acc_id, a.FROMDATE order by b.FROMDATE desc) bal_out_flzo_planfl,
               first_value(b.natval_in) over(partition by a.val_id, a.acc_id, a.FROMDATE order by b.FROMDATE desc) natval_in_flzo_planfl,
               first_value(b.natval_out) over(partition by a.val_id, a.acc_id, a.FROMDATE order by b.FROMDATE desc) natval_out_flzo_planfl
        from loan_bal_tmp_4 a
        left join BAL_LOAN_OVD b
          on a.acc_id = b.id
          and a.VAL_ID = b.VAL_ID
          and b.FROMDATE <= a.FROMDATE
          and b.ANLCODE = 'CR_BAL'
          and b.flzo = 1
          and b.planfl = 1
       ;
       num_rows:= nvl(SQL%ROWCOUNT,0);
       commit;
       save_debug_log('Fill_LOYAL_New.  33. num_rows= '||num_rows);
       truncate_table('dm_loan_bal_principal');
       save_debug_log('Fill_LOYAL_New.  34.');
       insert /*+ parallel(8) append */
       into dm_loan_bal_principal
       select /*-- parallel(8) */
         dlb.CONTRACT_ID,
         dlb.ACC_ID,
         dlb.VAL_ID,
         l.fromdate,
         nvl(l.bal_in, 0) + nvl(l.bal_in_flzo, 0) + nvl(l.bal_in_planfl, 0) +
         nvl(l.bal_in_flzo_planfl, 0) bal_in,
         nvl(l.bal_out, 0) + nvl(l.bal_out_flzo, 0) + nvl(l.bal_out_planfl, 0) +
         nvl(l.bal_out_flzo_planfl, 0) bal_out
          from loan_bal_tmp_5 l
         inner join DM_LOAN_ACC dla
            on l.ACC_ID = dla.ACC_ID
         inner join dm_loan_base dlb
            on dla.CONTRACT_ID = dlb.CONTRACT_ID
           and l.VAL_ID = dlb.VAL_ID
        ;
        num_rows:= nvl(SQL%ROWCOUNT,0);
        commit;
        save_debug_log('Fill_LOYAL_New.  35. num_rows= '||num_rows);
        truncate_table('loyal_1');
        save_debug_log('Fill_LOYAL_New.  36.');
        insert /*+ parallel(8) append */
        into loyal_1
          select /*-- parallel(8) */
           *
            from (select distinct dlb.CLI_ID,
                                  dcb.cli_code,
                                  dcb.iin,
                                  dcb.rnn,
                                  dlb.CONTRACT_ID,
                                  dlb.fromdate,
                                  dlb.todate,
                                  dlb.state,
                                  first_value(dl.fromdate) over(partition by dlb.contract_id order by dl.fromdate desc) act_dt,
                                  first_value(dl.bal_out) over(partition by dlb.contract_id order by dl.fromdate desc) act_bal
                    from DM_LOAN_base dlb
                   inner join DM_LOAN_BAL_PRINCIPAL dl
                      on dlb.contract_id = dl.contract_id
                   inner join DM_LOAN_base_add da
                      on dlb.contract_id = da.id
                   inner join DM_cif_base dcb
                      on dlb.cli_id = dcb.id
                   where 1 = 1
                     and dcb.is_ul = 0
                     and dlb.state in ('Актуален',
                                       'Погашен',
                                       'Выкуплен КИК-ом')
                     and vcc in
                         ('107320', '107329', '107330', '107340', '107390', '999992'))
           where 1 = 1
             and months_between(case
                                  when act_bal = 0 then
                                   act_dt
                                  else
                                   todate
                                end,
                                fromdate) > 6
             and months_between(trunc(sysdate) - 1, fromdate) >= 6 and months_between(trunc(sysdate) - 1, case when act_bal = 0 then act_dt else todate
        end)<24
       ;
       num_rows:= nvl(SQL%ROWCOUNT,0);
   commit;
   save_debug_log('Fill_LOYAL_New.  37. num_rows= '||num_rows);
   --delete from LOYAL_FIN_TMPTT;
   --commit;
   truncate_table('LOYAL_FIN_TMPTT');
   save_debug_log('Fill_LOYAL_New.  38.');
   insert /*+ parallel(8) append */
   into LOYAL_FIN_TMPTT
      select /*-- parallel(8) */
             a.CLI_ID,
             a.cli_code,
             a.iin,
             a.rnn,
             max(case
                   when a.act_bal = 0 then
                    0
                   else
                    1
                 end) is_act
        from loyal_1 a
        left join (select distinct b.cli_id
                     from DM_OVERDUE a
                    inner join DM_LOAN_base b
                       on a.CONTRACT_ID = b.CONTRACT_ID
                    where is_current = 1
                      and MAX_OVERDUE_SUM *
                          --decode(b.val_id, 21, 182, 421, 250, 1) >= 5000) b
                          etl.Get_NBRK_Curr(trunc(sysdate),'',b.val_id) >= 5000) b
          on a.cli_id = b.cli_id
        left join (select distinct b.cli_id
                     from DM_LOAN_acc a
                    inner join DM_LOAN_base b
                       on a.CONTRACT_ID = b.CONTRACT_ID
                    where a.anlcode = 'CR_WR_PD') c
          on a.cli_id = c.cli_id
        left join (select distinct b.cli_id
                     from DM_OVERDUE a
                    inner join loyal_1 b
                       on a.contract_id = b.contract_id
                      and add_months(case
                                       when act_bal = 0 then
                                        act_dt
                                       else
                                        todate
                                     end,
                                     -6) > dt_end
                      --and add_months(trunc(sysdate) - 1, -6) > dt_end  удалил 2015.11.05, т.к. условие не логично
                      and add_months(trunc(sysdate) - 1, -6) < dt_end --просрочки за последние 6месяцев     
                      and term > 30) d
          on a.cli_id = d.cli_id
        
        left join (select b.cli_id, count(*) as count_ovrd
                     from DM_OVERDUE a
                    inner join loyal_1 b
                       on a.contract_id = b.contract_id
                      --and add_months(trunc(sysdate) - 1, -6) > dt_end  удалил 2015.11.05, т.к. условие не логично
                      and add_months(trunc(sysdate) - 1, -6) < dt_end --просрочки за последние 6месяцев     
                      and term <= 30 group by b.cli_id) d1
          on a.cli_id = d1.cli_id
                   
        left join (select distinct d.CLI_ID
                     from DM_LOAN_base_add a
                    inner join DM_LOAN_BASE d
                       on a.id = d.CONTRACT_ID
                    where nvl(RESTRUCT_CODE_ATF, 'N') <> 'N'
                       or contract_num like '%/Mc%'
                       or contract_num like '%/Мс%') e
          on a.cli_id = e.cli_id
        left join lams.v_BLACK_LIST@EKZ bl1
          on a.iin = bl1.iin
        left join lams.v_BLACK_LIST@EKZ bl2
          on a.rnn = bl2.rnn
       where 1 = 1
         --and a.iin = '670125302351'
         and b.cli_id is null
         and c.cli_id is null
         and d.cli_id is null
         and nvl(d1.count_ovrd,0) <=1 --добавлен 2015.11.05  просрочка не более 30 (тридцати) дней и не более 1 (одного) раза за последние 6 (шесть) месяцев обслуживания займа в АО «АТФБанк»;
         and e.cli_id is null
         and bl1.iin is null
         and bl2.rnn is null
       group by a.CLI_ID, a.cli_code, a.iin, a.rnn
     ;
     num_rows:= nvl(SQL%ROWCOUNT,0);
     commit;
     save_debug_log('Fill_LOYAL_New.  39. num_rows= '||num_rows);
     Store_Etl_Tables(l_action,'loyal_fin_tmptt');
     save_debug_log('Fill_LOYAL_New.  40.');
     if  Check_Etl_Tables('loyal_fin_tmptt') then
         -- commit; ---'ok, data can be inserted'
          Truncate_Table('loyal_fin');
          --delete from loyal_fin;
          --commit;
          save_debug_log('Fill_LOYAL_New.  41.');
          insert  /*+ append */
          into loyal_fin
          select * from LOYAL_FIN_TMPTT;
          num_rows:= nvl(SQL%ROWCOUNT,0);
          commit;
          save_debug_log('Fill_LOYAL_New.  42. num_rows= '||num_rows);
      else
          rollback;
       --   gv_err_count:=gv_err_count+1;
          gc_Msg_tbl_info := 'Необходимо проверить кол-во строк в loyal_fin_tmptt!!!';
          Send_Etl_Results(sysdate,false);
          gc_Msg_tbl_info := '';
     end if;
     --save_debug_log('Fill_LOYAL_New.  43.');
     --убрать сбор статистики Chshuka Dmitriy September 17, 2015 5:11 PM
     --DBMS_STATS.GATHER_TABLE_STATS(ownname=>'DWH_BUFFER',tabname=>'LOYAL_FIN',cascade=>true);
     save_debug_log('Fill_LOYAL_New.  44.');
    Store_Etl_Tables(l_action,'dm_loan_acc');
    Store_Etl_Tables(l_action,'bal_loan_ovd');
    Store_Etl_Tables(l_action,'dm_loan_BAL_ovd');
    Store_Etl_Tables(l_action,'DM_LOAN_BAL_OVD_1');
    Store_Etl_Tables(l_action,'DM_LOAN_BAL_OVD_2');
    Store_Etl_Tables(l_action,'DM_LOAN_BAL_OVD_3');
    Store_Etl_Tables(l_action,'DM_LOAN_BAL_OVD_tmp_1');
    Store_Etl_Tables(l_action,'DM_LOAN_BAL_OVD_tmp_2');
    Store_Etl_Tables(l_action,'dm_overdue');
    Store_Etl_Tables(l_action,'loan_bal_tmp_1');
    Store_Etl_Tables(l_action,'loan_bal_tmp_2');
    Store_Etl_Tables(l_action,'loan_bal_tmp_3');
    Store_Etl_Tables(l_action,'loan_bal_tmp_4');
    Store_Etl_Tables(l_action,'loan_bal_tmp_5');
    Store_Etl_Tables(l_action,'dm_loan_bal_principal');
    Store_Etl_Tables(l_action,'loyal_1');
    save_debug_log('Fill_LOYAL_New.  45.');
    Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
Exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
END;
procedure Fill_Payments_Schedulers ----+
  is
 l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_Payments_Schedulers');
 l_action  etl_actions_log.id%type;
BEGIN
if check_sysdate_state (l_act_name) is null then
BEGIN
 gv_start:=dbms_utility.get_time;
 Store_Etl_Action(l_act_name,l_action);
  save_debug_log('Fill_Payments_Schedulers.  1.');
  colvir.ETL_DWH.run_thread_6@reps;---data for PAYM_SCHED
  save_debug_log('Fill_Payments_Schedulers.  2.');
  truncate_table('dm_loan_paym_3');
  save_debug_log('Fill_Payments_Schedulers.  3.');
   insert /*+ parallel(8) append*/
   into dm_loan_paym_3
   select * from colvir.etl_dm_loan_paym_3@reps;
   commit;
   save_debug_log('Fill_Payments_Schedulers.  4.');
  truncate_table('loan_buf_ekz');
  save_debug_log('Fill_Payments_Schedulers.  5.');
  insert /*+ parallel(8) append*/
  into loan_buf_ekz
  select distinct
         first_value(lrc.process_guid) over (partition by dl.contract_id order by decode(dl.contract_num,lr.registration_number,0,1),trunc(dl.FROMDATE)-trunc(FINISH_DATE)) process_guid,
         first_value(lrc.agr_id) over (partition by dl.contract_id order by decode(dl.contract_num,lr.registration_number,0,1),trunc(dl.FROMDATE)-trunc(FINISH_DATE)) agr_id,
         first_value(lr.START_DATE) over (partition by dl.contract_id order by decode(dl.contract_num,lr.registration_number,0,1),trunc(dl.FROMDATE)-trunc(FINISH_DATE)) START_DATE,
         first_value(lr.BRANCH_ID) over (partition by dl.contract_id order by decode(dl.contract_num,lr.registration_number,0,1),trunc(dl.FROMDATE)-trunc(FINISH_DATE)) BRANCH_ID,
         first_value(lr.TITLE) over (partition by dl.contract_id order by decode(dl.contract_num,lr.registration_number,0,1),trunc(dl.FROMDATE)-trunc(FINISH_DATE)) TITLE,
         first_value(lr.isloyal) over (partition by dl.contract_id order by decode(dl.contract_num,lr.registration_number,0,1),trunc(dl.FROMDATE)-trunc(FINISH_DATE)) isloyal,
         first_value(lr.salaryflag) over (partition by dl.contract_id order by decode(dl.contract_num,lr.registration_number,0,1),trunc(dl.FROMDATE)-trunc(FINISH_DATE)) salaryflag,
         first_value(dbe.branch_name) over (partition by dl.contract_id order by decode(dl.contract_num,lr.registration_number,0,1),trunc(dl.FROMDATE)-trunc(FINISH_DATE)) branch_name,
         --dl.sum_full*decode(dl.val_id,21,182,421,250,1) sum_full,
         dl.sum_full*etl.Get_NBRK_Curr(trunc(sysdate),'',dl.val_id) sum_full,
         dl.FROMDATE,
         dl.contract_id,
         der.effective_rate,
         --dl.sum_full*decode(dl.val_id,21,182,421,250,1)*der.effective_rate wt_effective_rate,
         dl.sum_full*etl.Get_NBRK_Curr(trunc(sysdate),'',dl.val_id)*der.effective_rate wt_effective_rate,
         dl.dep_id
  from DM_LOAN_BASE dl
  left join dm_loan_base_add da
  on dl.CONTRACT_ID=da.id
  left join DICT_EFFECTIVE_RATE der
  on der.term=least(greatest(round(decode(term_type,null,months_between(todate,fromdate),term_cnt/decode(term_type,'M',1,'D',30.4167,'Y',1/12))),1),180)
    and der.rate=least(greatest(round(coalesce(dl.rate,pcn_rate,0)*2)/2,0),50)
    and der.COMM=least(greatest(round(coalesce(pcn_com,0)*2)/2,0),20)
  left join DM_CIF_BASE dcb
  on dl.cli_id=dcb.id
  left join client_map cm
  on cm.client_src=dcb.id
    and cm.src='C'
  left join loan_request_CLNT lrc
  on lrc.agr_id=cm.agr_id
  left join loan_request lr
  on lrc.process_guid=lr.process_guid
    and trunc(dl.FROMDATE)-trunc(FINISH_DATE) between -1 and 31
  left join dict_branch_ekz dbe
  on lr.branch_id=dbe.branch_id
  where 1=1
      and dl.fromdate>='01.01.2013'
      and dl.STATE  in ('Актуален','Погашен','Выкуплен КИК-ом','Списан','Прощен','Списан долг','Списаны проценты')
  ;
  commit;
  save_debug_log('Fill_Payments_Schedulers.  6.');
  truncate_table('sal_tr');
  save_debug_log('Fill_Payments_Schedulers.  7.');
  insert /*+ parallel(8) append*/
  into sal_tr
  select cl.AGR_ID,
         cl.cli_id,
         t.POSTING_DATE,
         c.ACC_SCHEME_TYPE
  from TRANSACTION_3 t
  inner join ows_contract c
  on t.TARGET_NUMBER=c.CONTRACT_NUMBER
    and c.CON_CAT='A'
  inner join CLIENT cl
  on c.OWS_CLIENT_ID=cl.OWS_CLIENT_ID
  where trans_date >'01.10.2012'
      and t.OP_TYPE_name in ('Payment Salary',
                            'Payment To Client Contract')
   ;
 commit;
 save_debug_log('Fill_Payments_Schedulers.  8.');
 truncate_table('loan_buf_risk');
 save_debug_log('Fill_Payments_Schedulers.  9.');
 insert /*+ parallel(8) append*/
 into loan_buf_risk
 select dl.CONTRACT_ID,
         min(case when s.ACC_SCHEME_TYPE like '%STAFF%'
              then '1. Сотрудник'
              when dl2.contract_id is not null
              and dl2.todate>= dl.FROMDATE
              then '2. Действующий Заемщик'
              when dl2.contract_id is not null
              then '3. Бывший Заемщик'
              when s.ACC_SCHEME_TYPE is not null
              then '4. Зарплатник'
              else '5. Прочие'
              end) segm
  from DM_LOAN_BASE dl
  left join DM_LOAN_BASE dl2
  on dl.CLI_ID=dl2.CLI_ID
    and dl2.FROMDATE<dl.FROMDATE
    and dl2.STATE  in ('Актуален','Погашен','Выкуплен КИК-ом','Списан','Прощен','Списан долг','Списаны проценты')
  left join sal_tr s
  on dl.cli_id=s.cli_id
    and dl.fromdate between add_months(s.POSTING_DATE,-2) and s.POSTING_DATE
  where 1=1
      and dl.fromdate>='01.01.2013'
      and dl.STATE  in ('Актуален','Погашен','Выкуплен КИК-ом','Списан','Прощен','Списан долг','Списаны проценты')
  group by dl.CONTRACT_ID
  ;
  commit;
  save_debug_log('Fill_Payments_Schedulers.  10.');
  Truncate_Table('contr_list_risk');
  save_debug_log('Fill_Payments_Schedulers.  11.');
  insert /*+ parallel(8) append*/
  into contr_list_risk
  select dl.contract_id,
       dl.dep_id,
       dl.val_id,
       dl.VAL_CODE,
       da.PCN_COM,
       da.PCN_RATE,
       da.PRODUCT_NAME_ATF,
       da.TARGET_NAME_ATF,
       da.RESTRUCT_NAME_ATF,
       case when target_code_atf='14'
            or lower(product_name_atf) like '%ипотека%'
            then '1. Mortgage'
            when product_code_atf in ('4.4', '1.13', '1.14', '1.15', '1.16', '1.17')
            then '2. Auto'
            when product_code_atf in ('1.12', '4.3', '1.29', '1.30', '1.31', '1.32', '1.34', '1.35', '4.6', '1.40')
            then '3. Light'
            else '4. Consumer'
            end prod_type,
        dl.FROMDATE,
        dl.TODATE,
        dl.STATE,
        --dl.sum_full*decode(dl.val_id,21,182,421,250,1) sum_full,
        dl.sum_full*etl.Get_NBRK_Curr(trunc(sysdate),'',dl.val_id) sum_full,
       der.effective_rate,
       --dl.sum_full*decode(dl.val_id,21,182,421,250,1)*der.effective_rate wt_effective_rate,
       dl.sum_full*etl.Get_NBRK_Curr(trunc(sysdate),'',dl.val_id)*der.effective_rate wt_effective_rate,
       case when lower(dep.longname_hi) like '%филиал%'
          then dep.longname_hi
          when lower(dep.longname) like '%филиал%'
          then dep.longname
          end filial_name,
       dep.LONGNAME branch_name,
       max(case when acc_type_code='КФ01_О'
              then dlc.acc_id
              end) principal_acc_id,
       max(case when acc_type_code='КФ04_ОД'
              then dlc.acc_id
              end) ovd_principal_acc_id,
       max(case when acc_type_code='CR_WR_PD'
              then dlc.acc_id
              end) OW_principal_acc_id,
       case when dcb.vcc in ('107320',
                    '107329',
                    '107330',
                    '107340',
                    '107390',
                    '999992')
                  then '1.Retail'
             when dcb.vcc in ('107310',
                    '107319',
                    '999994')
                  then '2.Private'
             when dcb.vcc in ('104120',
                    '104810',
                    '104815',
                    '104819',
                    '999993')
                  then '3.SME'
              else '4. Corporate'
              end cl_type,
          lr.segm,
          nvl(lbe.salaryflag,0) salary_flag_ekz,
          nvl(lbe.isloyal,0) loyal_flag_ekz
from DM_LOAN_BASE dl
inner join dm_cif_base dcb
on dl.cli_id=dcb.id
inner join DM_LOAN_BASE_add da
on dl.contract_id=da.id
left join DM_LOAN_ACC dlc
on dl.CONTRACT_ID=dlc.CONTRACT_ID
left join loan_buf_risk lr
on dl.contract_id=lr.contract_id
left join (select contract_id,salaryflag,isloyal from loan_buf_ekz) lbe
on dl.contract_id=lbe.contract_id
left join DICT_EFFECTIVE_RATE der
on der.term=least(greatest(round(decode(term_type,null,months_between(todate,fromdate),term_cnt/decode(term_type,'M',1,'D',30.4167,'Y',1/12))),1),180)
  and der.rate=least(greatest(round(coalesce(dl.rate,pcn_rate,0)*2)/2,0),50)
  and der.COMM=least(greatest(round(coalesce(pcn_com,0)*2)/2,0),20)
left join
(select c.id,
       c.code,
       c.LONGNAME,
       c.id_hi,
       c2.code code_HI,
       c2.LONGNAME LONGNAME_HI
from c_dep c
inner join c_dep c2
on c.ID_HI=c2.id
WHERE 1=1
    ) dep
on dep.id=dl.dep_id
where 1=1
    and dl.fromdate>='01.01.2013'
    and dl.STATE  in ('Актуален','Погашен','Выкуплен КИК-ом','Списан','Прощен','Списан долг','Списаны проценты')
group by dl.contract_id,
       dl.dep_id,
       dl.val_id,
       dl.VAL_CODE,
       da.PCN_COM,
       da.PCN_RATE,
       da.PRODUCT_NAME_ATF,
       da.TARGET_NAME_ATF,
       da.RESTRUCT_NAME_ATF,
       case when target_code_atf='14'
            or lower(product_name_atf) like '%ипотека%'
            then '1. Mortgage'
            when product_code_atf in ('4.4', '1.13', '1.14', '1.15', '1.16', '1.17')
            then '2. Auto'
            when product_code_atf in ('1.12', '4.3', '1.29', '1.30', '1.31', '1.32', '1.34', '1.35', '4.6', '1.40')
            then '3. Light'
            else '4. Consumer'
            end ,
        dl.FROMDATE,
        dl.TODATE,
        dl.STATE,
        --dl.sum_full*decode(dl.val_id,21,182,421,250,1) ,
        dl.sum_full*etl.Get_NBRK_Curr(trunc(sysdate),'',dl.val_id) ,
       der.effective_rate,
       --dl.sum_full*decode(dl.val_id,21,182,421,250,1)*der.effective_rate ,
       dl.sum_full*etl.Get_NBRK_Curr(trunc(sysdate),'',dl.val_id)*der.effective_rate ,
       case when lower(dep.longname_hi) like '%филиал%'
          then dep.longname_hi
          when lower(dep.longname) like '%филиал%'
          then dep.longname
          end ,
       dep.LONGNAME,
       case when dcb.vcc in ('107320',
                    '107329',
                    '107330',
                    '107340',
                    '107390',
                    '999992')
                  then '1.Retail'
             when dcb.vcc in ('107310',
                    '107319',
                    '999994')
                  then '2.Private'
             when dcb.vcc in ('104120',
                    '104810',
                    '104815',
                    '104819',
                    '999993')
                  then '3.SME'
              else '4. Corporate'
              end,
          lr.segm,
          nvl(lbe.salaryflag,0),
          nvl(lbe.isloyal,0)
;
commit;
save_debug_log('Fill_Payments_Schedulers.  12.');
 Truncate_Table('risk_cube');
 save_debug_log('Fill_Payments_Schedulers.  13.');
 insert /*+ parallel(8) append*/
 into risk_cube
 select dl.*,
       trunc(dl.fromdate,'iw') fromweek,
       trunc(dl.fromdate,'mm') frommonth,
       d.LONGNAME payment_type,
       d.doper payment_date_plan,
       d.DCLOSE payment_date_fact,
       --d.AMOUNT_VAL*decode(dl.val_id,21,182,421,250,1) payment_amount_plan,
       d.AMOUNT_VAL* etl.Get_NBRK_Curr(trunc(sysdate),'',dl.val_id) payment_amount_plan,
       --d.AMOUNT_VAL*decode(dl.val_id,21,182,421,250,1)-d.paysdok*decode(dl.val_id,21,182,421,250,1) payment_amount_fact,
       d.AMOUNT_VAL* etl.Get_NBRK_Curr(trunc(sysdate),'',dl.val_id)-d.paysdok* etl.Get_NBRK_Curr(trunc(sysdate),'',dl.val_id) payment_amount_fact,
       ROW_NUMBER () OVER (PARTITION BY d.contract_id,d.LONGNAME ORDER BY d.doper) payment_number,
       case when trunc(sysdate)-1-d.doper>=1
          then 1
          else null
          end censored_01,
       case when trunc(sysdate)-1-d.doper>=7
          then 1
          else null
          end censored_07,
       case when trunc(sysdate)-1-d.doper>=14
          then 1
          else null
          end censored_14,
       case when trunc(sysdate)-1-d.doper>=21
          then 1
          else null
          end censored_21,
       case when trunc(sysdate)-1-d.doper>=30
          then 1
          else null
          end censored_30,
       case when trunc(sysdate)-1-d.doper>=60
          then 1
          else null
          end censored_60,
       case when trunc(sysdate)-1-d.doper>=90
          then 1
          else null
          end censored_90,
       (case when nvl(d.DCLOSE,trunc(sysdate)-1)-d.doper>=1
          then 1
          else 0
          end)*(case when trunc(sysdate)-1-d.doper>=1
          then 1
          else null
          end) default_01,
       (case when nvl(d.DCLOSE,trunc(sysdate)-1)-d.doper>=7
          then 1
          else 0
          end)*(case when trunc(sysdate)-1-d.doper>=7
          then 1
          else null
          end) default_07,
       (case when nvl(d.DCLOSE,trunc(sysdate)-1)-d.doper>=14
          then 1
          else 0
          end)*(case when trunc(sysdate)-1-d.doper>=14
          then 1
          else null
          end) default_14,
       (case when nvl(d.DCLOSE,trunc(sysdate)-1)-d.doper>=21
          then 1
          else 0
          end)*(case when trunc(sysdate)-1-d.doper>=21
          then 1
          else null
          end) default_21,
       (case when nvl(d.DCLOSE,trunc(sysdate)-1)-d.doper>=30
          then 1
          else 0
          end)*(case when trunc(sysdate)-1-d.doper>=30
          then 1
          else null
          end) default_30,
       (case when nvl(d.DCLOSE,trunc(sysdate)-1)-d.doper>=60
          then 1
          else 0
          end)*(case when trunc(sysdate)-1-d.doper>=60
          then 1
          else null
          end) default_60,
       (case when nvl(d.DCLOSE,trunc(sysdate)-1)-d.doper>=90
          then 1
          else 0
          end)*(case when trunc(sysdate)-1-d.doper>=90
          then 1
          else null
          end) default_90
from dm_loan_paym_3 d
inner join contr_list_risk dl
on d.contract_id=dl.contract_id
where 1=1
    and d.LONGNAME in ('Проценты по кредиту','Основной долг','Комиссия за  обслуживания банковского займа')
    and d.DOPER<trunc(sysdate)
    and d.AMOUNT_VAL>0
;
 commit;
 save_debug_log('Fill_Payments_Schedulers.  14.');
    Store_Etl_Tables(l_action,'dm_loan_paym_3');
    Store_Etl_Tables(l_action,'loan_buf_ekz');
    Store_Etl_Tables(l_action,'sal_tr');
    Store_Etl_Tables(l_action,'loan_buf_risk');
    Store_Etl_Tables(l_action,'contr_list_risk');
    Store_Etl_Tables(l_action,'risk_cube');
    save_debug_log('Fill_Payments_Schedulers.  15.');
 Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
Exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
END;
procedure threads_1_2---+
  is
 l_act_name constant etl_actions_log.action_name%type:=Upper('THREADS_1_2');
 l_action  etl_actions_log.id%type;
BEGIN
 if check_sysdate_state (l_act_name) is null then
  BEGIN
    save_debug_log('0 threads_1_2');
    gv_start:=dbms_utility.get_time;
    Store_Etl_Action(l_act_name,l_action);
    save_debug_log('1 colvir.ETL_DWH.run_thread_1@reps -begin');
    colvir.ETL_DWH.run_thread_1@reps;
    save_debug_log('2 colvir.ETL_DWH.run_thread_1@reps -end');
    save_debug_log('3 colvir.ETL_DWH.run_thread_2@reps -begin');
    colvir.ETL_DWH.run_thread_2@reps;
    save_debug_log('4 colvir.ETL_DWH.run_thread_2@reps -end');
 --  tmp_run_thread_2;
    Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
     exception
   when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
  END;
  end if;
END;
procedure threads_3_4---+
  is
 l_act_name constant etl_actions_log.action_name%type:=Upper('THREADS_3_4');
 l_action  etl_actions_log.id%type;
BEGIN
    if check_sysdate_state (l_act_name) is null then
  BEGIN
    gv_start:=dbms_utility.get_time;
    Store_Etl_Action(l_act_name,l_action);
    colvir.ETL_DWH.run_thread_3@reps;
    colvir.ETL_DWH.run_thread_4@reps;
  --  colvir.ETL_DWH.run_thread_8@reps;
    Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
     exception
   when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
  END;
  end if;
END;
procedure fill_CASHANDGOFORRB_TMP is
l_act_name constant etl_actions_log.action_name%type:=Upper('fill_CASHANDGOFORRB_TMP');
l_action  etl_actions_log.id%type;
begin
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      insert into CashAndGoForRB_tmp
      select t.*, sysdate as sdt from v_EKZ_CashAndGoForRB t;
      commit;
      Store_Etl_Tables(l_action,'CASHANDGOFORRB_TMP');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure fill_CASHANDGOFORRB is
  l_act_name constant etl_actions_log.action_name%type:=Upper('fill_CASHANDGOFORRB');
  l_action  etl_actions_log.id%type;
  CURSOR cur1 IS SELECT sdt from CashAndGoForRB_tmp group by sdt order by sdt;
  dt date;
begin
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      open cur1;
      loop
        fetch cur1 into dt;
        EXIT WHEN cur1%NOTFOUND;
        delete from CashAndGoForRB t
        where t.process_guid in (
          select t.process_guid from CashAndGoForRB_tmp t
          where t.sdt = dt
        );
        commit;
        insert into CashAndGoForRB  select t.* from CashAndGoForRB_tmp t where t.sdt = dt;
        commit;
      end loop;
      commit;
      close cur1;
      Truncate_Table('CashAndGoForRB_tmp');
      Store_Etl_Tables(l_action,'CASHANDGOFORRB');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure fill_EKZ_OpenWay is
  l_act_name constant etl_actions_log.action_name%type:=Upper('fill_EKZ_OpenWay');
  l_action  etl_actions_log.id%type;
  cnt ETL_TABLES_LOG.NUM_ROWS%type;
begin
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      insert into EKZ_OPENWAY_TMP
      select
         m."PROCESS_GUID"
        ,m."PROCESS_CODE"
        ,m."PROCESS_VERSION"
        ,m."START_DATE"
        ,m."FINISH_DATE"
        ,m."PROCESS_STATUS"
        ,m."SUBDIVISION"
        ,m."STEP_COUNTER"
        ,m."ISRUNNING"
        ,m."INITIATOR_CODE"
        ,m."PROCESS_NUM"
        ,m."AMOUNT"
        ,m."CURRENCY"
        ,m."CLIENT_NAME"
        ,m."REGNUMBER"
        ,m."BRANCHNAME"
        ,m."DEPNAME"
        ,m."PR_STATUS"
        ,m."OPERATIONNAME"
        ,m."TITLE"
        ,m."FULL_NAME"
        ,m."BRANCH_ID"
        ,m."DEP_ID"
        ,m."OPERATION_ID"
        ,m."CARDPRODUCT_ID"
        ,m."CARDPRODUCT_NAME"
        ,m."APPL_STATUS"
        ,m."APPL_DATE"
        ,m."FLDEL"
        ,m."PIN2_STATUS"
        ,m."is_owner"
        ,m."way4clientid"
        ,m."sub_type"
        ,m."DELIVERY_BRANCH"
        ,m."Delivery_dep"
        ,m."subtype"
        ,m."nsubtype"
        ,m."cur"
        ,m."limit"
        ,m."iin"
        ,m."RevType"
        ,m."CardNumber"
        ,m."ContractNumber"
        ,m."Institution"
        ,m."ParentRegNumber"
        ,m."ClientNumber"
        ,m."ShortName"
        ,m."RNN"
        ,m."way4_error"
        ,m."FILE_STATUS"
        ,m."IsPakageAddCard"
        ,m."IBAN"
        ,m."AddCardCount"
        ,m."Verifier_code"
        ,m."Verifier_name"
        ,m."Verifier_Result"
        ,m."Verifier_date"
        ,m."IS_REV_CARD"
        ,m."INITIATOR_POSITION"
        ,m."AppFileName"
        ,m."Persent"
        ,'MSSQL' as source
        ,sysdate as sdt
      from v_EKZ_OpenWay m
      where m."START_DATE" >=trunc(sysdate)-365 and (m."FINISH_DATE" is null or m."FINISH_DATE" >= trunc(sysdate)-7);
      commit;
      Store_Etl_Tables(l_action,'EKZ_OPENWAY_TMP');
      select t.num_rows into cnt from ETL_TABLES_LOG t
      where t.etl_log_id = l_action and t.table_name = 'EKZ_OPENWAY_TMP';
      if cnt > 0 then
        delete from EKZ_OPENWAY t
        where t.process_guid in (select process_guid from EKZ_OPENWAY_TMP);
        insert into EKZ_OPENWAY
        select * from  EKZ_OPENWAY_TMP;
        commit;
        Truncate_Table('EKZ_OPENWAY_TMP');
      end if;
      Store_Etl_Tables(l_action,'EKZ_OPENWAY');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure fill_IB_regclient_fl is
  l_act_name constant etl_actions_log.action_name%type:=Upper('fill_IB_regclient_fl');
  l_action  etl_actions_log.id%type;
  i number;
begin
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      Truncate_Table('IB_regclient_fl_tmp');
      insert into IB_regclient_fl_tmp
      --select t.*, sysdate as SDT from v_RegisteredClients@sdbo_db t;
      select * from sdbo_RegisteredClients;
      commit;
      Store_Etl_Tables(l_action,'IB_regclient_fl_tmp');
      select count(*) into i from IB_regclient_fl_tmp;
      if i>0 then
        Truncate_Table('IB_regclient_fl');
        insert into IB_regclient_fl
        select * from IB_regclient_fl_tmp t;
        commit;
      end if;
      Store_Etl_Tables(l_action,'IB_regclient_fl');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure Save_DWH_Current_Size
is
begin
  insert into DWH_Size_Stat
  select /*round(bytes/1024/1024,2)*/ t.bytes mb, t.segment_name,t.segment_type, sysdate as sdt from user_segments t --c 9.4.15 mb хранит bytes
  order by bytes desc;
  commit;
end;
procedure fill_EKZ_RET_GETSTEP is
  l_act_name constant etl_actions_log.action_name%type:=Upper('fill_EKZ_RET_GETSTEP');
  l_action  etl_actions_log.id%type;
begin
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      Truncate_Table('EKZ_Ret_getStepsLast7Days');
      insert into EKZ_Ret_getStepsLast7Days
      select a.* , sysdate as SDT from v_Retail_getStepsLast7Days a;
      commit;
      Store_Etl_Tables(l_action,'EKZ_Ret_getStepsLast7Days');
      delete EKZ_RET_GETSTEP t where t.process_guid in (select a.process_guid from EKZ_Ret_getStepsLast7Days a);
      commit;
      Store_Etl_Tables(l_action,'EKZ_RET_GETSTEP');
      insert into EKZ_RET_GETSTEP
      select * from EKZ_Ret_getStepsLast7Days t;
      commit;
      Store_Etl_Tables(l_action,'EKZ_RET_GETSTEP');
      --ImportToDWH_PRIM('EKZ_RET_GETSTEP');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure fill_ows_is_code_word is
  l_act_name constant etl_actions_log.action_name%type:=Upper('fill_ows_is_code_word');
  l_action  etl_actions_log.id%type;
begin
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      Truncate_Table('ows_client_is_code_word');
      insert into ows_client_is_code_word
      select id ows_client_id,
            case when mother_s_nam is null then 0
                 when mother_s_nam is not null then 1
            end as is_code_word
      from ows.CLIENT@rpt;
      commit;
      Store_Etl_Tables(l_action,'ows_client_is_code_word');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end fill_ows_is_code_word;
procedure fill_EKZ_PROCESS_RESULTS_TMP1 is
  v_line EKZ_PROCESS_RESULTS_TMP%ROWTYPE;
  CURSOR curs1 IS
    select t.*, sysdate as SDT from HBPROCSYSTEM.PROCESS_RESULTS@EKZ t
      where trunc(t.finish_date) >= trunc(sysdate - 5) or t.finish_date is null
      --where trunc(t.finish_date) >=  to_date('01.01.2012','dd.mm.yyyy')
      --and trunc(t.finish_date) <  to_date('01.01.2015','dd.mm.yyyy')
  ;
begin
  OPEN curs1;
  LOOP
      EXIT WHEN curs1%NOTFOUND;
      FETCH curs1 INTO v_line;
      BEGIN
        insert into EKZ_PROCESS_RESULTS_TMP values v_line;
        commit;
        exception
          when others then
             rollback;
             insert into EKZ_PROCESS_RESULTS_ERR (PROCESS_GUID,SDT) values (v_line.PROCESS_GUID, sysdate);
             commit;
      END;
  END LOOP;
  CLOSE curs1;
end;
procedure fill_EKZ_PROCESS_RESULTS_TMP is
 /*
   время работы:
   добавлено записей:
 */
l_act_name constant etl_actions_log.action_name%type:=Upper('fill_EKZ_PROCESS_RESULTS_TMP');
l_action  etl_actions_log.id%type;
begin
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      fill_EKZ_PROCESS_RESULTS_TMP1;
      Store_Etl_Tables(l_action,'EKZ_PROCESS_RESULTS_TMP');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure fill_EKZ_PROCESS_RESULTS is
 /*
   время работы:
   добавлено записей:
 */
  l_act_name constant etl_actions_log.action_name%type:=Upper('fill_EKZ_PROCESS_RESULTS');
  l_action  etl_actions_log.id%type;
  CURSOR cur1 IS SELECT sdt from EKZ_PROCESS_RESULTS_TMP group by sdt order by sdt;
  dt date;
begin
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      open cur1;
      loop
        fetch cur1 into dt;
        EXIT WHEN cur1%NOTFOUND;
        delete from EKZ_PROCESS_RESULTS t
        where t.process_guid in (
          select t.process_guid from EKZ_PROCESS_RESULTS_TMP t
          where t.sdt = dt
        )
        ;
        commit;
        insert into EKZ_PROCESS_RESULTS  select t.* from EKZ_PROCESS_RESULTS_TMP t where t.sdt = dt;
        commit;
      end loop;
      commit;
      close cur1;
      Truncate_Table('EKZ_PROCESS_RESULTS_TMP');
      Store_Etl_Tables(l_action,'EKZ_PROCESS_RESULTS');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
----------------------------------------------------------------------------------------------------------------------------
--конец обработка
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
--начало обработка раз в месяц
----------------------------------------------------------------------------------------------------------------------------
Procedure Fill_Bal_Regular --месячный агрегат по счетам на конец месяца +
  is
 l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_Bal_Regular');
 l_action  etl_actions_log.id%type;
 --str varchar(50);
begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  DBMS_UTILITY.EXEC_DDL_STATEMENT('alter table DM_ALL_BAL_AGG truncate partition P'||to_char(add_months(trunc(sysdate,'mm'),-1),'yyyymm'));
  colvir.ETL_DWH.Run_Thread_7@reps;
  execute immediate ('truncate table bal_loan_all');
  insert into bal_loan_all
  select /*+append*/
         a.*,
         LEAD(fromdate,1) over (partition by DEP_ID, ID, VAL_ID, FLZO,PLANFL order by fromdate) todate,
         lag(fromdate,1) over (partition by DEP_ID, ID, VAL_ID, FLZO,PLANFL order by fromdate) beforedate
  from colvir.etl_bal_loan_all@reps a;
  commit;
  execute immediate ('truncate table DM_ALL_BAL_AGG_BUF');
  insert /*+ append parallel(16) */ into DM_ALL_BAL_AGG_BUF
  select val_id,
         dep_id,
         id acc_id,
         planfl,
         flzo,
         add_months(trunc(sysdate,'mm'),-1) month_year,
         sum(case when todate is null
                      then BAL_OUT
                      else 0
                      end) BAL_OUT,
         sum(case when beforedate is null
                  and fromdate<>add_months(trunc(sysdate,'mm'),-1)
            then BAL_IN*(FROMDATE-add_months(trunc(sysdate,'mm'),-1))
            else BAL_OUT*(nvl(todate,add_months(add_months(trunc(sysdate,'mm'),-1),1))-FROMDATE)
            end)/max(add_months(trunc(FROMDATE,'mm'),1)-trunc(FROMDATE,'mm')) BAL_OUT_AVG,
         sum(case when todate is null
                      then NATVAL_OUT
                      else 0
                      end) NATVAL_OUT,
         sum(case when beforedate is null
                  and fromdate<>add_months(trunc(sysdate,'mm'),-1)
            then NATVAL_IN*(FROMDATE-add_months(trunc(sysdate,'mm'),-1))
            else NATVAL_OUT*(nvl(todate,add_months(add_months(trunc(sysdate,'mm'),-1),1))-FROMDATE)
            end)/max(add_months(trunc(FROMDATE,'mm'),1)-trunc(FROMDATE,'mm')) NATVAL_out_AVG
  from bal_loan_all
  group by val_id,
         dep_id,
         id,
         planfl,
         flzo,
         add_months(trunc(sysdate,'mm'),-1);
  commit;
  insert /*+ append parallel(16) */ into DM_ALL_BAL_AGG_BUF
  select val_id,
         dep_id,
         acc_id,
         planfl,
         flzo,
         add_months(a.month_year,1) month_year,
         bal_out,
         bal_out bal_out_avg,
         NATVAL_out,
         NATVAL_out NATVAL_out_avg
  from DM_ALL_BAL_AGG a
  where 1=1
      and month_year=add_months(add_months(trunc(sysdate,'mm'),-1),-1)
      and not exists (select 1 from DM_ALL_BAL_AGG_BUF b
                      where a.val_id=b.val_id and a.acc_id=b.acc_id
                            and a.dep_id=b.dep_id
                            and a.planfl=b.planfl
                            and a.FLZO=b.FLZO);
  commit;
  insert /*+ append parallel(16) */ into DM_ALL_BAL_AGG
  select *
  from DM_ALL_BAL_AGG_BUF;
  commit;
  --select 'P'||to_char(add_months(trunc(sysdate,'mm'),-1),'yyyymm') into str from dual;
  --dbms_utility.exec_ddl_statement('alter index PK_ALL_BAL_AGG rebuild partition '||str);
  Store_Etl_Tables(l_action,'bal_loan_all');
  Store_Etl_Tables(l_action,'DM_ALL_BAL_AGG_BUF');
  Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
Procedure Fill_DM_LOAN_BAL_AGG --месячный агрегат , остатки по кредитам +
  is
l_act_name constant etl_actions_log.action_name%type:=Upper('Fill_DM_LOAN_BAL_AGG');
l_action  etl_actions_log.id%type;
 --str varchar2(20 char);
begin
if check_sysdate_state (l_act_name) is null then
BEGIN
-----------
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  execute immediate ('truncate table bal_loan');
  insert into bal_loan
  select /*+append*/*
  from colvir.etl_bal_loan@reps;
  commit;
  DBMS_UTILITY.EXEC_DDL_STATEMENT('alter table DM_LOAN_BAL_AGG truncate partition P'||to_char(add_months(trunc(sysdate,'mm'),-1),'yyyymm') );
  execute immediate ('truncate table DM_LOAN_BAL_AGG_BUF');
  insert into DM_LOAN_BAL_AGG_BUF
  select distinct
         val_id,
         dep_id,
         id acc_id,
         planfl,
         flzo,
         add_months(trunc(sysdate,'mm'),-1) month_year,
         FIRST_VALUE(bal_out) over (partition by val_id,dep_id,id,planfl,flzo order by fromdate desc)  bal_out,
         FIRST_VALUE(NATVAL_out) over (partition by val_id,dep_id,id,planfl,flzo order by fromdate desc)  NATVAL_out
  from bal_loan
  where trunc(fromdate,'mm')=add_months(trunc(sysdate,'mm'),-1);
  commit;
  insert into DM_LOAN_BAL_AGG_BUF
  select val_id,
         dep_id,
         acc_id,
         planfl,
         flzo,
         add_months(a.month_year,1) month_year,
         bal_out,
         NATVAL_out
  from DM_LOAN_BAL_AGG a
  where 1=1
      and month_year=add_months(add_months(trunc(sysdate,'mm'),-1),-1)
      and not exists (select 1 from DM_LOAN_BAL_AGG_BUF b
                      where a.val_id=b.val_id and a.acc_id=b.acc_id
                            and a.dep_id=b.dep_id
                            and a.planfl=b.planfl
                            and a.FLZO=b.FLZO);
  commit;
  commit;
  insert into DM_LOAN_BAL_AGG
  select *
  from DM_LOAN_BAL_AGG_BUF;
  commit;
 -- select 'P'||to_char(add_months(trunc(sysdate,'mm'),-1),'yyyymm') into str from dual;
 -- dbms_utility.exec_ddl_statement('alter index PK_BAL_AVG rebuild partition '||str);
--------------
  Store_Etl_Tables(l_action,'bal_loan');
  Store_Etl_Tables(l_action,'DM_LOAN_BAL_AGG_BUF');
  Store_Etl_Tables(l_action,'DM_LOAN_BAL_AGG');
  Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
procedure Colvir_import is
  l_act_name constant etl_actions_log.action_name%type:=Upper('Colvir_import');
  l_action  etl_actions_log.id%type;
   TYPE CurTyp IS REF CURSOR;  -- define weak REF CURSOR type
   cur   CurTyp;  -- declare cursor variable
   v_max_id   NUMBER := 962192288; --962240908  962240908
   l col_Q_ROW%rowtype;
begin
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
        Truncate_Table('COL_ROW_NAME');
        insert into COL_ROW_NAME
        select
           t.id
          ,t.code
          ,t.name
          ,t.longname
        from colvir.QV_ENTGRPROW@reps T, colvir.Q_ROWDSC@reps RD, colvir.Q_ROWTYPE@reps RT
        where T.ENT_ID=/*:ENT_ID*/ 3122
        and T.ID_QV-30000000=RD.ID(+)
        and T.SHOWFL='1'
        and RT.ID(+)=RD.ROW_ID
        and T.ARCFL='0';
        commit;
        select max(id) into v_max_id from col_Q_ROW;
        --письмо от Artem Sadovski September 17, 2015 10:28 AM
        --ниже 4 строки - оптимальный код
        insert /*+ parallel(16) append*/
        into col_Q_ROW
        select * from colvir.Q_ROW@reps
        where id > v_max_id;
        commit;
        --код не оптимален
        /*OPEN cur FOR  -- open cursor variable
           'select * from colvir.Q_ROW@reps where id > :s' USING v_max_id;
        loop
           fetch cur into l ;
           EXIT WHEN cur%NOTFOUND;
           insert into col_Q_ROW values l;
        end loop;
        commit;
        close cur;  */
        -----------------------------------------
        /*insert into col_Q_ROW
        select * from colvir.Q_ROW@reps t
        where t.id > (select max(id) from col_Q_ROW);
        commit;*/
     /* Truncate_Table('col_TT_POINT');
      insert into col_TT_POINT  --13min
      select t.*, sysdate as upd_DT from colvir.TT_POINT@reps  t;
      commit;*/
      /*Truncate_Table('col_T_DEASHDPNT');
      insert into col_T_DEASHDPNT  --8min
      select t.*, sysdate as upd_DT from colvir.T_DEASHDPNT@reps  t;
      commit;*/
      /*Truncate_Table('col_T_ARLCLC');
      insert into col_T_ARLCLC  --1min
      select t.*, sysdate as upd_DT from colvir.T_ARLCLC@reps  t;
      commit;*/
      /*Truncate_Table('col_T_ARLDEA');
      insert into col_T_ARLDEA  --2min
      select t.*, sysdate as upd_DT from colvir.T_ARLDEA@reps  t;
      commit;*/
      /*Truncate_Table('col_T_ARLDSC');
      insert into col_T_ARLDSC  --1min
      select t.*, sysdate as upd_DT from colvir.T_ARLDSC@reps  t;
      commit;*/
      /*Truncate_Table('COL_T_DEAPAY');
      insert into COL_T_DEAPAY
      select t.*, sysdate as DT_UPD from colvir.T_DEAPAY@reps t
      ;
      commit;*/
      /*Truncate_Table('COL_T_DEA');
      insert into COL_T_DEA
      select t.* from colvir.T_DEA@reps  t;
      commit;*/
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
/*
procedure fill_clnt_analit_20141205 is
 \*
   время работы: 0:33:39
   добавлено записей: 1264709
 *\
l_act_name constant etl_actions_log.action_name%type:=Upper('fill_clnt_analit_20141205');
l_action  etl_actions_log.id%type;
begin
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      Truncate_Table('clnt_analit_20141205');
      insert into clnt_analit_20141205
      select \*+ parallel(4) *\
           cl.agr_id,
           cl.OWS_CLIENT_ID,
           min(case when tr.target_number is not null
              and (cl.is_empl=1
                or oc.acc_scheme_type='STAFF')
              then '01. Сотрудник'
            when l.todate >sysdate
              and l.state in ('Актуален','Выкуплен КИК-ом')
              then '02. Действующий Заемщик'
            when l.todate <=sysdate
              and l.state in ('Погашен')
              then '03. Бывший Заемщик'
            when tr.target_number is not null
              and not (cl.is_empl=1
                or oc.acc_scheme_type='STAFF')
              then '04. Зарплатник'
            when oc.acc_scheme_type='REVOLVER'
                and oc.contract_status='Account OK'
              then '05. Владелец Кредитной карты'
            when d.state in ('Актуален')
              then '06. Действующий Вкладчик'
            when d.state in ('Расторгунт досрочно','Выплачен')
              then '07. Бывший Вкладчик'
            when tr.target_number is null
              and oc.acc_scheme_type in ('STAFF','SALARY','SALARY KAZZINK')
              and contract_status='Card OK'
              then '08. Бывший Зарплатник'
            when tr.target_number is null
              and oc.acc_scheme_type not in ('STAFF','SALARY','SALARY KAZZINK')
              and plastic_type is not null
              and contract_status='Card OK'
              then '09. Владелец дебетовой карты'
            when acc.CLI_ID is not null
              then '10. Владелец текущего счета'
              else '11. Прочие'
              end) segm,
          min(case when tr.target_number is not null
              and (cl.is_empl=1
                or oc.acc_scheme_type='STAFF')
              then '1.Сотрудник'
              else '2.НЕ сотрудник'
              end) is_staff,
          min(case when l.todate > sysdate
              and l.state in ('Актуален','Выкуплен КИК-ом')
              and l.fromdate<add_months(sysdate,-6)
              then '1. >=6м'
            when l.todate > sysdate
              and l.state in ('Актуален','Выкуплен КИК-ом')
              and l.fromdate>=add_months(sysdate,-6)
              then '2. <6м'
              else '3. null'
              end) is_loan_active,
          min(case when l.todate <=sysdate
              and l.state in ('Погашен')
              and l.todate>add_months(sysdate,-24)
              then '1. <24м'
            when l.todate <=sysdate
              and l.state in ('Погашен')
              and l.todate<=add_months(sysdate,-24)
              then '2. >=24м'
              else '3. null'
              end) is_loan_closed,
          min(case when tr.target_number is not null
              and not (cl.is_empl=1
                or oc.acc_scheme_type='STAFF')
              then '1. Зарплатник'
              else '2. НЕ зарплатник'
              end) is_payroll,
          min(case when cc.acc_ok=1
              and cc.pl_ok=1
              and cc.debt>0
              and cc.lim>0
              then '1. Есть КК с задолженностью'
             when cc.acc_ok=1
              and cc.pl_ok=1
              and cc.debt=0
              and cc.lim>0
              then '2. Есть КК без задолженности'
             when cc.acc_ok=1
              and cc.pl_ok=0
              and cc.debt>0
              and cc.lim>0
              then '3. Есть счет КК с задолженностью,но нет пластика'
             when cc.acc_ok=1
              and cc.pl_ok=0
              and cc.debt=0
              and cc.lim>0
              then '4. Есть счет КК без задолженности и нет пластика'
             when cc.del<0
              then '5. Есть счет КК с просрочкой'
             when cc.acc_ok=0
              then '6. Была КК ранее'
             else '7. НЕ было КК'
             end) is_cc,
            min(case when d.state in ('Актуален')
              then '1. Действующий Вкладчик'
              when d.state in ('Расторгунт досрочно','Выплачен')
              then '2. Бывший Вкладчик'
              else '3. Нет и не было вкладов'
            end) is_dep,
            min(case when cp.phone_number is not null
                then '1. Есть мобильный телефон'
                else '2. Нет мобильного телефона'
                end) is_phone,
            min(case when adr2.cli_id is not null
                  or adr.cli_id is not null
                then '1. Есть адрес'
                else '2. Нет адреса'
                end) is_address,
            min(case when oc.sms_notify is not null
                then '1. Есть SMS-сервис'
                else '2. Нет SMS-сервиса'
                end) is_sms,
            min(case when oc.web_banking is not null
                then '1. Есть интернет-банк'
                else '2. Нет интернет-банка'
                end) is_web_banking,
            min(cl.sex) sex,
            min(case when months_between(sysdate,cl.birth_date)/12 between 21 and 62
                  and cl.sex='M'
                  or (months_between(sysdate,cl.birth_date)/12 between 21 and 62
                  and cl.sex='F')
                then '1. Проходит по возрасту для кредитования'
                else '2. Не проходит по возрасту для кредитования'
                end) age_ind,
            min(trunc(months_between(sysdate,cl.birth_date)/12)) age,
            max(case when lr.income is null
                then '1. Нет информации о доходе в ЭКЗ'
                when lr.income<20000
                then '2. 0 - 20 000'
                when lr.income<40000
                then '3. 20 000 - 40 000'
                when lr.income<100000
                then '4. 40 000 - 100 000'
                when lr.income<300000
                then '5. 100 000 - 300 000'
                when lr.income<600000
                then '6. 300 000 - 600 000'
                when lr.income<600000
                then '7. 600 000 - 1 000 000'
                when lr.income>1000000
                then '8. > 1 000 000'
                end) sal_ekz,
            min(case when del.cli_id is not null
                  or cc.del<0
                then '1. Есть текущая просрочка'
                else '2. Нет текущей просрочки'
                end) overdue_ind,
            min(case when br.longname_hi in ('Филиал  АО АТФБанк  в г.Алматы',
                        'Филиал АО АТФБанк  в г. Астана'
                        )
                  or br.longname in ('Филиал  АО АТФБанк  в г.Алматы',
                        'Филиал АО АТФБанк  в г. Астана'
                        )
                then '1. Алмата/Астана'
                when br.longname in ('АО АТФБАНК'
                        )
                then '3. ГБ'
                when br.longname_hi in ('Закрытые подразделения'
                        )
                then '4. Закрытые подразделения'
                else '2. Регионы'
                end) region_ind,
            min(case when oc.plastic_type in ('Chip Infinite Visa')
                  and oc.contract_status='Card OK'
                  and oc.acc_scheme_type<>'REVOLVER'
                  then '1. Infinite'
                 when oc.plastic_type in ('Chip Platinum Visa')
                  and oc.contract_status='Card OK'
                  and oc.acc_scheme_type<>'REVOLVER'
                  then '2. Platinum'
                 when oc.plastic_type in ('Chip Gold Visa',
                            'MC Gold',
                            'Gold Visa')
                  and oc.contract_status='Card OK'
                  and oc.acc_scheme_type<>'REVOLVER'
                  then '3. Gold'
                 when oc.plastic_type in ('Chip Classic Visa',
                            'MC Standart',
                            'Chip Revolver Visa',
                            'Commercial Revolver Visa')
                  and oc.contract_status='Card OK'
                  and oc.acc_scheme_type<>'REVOLVER'
                  then '4. Classic'
                 when oc.plastic_type in ('Cirrus/Maestro',
                            'Visa Instant',
                            'Electron Visa',
                            'Chip Electron Visa')
                  and oc.contract_status='Card OK'
                  and oc.acc_scheme_type<>'REVOLVER'
                  then '5. Electron'
                  end) dc_plastic_type,
            min(case when oc.plastic_type in ('Chip Infinite Visa')
                  and oc.contract_status='Card OK'
                  and oc.acc_scheme_type='REVOLVER'
                  then '1. Infinite'
                 when oc.plastic_type in ('Chip Platinum Visa')
                  and oc.contract_status='Card OK'
                  and oc.acc_scheme_type='REVOLVER'
                  then '2. Platinum'
                 when oc.plastic_type in ('Chip Gold Visa',
                            'MC Gold',
                            'Gold Visa')
                  and oc.contract_status='Card OK'
                  and oc.acc_scheme_type='REVOLVER'
                  then '3. Gold'
                 when oc.plastic_type in ('Chip Classic Visa',
                            'MC Standart',
                            'Chip Revolver Visa',
                            'Commercial Revolver Visa')
                  and oc.contract_status='Card OK'
                  and oc.acc_scheme_type='REVOLVER'
                  then '4. Classic'
                 when oc.plastic_type in ('Cirrus/Maestro',
                            'Visa Instant',
                            'Electron Visa',
                            'Chip Electron Visa')
                  and oc.contract_status='Card OK'
                  and oc.acc_scheme_type='REVOLVER'
                  then '5. Electron'
                  end) cc_plastic_type,
            min(case when oc.plastic_type in ('Business Visa',
                              'MC Business')
                  and oc.contract_status='Card OK'
                  then '1. Есть Business-card'
                  else '2. Нет Business-card'
                  end) is_business_card,
            min(case when oc.plastic_type in ('Virtuon Visa')
                  and oc.contract_status='Card OK'
                  then '1. Есть Virt-card'
                  else '2. Нет Virt-card'
                  end) is_Virt_card,
            min(case when cl.is_vip=1
                  then '1. VIP'
                  else '2. Mass'
                  end) is_vip
      from client cl
          INNER JOIN (select c.id,
                     c.code,
                     c.LONGNAME,
                     c.id_hi,
                     c2.code code_HI,
                     c2.LONGNAME LONGNAME_HI
                from c_dep c
                  inner join c_dep c2 on c.ID_HI=c2.id
                WHERE 1=1
                    --AND c2.LONGNAME NOT IN ('Закрытые подразделения','АО АТФБАНК')
                ) br on br.id=cl.dep_id
          LEFT join ows_contract oc on cl.OWS_CLIENT_ID=oc.OWS_CLIENT_ID
                         --and oc.con_cat='A'
          left join transaction_3 tr on oc.CONTRACT_NUMBER=tr.TARGET_NUMBER
                          and tr.trans_date>add_months(sysdate,-3)
                          and tr.dir='1'
                          and tr.op_type_name='Payment Salary'
          left join dm_loan_base l on cl.cli_id=l.cli_id
          left join dm_dep_base d on cl.cli_id=d.cli_id
          left join dm_acc_base acc on cl.CLI_ID=acc.CLI_ID
                         and acc.bal3='2204'
                         and acc.acc_state='Открыт'
          left join client_phones cp on cp.id_customer=cl.agr_id and cp.phone_type=3
          left join (select * from
                   (select cli_id,
                       cli_code,
                       decode(trim(r_index),'#',null,trim(r_index)) r_index ,
                       trim(decode(trim(r_city1_t),'#',null,trim(r_city1_t))||' '||decode(trim(r_city1),'#',null,trim(r_city1))) r_city,
                       decode(trim(r_mdistr_t),'#',null,trim(r_mdistr_t)) r_mdistr_t,
                       decode(trim(r_mdistr),'#',null,trim(r_mdistr)) r_mdistr,
                       decode(trim(r_street_t),'#',null,trim(r_street_t)) r_street_t,
                       decode(trim(r_street),'#',null,trim(r_street)) r_street,
                       decode(trim(r_house_t),'#',null,trim(r_house_t)) r_house_t,
                       decode(trim(r_house),'#',null,trim(r_house)) r_house,
                       decode(trim(r_apt_t),'#',null,trim(r_apt_t)) r_apt_t,
                       decode(trim(r_apt),'#',null,trim(r_apt)) r_apt
                  from dm_cif_addr)
                 where 1=1
                   and r_index is not null
                   and r_city is not null
                   and coalesce(r_street_t,r_mdistr_t) is not null
                   and r_house_t is not null
                 ) adr on cl.CLI_ID=adr.cli_id
          left join (select * from
                (select cli_id,
                     cli_code,
                     decode(trim(f_index),'#',null,trim(f_index)) f_index ,
                     trim(decode(trim(f_city1_t),'#',null,trim(f_city1_t))||' '||decode(trim(f_city1),'#',null,trim(f_city1))) f_city,
                     decode(trim(f_mdistr_t),'#',null,trim(f_mdistr_t)) f_mdistr_t,
                     decode(trim(f_mdistr),'#',null,trim(f_mdistr)) f_mdistr,
                     decode(trim(f_street_t),'#',null,trim(f_street_t)) f_street_t,
                     decode(trim(f_street),'#',null,trim(f_street)) f_street,
                     decode(trim(f_house_t),'#',null,trim(f_house_t)) f_house_t,
                     decode(trim(f_house),'#',null,trim(f_house)) f_house,
                     decode(trim(f_apt_t),'#',null,trim(f_apt_t)) f_apt_t,
                     decode(trim(f_apt),'#',null,trim(f_apt)) f_apt
                 from dm_cif_addr
                )
                 where 1=1
                  and f_index is not null
                  and f_city is not null
                  and coalesce(f_street_t,f_mdistr_t) is not null
                  and f_house_t is not null
                ) adr2 on cl.CLI_ID=adr2.cli_id
          left join (select  ows_client_id,
                     max(decode(contract_status,'Account OK',1,0)) acc_ok,
                     max(decode(contract_status,'Card OK',1,0)) pl_ok,
                     max(case when con_cat='A'and contract_status='Account OK'
                      then -auth_limit_amount
                      end) lim,
                     max(case when con_cat='A'and contract_status='Account OK'
                      then -total_balance
                      end) debt,
                     min(case when con_cat='A' and contract_status='Account OK'
                      then amount_available
                      end) del
                 from ows_contract oc
                 where oc.acc_scheme_type='REVOLVER'
                 group by ows_client_id
                ) cc on cl.ows_client_id=cc.ows_client_id
          left join loan_request_clnt lrc on cl.agr_id=lrc.agr_id
          left join loan_request lr on lrc.process_guid=lr.process_guid
          left join dm_delay_curr del on cl.cli_id=del.cli_id
      where 1=1
          and cl.is_ul=0
          and cl.is_ip=0
      group by cl.agr_id,cl.OWS_CLIENT_ID
      ;
      commit;
      Store_Etl_Tables(l_action,'clnt_analit_20141205');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure fill_clnt_analit_20141205_2 is
 \*
   время работы: 0:10:53
   добавлено записей: 1264709
 *\
l_act_name constant etl_actions_log.action_name%type:=Upper('fill_clnt_analit_20141205_2');
l_action  etl_actions_log.id%type;
begin
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      -- плановые коммуникации
      Truncate_Table('future_act_tmp_20141205');
      insert into future_act_tmp_20141205
        select decode(min(s.start_date), null,0,1) is_act, agr_id
        from offer o
           join sale_camp_sched_offers so on so.offer_id = o.offer_id
           join sale_camp_scheduler sc on so.id_sale_camp_shed=sc.id and so.id_sale_campaign=sc.id_sale_campaign
           join sale_pool_scheduler s on sc.id_sale_campaign=s.id_sale_campaign and sc.id=s.id_camp_sched and s.state = 'CREATED'
        where o.is_active = 1 and o.offer_status_code in (301,302)
        group by agr_id;
      commit;
      Truncate_Table('clnt_analit_20141205_2');
      insert into clnt_analit_20141205_2
        SELECT  \*+ parallel(8) *\
          c.AGR_ID,
          c.OWS_CLIENT_ID,
          c.SEGM,
          c.IS_STAFF,
          c.IS_LOAN_ACTIVE,
          c.IS_LOAN_CLOSED,
          c.IS_PAYROLL,
          c.IS_CC,
          c.IS_DEP,
          c.IS_PHONE,
          c.IS_ADDRESS,
          c.IS_SMS,
          c.IS_WEB_BANKING,
          c.SEX,
          c.AGE_IND,
          c.AGE,
          c.SAL_EKZ,
          c.OVERDUE_IND,
          c.REGION_IND,
          c.DC_PLASTIC_TYPE,
          c.CC_PLASTIC_TYPE,
          c.IS_BUSINESS_CARD,
          c.IS_VIRT_CARD,
          c.is_vip,
          sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM','Retail')
                    then trans.trans_amount
                    end)/3 avg_trans_amnt,
          sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM')
                    then trans.trans_amount
                    end)/3 avg_trans_amnt_ATM,
          sum(case when trans.dir='-1'
                        and trans.op_type_name in ('Retail')
                    then trans.trans_amount
                    end)/3 avg_trans_amnt_RETAIL,
          case when sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM','Retail')
                    then trans.trans_amount
                    end)>0
                    and sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM')
                    then trans.trans_amount
                    end)/decode(sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM','Retail')
                    then trans.trans_amount
                    end),0,1,sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM','Retail')
                    then trans.trans_amount
                    end)) <.25
                    then '1. Доля ATM < 25%'
                when sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM','Retail')
                    then trans.trans_amount
                    end)>0
                    and sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM')
                    then trans.trans_amount
                    end)/decode(sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM','Retail')
                    then trans.trans_amount
                    end),0,1,sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM','Retail')
                    then trans.trans_amount
                    end)) <.5
                    then '2. Доля ATM < 50%'
                when sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM','Retail')
                    then trans.trans_amount
                    end)>0
                    and sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM')
                    then trans.trans_amount
                    end)/decode(sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM','Retail')
                    then trans.trans_amount
                    end),0,1,sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM','Retail')
                    then trans.trans_amount
                    end)) <.75
                    then '3. Доля ATM < 75%'
                when sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM','Retail')
                    then trans.trans_amount
                    end)>0
                    and sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM')
                    then trans.trans_amount
                    end)/decode(sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM','Retail')
                    then trans.trans_amount
                    end),0,1,sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM','Retail')
                    then trans.trans_amount
                    end)) >=.75
                    then '4. Доля ATM >= 75%'
                    else '5. Нет расходных операций по пластику'
                    end trans_pattern,
          case when sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM','Retail')
                    then trans.trans_amount
                    end)/3 between 0.000001 and 20000
                  then '1. 1 - 20 000'
                  when sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM','Retail')
                    then trans.trans_amount
                    end)/3 < 40000
                  then '2. 20 000 - 40 000'
                  when sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM','Retail')
                    then trans.trans_amount
                    end)/3 < 100000
                  then '3. 40 000 - 100 000'
                  when sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM','Retail')
                    then trans.trans_amount
                    end)/3 < 300000
                  then '4. 100 000 - 300 000'
                  when sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM','Retail')
                    then trans.trans_amount
                    end)/3 < 600000
                  then '5. 300 000 - 600 000'
                  when sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM','Retail')
                    then trans.trans_amount
                    end)/3 < 1000000
                  then '6. 600 000 - 1 000 000'
                  when sum(case when trans.dir='-1'
                        and trans.op_type_name in ('ATM','Retail')
                    then trans.trans_amount
                    end)/3 >= 1000000
                  then '7. > 1 000 000'
                    else '8. Нет расходных операций по пластику'
                  end spend_amnt,
          case when sum(case when trans.dir='1'
                                  and trans.op_type_name='Payment Salary'
                    then trans.trans_amount
                    end)/3 between 0.000001 and 20000
                  then '1. 1 - 20 000'
                  when sum(case when trans.dir='1'
                                  and trans.op_type_name='Payment Salary'
                    then trans.trans_amount
                    end)/3 < 40000
                  then '2. 20 000 - 40 000'
                  when sum(case when trans.dir='1'
                                  and trans.op_type_name='Payment Salary'
                    then trans.trans_amount
                    end)/3 < 100000
                  then '3. 40 000 - 100 000'
                  when sum(case when trans.dir='1'
                                  and trans.op_type_name='Payment Salary'
                    then trans.trans_amount
                    end)/3 < 300000
                  then '4. 100 000 - 300 000'
                  when sum(case when trans.dir='1'
                                  and trans.op_type_name='Payment Salary'
                    then trans.trans_amount
                    end)/3 < 600000
                  then '5. 300 000 - 600 000'
                  when sum(case when trans.dir='1'
                                  and trans.op_type_name='Payment Salary'
                    then trans.trans_amount
                    end)/3 < 1000000
                  then '6. 600 000 - 1 000 000'
                  when sum(case when trans.dir='1'
                                  and trans.op_type_name='Payment Salary'
                    then trans.trans_amount
                    end)/3 >= 1000000
                  then '7. > 1 000 000'
                    else '8. Нет зарплатных поступлений'
                  end sal_w4,
          max(case when dep.bal_out_ekv is null
                                or dep.bal_out_ekv=0
                          then '1. Нет остатка/нулевой остаток на депозитах'
                          when dep.bal_out_ekv >0
                                and dep.bal_out_ekv<20000
                          then '2. 0 - 20 000'
                          when dep.bal_out_ekv<100000
                          then '3. 20 000 - 100 000'
                          when dep.bal_out_ekv<500000
                          then '4. 100 000 - 500 000'
                          when dep.bal_out_ekv<2500000
                          then '5. 500 000 - 2 500 000'
                          when dep.bal_out_ekv<15000000
                          then '6. 2 500 000 - 15 000 000'
                          when dep.bal_out_ekv>15000000
                          then '7. > 15 000 000'
                          end) dep_bal,
          max(case when acc.bal_out_ekv is null
                                or acc.bal_out_ekv=0
                          then '1. Нет остатка/нулевой остаток на текущих счетах'
                          when acc.bal_out_ekv >0
                                and acc.bal_out_ekv<20000
                          then '2. 0 - 20 000'
                          when acc.bal_out_ekv<100000
                          then '3. 20 000 - 100 000'
                          when acc.bal_out_ekv<500000
                          then '4. 100 000 - 500 000'
                          when acc.bal_out_ekv<2500000
                          then '5. 500 000 - 2 500 000'
                          when acc.bal_out_ekv<15000000
                          then '6. 2 500 000 - 15 000 000'
                          when acc.bal_out_ekv>15000000
                          then '7. > 15 000 000'
                          end) acc_bal,
             null as last_action_period,
             null as have_planned_action,
             null as last_offer_status,
             null as have_ibank,
             case when vso.OFFER_TYPE = 'LOAN' then 1 else 0 end as IS_ACT_LOAN,
              nvl(vso.CAMPAIGN_CODE,'') as CAMPAIGN_CODE_LOAN
             ,case when vso.CHANGE_DATE is null and ofr.offer_status_change_dttm is null then '0'
                 else
                    case
                     when round(sysdate - greatest(nvl(vso.CHANGE_DATE,sysdate-1000),nvl(ofr.offer_status_change_dttm,sysdate-1000)))<=15 then '15'
                     when round(sysdate - greatest(nvl(vso.CHANGE_DATE,sysdate-1000),nvl(ofr.offer_status_change_dttm,sysdate-1000)))<=30 then '30'
                       else '>30'
                      end
                   end dt_last_contact,
              ac.action_name,
              case when ofr.offer_type = 'deposit' then 1 else 0 end as IS_ACT_DEPO,
              nvl(ofr.CAMPAIGN_CODE,'')  as CAMPAIGN_CODE_DEPO,
              nvl(mvcr.CAMPAIGN_CODE,'')  as CAMPAIGN_CODE
        from clnt_analit_20141205 c
          left join MV_COMMUNICATION_RESPONSE mvcr on mvcr.agr_id = c.agr_id
          left join OWS_CONTRACT oc on c.OWS_CLIENT_ID=oc.OWS_CLIENT_ID
          left join transaction_3 trans on oc.CONTRACT_NUMBER=trans.TARGET_NUMBER and trans.trans_date>add_months(sysdate,-3)
          left join ( select cl.agr_id, -sum(bal_out) bal_out_ekv from dm_dep_base d
                   inner join client cl on d.cli_id=cl.cli_id left join dm_bal_snap sd on d.acc_id=sd.acc_id --and d.acc_dep_id=sd.dep_id
                group by cl.agr_id
                ) dep on c.agr_id=dep.agr_id
          left join ( select cl.agr_id, -sum(bal_out) bal_out_ekv from dm_acc_base acc
                  inner join client cl on acc.cli_id=cl.cli_id and acc.bal3='2204' and acc.acc_state='Открыт'
                  left join dm_bal_snap sd on acc.acc_id=sd.acc_id and acc.dep_id=sd.dep_id
                group by cl.agr_id
                ) acc on c.agr_id=acc.agr_id
         left join v_subj_offer vso on vso.agr_id = c.AGR_ID and vso.ISACTUAL = 1
         left join offer ofr on ofr.agr_id = c.agr_id and ofr.offer_type = 'deposit' and ofr.is_active = 1
         left join (select agr_id,max(contact_id) contact_id
                    from contact
                    group by agr_id) tmp1 on tmp1.agr_id = c.agr_id
         left join sale_camp_sched_action_offers ac on ac.contact_id = tmp1.contact_id
        --where c.agr_id=446631
        group by
          c.AGR_ID,
          c.OWS_CLIENT_ID,
          c.SEGM,
          c.IS_STAFF,
          c.IS_LOAN_ACTIVE,
          c.IS_LOAN_CLOSED,
          c.IS_PAYROLL,
          c.IS_CC,
          c.IS_DEP,
          c.IS_PHONE,
          c.IS_ADDRESS,
          c.IS_SMS,
          c.IS_WEB_BANKING,
          c.SEX,
          c.AGE_IND,
          c.AGE,
          c.SAL_EKZ,
          c.OVERDUE_IND,
          c.REGION_IND,
          c.DC_PLASTIC_TYPE,
          c.CC_PLASTIC_TYPE,
          c.IS_BUSINESS_CARD,
          c.IS_VIRT_CARD,
          c.is_vip,
          vso.OFFER_TYPE ,
          vso.CAMPAIGN_CODE,
          vso.CHANGE_DATE ,
          ofr.offer_status_change_dttm,
          ac.action_name,
          ofr.offer_type,
          ofr.CAMPAIGN_CODE,
          mvcr.CAMPAIGN_CODE
        ;
      commit;
      update CLNT_ANALIT_20141205_2 ca
        set last_action_period =
            ( select
                   case when sysdate - nvl(max(co.contact_creation_dttm), sysdate + 200) < -100 then - 1
             else case when sysdate - nvl(max(co.contact_creation_dttm), sysdate + 200) > 30 then 30
             else case when sysdate - nvl(max(co.contact_creation_dttm), sysdate + 200) > 15 then 15 else 0
                   end end end
              from contact co
              where co.agr_id = ca.agr_id
          );
      merge into CLNT_ANALIT_20141205_2 ca
         using (select * from future_act_tmp_20141205 o) a on (ca.agr_id=a.agr_id)
         when matched then update set
           ca.have_planned_action=1;
      merge into CLNT_ANALIT_20141205_2 ca
          using (select o.agr_id, o.offer_id, o.offer_status_code, dos.offer_status_name
               from offer o
                    join (select agr_id, max(offer_id) offer_id  from offer group by agr_id ) oo on o.offer_id=oo.offer_id
                    join dict_offer_status dos on dos.offer_status_code=o.offer_status_code
                ) a on (ca.agr_id=a.agr_id)
          when matched then update set
            ca.last_offer_status=a.offer_status_name;
      merge into CLNT_ANALIT_20141205_2 ca
          using (select distinct (agr_id) agr_id from ibank_client) a on (ca.agr_id=a.agr_id)
          when matched then update set
            ca.have_ibank='1. yes';
      update CLNT_ANALIT_20141205_2 set have_ibank='2. no' where have_ibank is null;
      commit;
      Store_Etl_Tables(l_action,'future_act_tmp_20141205');
      Store_Etl_Tables(l_action,'clnt_analit_20141205_2');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
*/
procedure MV_CLNT_ANALIT_AGG_Refresh---+
 /*
   время работы: 0:01:04
   добавлено записей: 255156
 */
is
  l_act_name constant etl_actions_log.action_name%type:=Upper('MV_CLNT_ANALIT_AGG_Refresh');
  l_action  etl_actions_log.id%type;
begin
if check_sysdate_state (l_act_name) is null then
BEGIN
  gv_start:=dbms_utility.get_time;
  Store_Etl_Action(l_act_name,l_action);
  DBMS_MVIEW.REFRESH(LIST => 'MV_CLNT_ANALIT_AGG20141205', METHOD => 'C');
  Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
  commit;
exception
  when others then
    rollback;
    gv_err_count:=gv_err_count+1;
    Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
    ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
    );
END;
end if;
end;
/*procedure loan_sched is
  l_act_name constant etl_actions_log.action_name%type:=Upper('loan_sched');
  l_action  etl_actions_log.id%type;
begin
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      Truncate_Table('LOAN_SCHED_1');
      insert into LOAN_SCHED_1
      select
        s.ORD_ID as contract_id,
        s.ID,
        d.LONGNAME,
        s.DOPER,
        s.AMOUNT,
        s.SHDTYPE,
        --s.AMOUNT/POWER(10,T_PkgVal.fGetFac(ad.VAL_ID)) as AMOUNT,
        s.PRC,
        --substr(bs_dom.DCCode('T_DEASHDPNT_SHDTYP',s.SHDTYPE),1,30) as SHDTYPE,
        --substr(T_PkgArlClc.fPntStat(s.TT_ID, s.TT_NORD, c.ARL_ID),1,250) as STAT,
        s.DCLCFROM,
        s.DCLCTO,
        p.CALCDATE,
        ad.VAL_ID,
        s.TT_ID, s.TT_NORD, c.ARL_ID
      from col_TT_POINT p, col_T_DEASHDPNT s,  col_T_ARLCLC c, col_T_ARLDEA ad, col_T_ARLDSC d
      where s.CLC_ID = c.ID and c.ARL_ID = d.ID
        and ad.DEP_ID = s.DEP_ID and ad.ORD_ID = s.ORD_ID and ad.CLC_ID = c.ID
        and p.ID=s.TT_ID and p.NORD=s.TT_NORD
      ;
      commit;
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;*/
----------------------------------------------------------------------------------------------------------------------------
--конец обработка раз в месяц
----------------------------------------------------------------------------------------------------------------------------
function Get_NBRK_Curr(p_date in date, p_curr_code in varchar2, p_val_id in number ) return number
  is
  v_rate number;
begin
  if p_val_id <> 0 then begin
      if p_val_id = 1 then
        v_rate := 1;
      else begin
        select c.rate into v_rate from
          (select * from NBRK_CURRENCY_RATE t
           where t.dt<=p_date and (t.alph_code = upper(p_curr_code) or t.val_id = p_val_id)
           order by t.dt desc) c
        where rownum < 2;
      end;
      end if;
  end;
  else
  begin
      if upper(p_curr_code) in ('KZT','398','') then
        v_rate := 1;
      else begin
        select c.rate into v_rate from
          (select * from NBRK_CURRENCY_RATE t
           where t.dt<=p_date and (t.alph_code = upper(p_curr_code) or t.num_code = upper(p_curr_code))
           order by t.dt desc) c
        where rownum < 2;
      end;
      end if;
  end;
  end if;
  return v_rate;
end;
procedure FILL_NBRK_CURRENCY_RATE is
  l_act_name constant etl_actions_log.action_name%type:=Upper('FILL_NBRK_CURRENCY_RATE');
  l_action  etl_actions_log.id%type;
begin
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      insert into NBRK_CURRENCY_RATE
      select
          t.Fromdate as DT
          ,t.Rate  as rate
          ,a.CODE as alph_code
          ,a.ALTERCODE as num_code
          ,t.val_id
      from colvir.T_VALRAT@reps t
      left join colvir.T_VAL@reps a on a.ID = t.val_id
      where t.Fromdate > (select max(dt) from NBRK_CURRENCY_RATE);
      commit;
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure FILL_W4_OPT_ACNT_BALANCE is
  l_act_name constant etl_actions_log.action_name%type:=Upper('FILL_W4_OPT_ACNT_BALANCE');
  l_action  etl_actions_log.id%type;
  v_dt  date;
  v_start_dt date;
  i number;
begin
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      save_debug_log('FILL_W4_OPT_ACNT_BALANCE.  1.');
      select max(AMND_DATE) into v_dt from ows.OPT_ACNT_BALANCE@rpt where AMND_DATE <= sysdate;
      save_debug_log('FILL_W4_OPT_ACNT_BALANCE.  2.');
      select max(AMND_DATE)+1 into v_start_dt from W4_OPT_ACNT_BALANCE where AMND_DATE <= sysdate;
      save_debug_log('FILL_W4_OPT_ACNT_BALANCE.  3.');
      execute immediate ('truncate table W4_OPT_ACNT_BALANCE_TMP');
      save_debug_log('FILL_W4_OPT_ACNT_BALANCE.  4.');
      i:=0;
      loop
        insert  /*+ append*/
        into W4_OPT_ACNT_BALANCE_TMP
        select
         *
        from ows.OPT_ACNT_BALANCE@rpt
        where AMND_DATE = v_start_dt + i;
        commit;
        exit when v_dt < v_start_dt + i;
        i:=i+1;
      end loop;
      save_debug_log('FILL_W4_OPT_ACNT_BALANCE.  5.');
      insert /*+ parallel(8) append*/
      into W4_OPT_ACNT_BALANCE
      select * from W4_OPT_ACNT_BALANCE_TMP;
      commit;
      save_debug_log('FILL_W4_OPT_ACNT_BALANCE.  6.');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure FILL_GSVP is
  l_act_name constant etl_actions_log.action_name%type:=Upper('FILL_GSVP');
  l_action  etl_actions_log.id%type;
begin
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      delete from  EKZ_GSVP
      where querydate >= trunc(sysdate)-7;
      commit;
      insert into EKZ_GSVP
      select * from LAMS.Gsvp@EKZ t
      where t.querydate >= trunc(sysdate)-7;
      commit;
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure FILL_T_BAL is
  TYPE   CurTyp IS REF CURSOR;  
  cur   CurTyp;  

  type t_COL_T_BAL_tab is table of COL_T_BAL%rowtype;
  l_data t_COL_T_BAL_tab;

  l_act_name constant etl_actions_log.action_name%type:=Upper('FILL_T_BAL');
  l_action  etl_actions_log.id%type;
  v_start_dt date;
  v_end_dt date;
  i number;
  cnt number;
  num_rows number;
begin
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      i:=0;
      v_start_dt:=trunc(sysdate)-40;
      v_end_dt:=trunc(sysdate)-1;
      loop
         select count(1) into cnt from COL_T_BAL t where t.FROMDATE = v_start_dt+i and rownum = 1;
         if cnt <=0 then
           /*insert \*+ append *\  --ужасно медлено 6477сек
           into COL_T_BAL
           select * from colvir.T_BAL@reps t where t.FROMDATE = v_start_dt+i;
           commit;*/
           save_debug_log('FILL_T_BAL. 1');
           OPEN cur FOR   --отрабатывает за 79сек посл.раз за 6389сек
              'select /*+ parallel(16) */
                   t.val_id    
                  ,t.dep_id    
                  ,t.id        
                  ,t.flzo      
                  ,t.planfl    
                  ,t.fromdate  
                  ,t.bal_in    
                  ,t.bal_out   
                  ,t.specfl    
                  ,t.natval_in 
                  ,t.natval_out
               from colvir.T_BAL@reps t where t.FROMDATE = :s' USING v_start_dt+i;
             --open cur;
             save_debug_log('FILL_T_BAL. 2.');
             execute immediate ('truncate table COL_T_BAL_TMP');
             loop  
               fetch cur bulk collect into l_data limit 5000000;
               exit when l_data.count=0;
               forall i in indices of l_data
               insert /*+ append */ 
               into COL_T_BAL_TMP (
                    val_id    
                   ,dep_id    
                   ,id        
                   ,flzo      
                   ,planfl    
                   ,fromdate  
                   ,bal_in    
                   ,bal_out   
                   ,specfl    
                   ,natval_in 
                   ,natval_out
               ) values (
                  l_data(i).val_id     
                 ,l_data(i).dep_id     
                 ,l_data(i).id         
                 ,l_data(i).flzo       
                 ,l_data(i).planfl     
                 ,l_data(i).fromdate   
                 ,l_data(i).bal_in     
                 ,l_data(i).bal_out    
                 ,l_data(i).specfl     
                 ,l_data(i).natval_in  
                 ,l_data(i).natval_out 
               );
             end loop;
           commit;
           close cur;
           save_debug_log('FILL_T_BAL. 3.');
           Store_Etl_Tables(l_action,'COL_T_BAL_TMP');
           save_debug_log('FILL_T_BAL. 4.');
           insert /*+ parallel(16) append */
           into COL_T_BAL
           select * from COL_T_BAL_TMP t;
           num_rows:= nvl(SQL%ROWCOUNT,0);
           commit;
           save_debug_log('FILL_T_BAL. 5. num_rows= '||num_rows);
         end if;
         exit when v_end_dt<= v_start_dt+i;
         i:=i+1;
      end loop;
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure imp2prim_dm_cif_addr is
  l_act_name constant etl_actions_log.action_name%type:=Upper('imp2prim_dm_cif_addr');
  l_action  etl_actions_log.id%type;
  cnt_rec integer;
begin
  select count(*) into cnt_rec from Etl_Actions_Log t
  where trunc(t.updated)=trunc(sysdate)and t.action_name = upper('Fill_Addr')and t.state = 'COMPLETED';
  if check_sysdate_state (l_act_name) is null and cnt_rec>0 then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      ImportToDWH_PRIM('dm_cif_addr');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure imp2prim_DM_DELAY_CURR is
  l_act_name constant etl_actions_log.action_name%type:=Upper('imp2prim_DM_DELAY_CURR');
  l_action  etl_actions_log.id%type;
  cnt_rec integer;
begin
  select count(*) into cnt_rec from Etl_Actions_Log t
  where trunc(t.updated)=trunc(sysdate)and t.action_name = upper('Fill_DM_DELAY_CURR')and t.state = 'COMPLETED';
  if check_sysdate_state (l_act_name) is null and cnt_rec>0 then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      ImportToDWH_PRIM('DM_DELAY_CURR');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure imp2prim_ows_contract is
  l_act_name constant etl_actions_log.action_name%type:=Upper('imp2prim_ows_contract');
  l_action  etl_actions_log.id%type;
  cnt_rec integer;
begin
  select count(*) into cnt_rec from Etl_Actions_Log t
  where trunc(t.updated)=trunc(sysdate)and t.action_name = upper('Fill_W4_Contract')and t.state = 'COMPLETED';
  if check_sysdate_state (l_act_name) is null and cnt_rec>0 then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      ImportToDWH_PRIM('ows_contract');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure imp2prim_DICT_PHONE_TYPES is
  l_act_name constant etl_actions_log.action_name%type:=Upper('imp2prim_DICT_PHONE_TYPES');
  l_action  etl_actions_log.id%type;
begin
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      ImportToDWH_PRIM('DICT_PHONE_TYPES');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure imp2prim_CLIENT_PHONES is
  l_act_name constant etl_actions_log.action_name%type:=Upper('imp2prim_CLIENT_PHONES');
  l_action  etl_actions_log.id%type;
begin
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      ImportToDWH_PRIM('CLIENT_PHONES');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure imp2prim_DM_ACC_BASE is
  l_act_name constant etl_actions_log.action_name%type:=Upper('imp2prim_DM_ACC_BASE');
  l_action  etl_actions_log.id%type;
  cnt_rec integer;
begin
  select count(*) into cnt_rec from Etl_Actions_Log t
  where trunc(t.updated)=trunc(sysdate)and t.action_name = upper('Fill_dm_acc_base')and t.state = 'COMPLETED';
  if check_sysdate_state (l_act_name) is null and cnt_rec>0 then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      ImportToDWH_PRIM('DM_ACC_BASE');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure imp2prim_dm_dep_base is
  l_act_name constant etl_actions_log.action_name%type:=Upper('imp2prim_dm_dep_base');
  l_action  etl_actions_log.id%type;
  cnt_rec integer;
begin
  select count(*) into cnt_rec from Etl_Actions_Log t
  where trunc(t.updated)=trunc(sysdate)and t.action_name = upper('Fill_dm_dep_base')and t.state = 'COMPLETED';
  if check_sysdate_state (l_act_name) is null and cnt_rec>0 then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      ImportToDWH_PRIM('dm_dep_base');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure imp2prim_dm_loan_base is
  l_act_name constant etl_actions_log.action_name%type:=Upper('imp2prim_dm_loan_base');
  l_action  etl_actions_log.id%type;
  cnt_rec integer;
begin
  select count(*) into cnt_rec from Etl_Actions_Log t
  where trunc(t.updated)=trunc(sysdate)and t.action_name = upper('Fill_DM_LOAN_BASE')and t.state = 'COMPLETED';
  if check_sysdate_state (l_act_name) is null and cnt_rec>0 then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      ImportToDWH_PRIM('dm_loan_base');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure imp2prim_transaction_3 is
  l_act_name constant etl_actions_log.action_name%type:=Upper('imp2prim_transaction_3');
  l_action  etl_actions_log.id%type;
  cnt_rec integer;
begin
  select count(*) into cnt_rec from Etl_Actions_Log t
  where trunc(t.updated)=trunc(sysdate)and t.action_name = upper('Fill_Trans_new')and t.state = 'COMPLETED';
  if check_sysdate_state (l_act_name) is null and cnt_rec>0 then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      ImportToDWH_PRIM('transaction_3');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure imp2prim_c_dep is
  l_act_name constant etl_actions_log.action_name%type:=Upper('imp2prim_c_dep');
  l_action  etl_actions_log.id%type;
  cnt_rec integer;
begin
  select count(*) into cnt_rec from Etl_Actions_Log t
  where trunc(t.updated)=trunc(sysdate)and t.action_name = upper('Fill_Dep')and t.state = 'COMPLETED';
  if check_sysdate_state (l_act_name) is null and cnt_rec>0 then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      ImportToDWH_PRIM('c_dep');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure imp2prim_client is
  l_act_name constant etl_actions_log.action_name%type:=Upper('imp2prim_client');
  l_action  etl_actions_log.id%type;
begin
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      ImportToDWH_PRIM('client');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure imp2prim_dm_bal_snap is
  l_act_name constant etl_actions_log.action_name%type:=Upper('imp2prim_dm_bal_snap');
  l_action  etl_actions_log.id%type;
  cnt_rec integer;
begin
  select count(*) into cnt_rec from Etl_Actions_Log t
  where trunc(t.updated)=trunc(sysdate)and t.action_name = upper('Fill_DM_BAL_SNAP')and t.state = 'COMPLETED';
  if check_sysdate_state (l_act_name) is null and cnt_rec>0 then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      ImportToDWH_PRIM('dm_bal_snap');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure imp2prim_OWS_CLIENT_BUF is
  l_act_name constant etl_actions_log.action_name%type:=Upper('imp2prim_OWS_CLIENT_BUF');
  l_action  etl_actions_log.id%type;
  cnt_rec integer;
begin
  select count(*) into cnt_rec from Etl_Actions_Log t
  where trunc(t.updated)=trunc(sysdate)and t.action_name = upper('Fill_OWS_CLIENT_BUF')and t.state = 'COMPLETED';
  if check_sysdate_state (l_act_name) is null and cnt_rec>0 then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      ImportToDWH_PRIM('OWS_CLIENT_BUF');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure imp2prim_client_map is
  l_act_name constant etl_actions_log.action_name%type:=Upper('imp2prim_client_map');
  l_action  etl_actions_log.id%type;
begin
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      ImportToDWH_PRIM('client_map');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure imp2prim_DM_CIF_BASE is
  l_act_name constant etl_actions_log.action_name%type:=Upper('imp2prim_DM_CIF_BASE');
  l_action  etl_actions_log.id%type;
  cnt_rec integer;
begin
  select count(*) into cnt_rec from Etl_Actions_Log t
  where trunc(t.updated)=trunc(sysdate)and t.action_name = upper('Fill_DM_CIF_BASE')and t.state = 'COMPLETED';
  if check_sysdate_state (l_act_name) is null and cnt_rec>0 then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      ImportToDWH_PRIM('DM_CIF_BASE');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure imp2prim_IB_REGCLIENT_FL is
  l_act_name constant etl_actions_log.action_name%type:=Upper('imp2prim_IB_REGCLIENT_FL');
  l_action  etl_actions_log.id%type;
  cnt_rec integer;
begin
  select count(*) into cnt_rec from Etl_Actions_Log t
  where trunc(t.updated)=trunc(sysdate)and t.action_name = upper('fill_IB_regclient_fl')and t.state = 'COMPLETED';
  if check_sysdate_state (l_act_name) is null and cnt_rec>0 then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      ImportToDWH_PRIM('IB_REGCLIENT_FL');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure imp2prim_calendar is
  l_act_name constant etl_actions_log.action_name%type:=Upper('imp2prim_calendar');
  l_action  etl_actions_log.id%type;
begin
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      ImportToDWH_PRIM('calendar');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure imp2prim_DASH_BOARD is
  l_act_name constant etl_actions_log.action_name%type:=Upper('imp2prim_DASH_BOARD');
  l_action  etl_actions_log.id%type;
  cnt_rec integer;
begin
  select count(*) into cnt_rec from Etl_Actions_Log t
  where trunc(t.updated)=trunc(sysdate)and t.action_name = upper('Dash_Board_Update')and t.state = 'COMPLETED';
  if check_sysdate_state (l_act_name) is null and cnt_rec>0 then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      ImportToDWH_PRIM('DASH_BOARD');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure imp2prim_DM_LOAN_PAYM_3 is
  l_act_name constant etl_actions_log.action_name%type:=Upper('imp2prim_DM_LOAN_PAYM_3');
  l_action  etl_actions_log.id%type;
  cnt_rec integer;
begin
  select count(*) into cnt_rec from Etl_Actions_Log t
  where trunc(t.updated)=trunc(sysdate)and t.action_name = upper('Fill_Payments_Schedulers')and t.state = 'COMPLETED';
  if check_sysdate_state (l_act_name) is null and cnt_rec>0 then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      ImportToDWH_PRIM('DM_LOAN_PAYM_3');
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure FINISH_ETL_RUN is
  l_act_name constant etl_actions_log.action_name%type:=Upper('FINISH_ETL_RUN');
  l_action  etl_actions_log.id%type;
begin
  /*imp2prim_DICT_PHONE_TYPES;
  imp2prim_CLIENT_PHONES;
  imp2prim_client;
  imp2prim_calendar;*/
  /*imp2prim_dm_cif_addr;
  imp2prim_DM_DELAY_CURR;
  imp2prim_ows_contract;
  imp2prim_DM_ACC_BASE;
  imp2prim_dm_dep_base;
  imp2prim_dm_loan_base
  imp2prim_transaction_3;
  imp2prim_c_dep;
  imp2prim_dm_bal_snap;
  imp2prim_OWS_CLIENT_BUF;
  imp2prim_client_map;
  imp2prim_DM_CIF_BASE;
  imp2prim_IB_REGCLIENT_FL;
  imp2prim_DASH_BOARD;
  imp2prim_DM_LOAN_PAYM_3;*/
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);
      Update_Etl_action(l_action,gc_Completed,(dbms_utility.get_time-gv_start)/100);
      exception
        when others then
           rollback;
           gv_err_count:=gv_err_count+1;
           Update_Etl_action(l_action,gc_Failed,(dbms_utility.get_time-gv_start)/100
            ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
           );
    END;
  end if;
end;
procedure run_morning
is
   l_s boolean;
   i integer;
   count_iter integer;
   sleeptime integer;
   cnt_rec integer;
   count_iter1 integer;
begin
  count_iter := 3;
  sleeptime := 900;
  i := 1;
  LOOP
     gv_err_count:=0;
     threads_1_2;
     if gv_err_count>0 then i := i + 1; if i<count_iter then DBMS_LOCK.Sleep(sleeptime); end if; end if;
     EXIT WHEN (i >= count_iter) or (gv_err_count=0) ;
  END LOOP;
  threads_1_2;
  if gv_err_count>0 then goto m; end if;
  threads_3_4;
  if gv_err_count>0 then goto m; end if;
  FILL_NBRK_CURRENCY_RATE;
  if gv_err_count>0 then goto m; end if;
  --SetDwhNlsParams; Нет необходимости, работаем с nls параметрами колвира вполне комфортно
  Fill_DM_LOAN_BASE;
  if gv_err_count>0 then goto m; end if;
  --RUN_JOB('ETL_IMP2PRIM_DM_LOAN_BASE_JOB');
  fill_dep;
  if gv_err_count>0 then goto m; end if;
  --RUN_JOB('ETL_IMP2PRIM_C_DEP_JOB');
  Fill_DM_CIF_BASE;
  if gv_err_count>0 then goto m; end if;
  --RUN_JOB('ETL_IMP2PRIM_DM_CIF_BASE_JOB');
  Fill_CS_CLI_RM_VCC;
  if gv_err_count>0 then goto m; end if;
  Fill_dm_acc_base;
  if gv_err_count>0 then goto m; end if;
  --RUN_JOB('ETL_IMP2PRIM_DM_ACC_BASE_JOB');
  i := 1;
  LOOP
     gv_err_count:=0;
     Fill_LOYAL_New;
     if gv_err_count>0 then i := i + 1; if i<count_iter then DBMS_LOCK.Sleep(sleeptime); end if; end if;
     EXIT WHEN (i >= count_iter) or (gv_err_count=0) ;
  END LOOP;
  COLVIR_IMPORT;
  if gv_err_count>0 then goto m; end if;
  loop
    exit when extract (hour from cast(sysdate as timestamp))>=6;
    DBMS_LOCK.Sleep(300);
  end loop;
  i := 1;
  LOOP
     save_debug_log('Fill_OWS_CLIENT_BUF 1. ');
     gv_err_count:=0;
     Fill_OWS_CLIENT_BUF;
     save_debug_log('Fill_OWS_CLIENT_BUF 2. ');
     if gv_err_count>0 then
        i := i + 1;
        if i<count_iter then
           save_debug_log('Fill_OWS_CLIENT_BUF 2.1. ');
           DBMS_LOCK.Sleep(sleeptime);
        end if;
     end if;
     EXIT WHEN (i >= count_iter) or (gv_err_count=0) ;
     save_debug_log('Fill_OWS_CLIENT_BUF 3. ');
  END LOOP;
  --Fill_OWS_CLIENT_BUF;
  if gv_err_count>0 then goto m; end if;
  --RUN_JOB('ETL_IMP2PRIM_OWS_CLIENT_JOB');
  fill_addr;
  if gv_err_count>0 then goto m; end if;
  --RUN_JOB('ETL_IMP2PRIM_DM_CIF_ADDR_JOB');
  FIll_DM_CIF_PHONE_NORMAL;
  if gv_err_count>0 then goto m; end if;
--  Fill_dm_acc_base;
--  if gv_err_count>0 then goto m; end if;
  Fill_DM_DELAY_CURR;
  if gv_err_count>0 then goto m; end if;
  --RUN_JOB('ETL_IMP2PRIM_DM_DELAY_CURR_JOB');
  Fill_DM_BAL_SNAP;
  if gv_err_count>0 then goto m; end if;
  --RUN_JOB('ETL_IMP2PRIM_DM_BAL_SNAP_JOB');
  Fill_dm_dep_base;
  if gv_err_count>0 then goto m; end if;
  --RUN_JOB('ETL_IMP2PRIM_DM_DEP_BASE_JOB');
 -- Fill_Bal_Regular;
  Fill_Client_all;
  if gv_err_count>0 then goto m; end if;
  Fill_Delay_Regular;
  if gv_err_count>0 then goto m; end if;
  /*i := 1;
  LOOP
     gv_err_count:=0;
     Fill_Trans_new; --стартует по джобу в 6 утра
     if gv_err_count>0 then i := i + 1; if i<count_iter then DBMS_LOCK.Sleep(sleeptime); end if; end if;
     EXIT WHEN (i >= count_iter) or (gv_err_count=0) ;
  END LOOP;
  --Fill_Trans_new;
  if gv_err_count>0 then goto m; end if;
  i := 1;
  LOOP
     gv_err_count:=0;
     Fill_W4_Contract; --стартует по джобу в 6 утра
     if gv_err_count>0 then i := i + 1; if i<count_iter then DBMS_LOCK.Sleep(sleeptime); end if; end if;
     EXIT WHEN (i >= count_iter) or (gv_err_count=0) ;
  END LOOP;
  --Fill_W4_Contract;
  if gv_err_count>0 then goto m; end if;*/
  Fill_dm_loan_base_add_2;
  if gv_err_count>0 then goto m; end if;
  Fill_Client_Phones_Colvir;
  if gv_err_count>0 then goto m; end if;
  Fill_Client_Phones_W4;
  if gv_err_count>0 then goto m; end if;
  Fill_Client_Phones_Ekz;
  if gv_err_count>0 then goto m; end if;
  Collaterals_Refresh;
  if gv_err_count>0 then goto m; end if;
  Application_Refresh;
  if gv_err_count>0 then goto m; end if;
  Dash_Board_Update;
  if gv_err_count>0 then goto m; end if;
  --RUN_JOB('ETL_IMP2PRIM_DASH_BOARD_JOB');
  fill_ekz_reject_reason;
  if gv_err_count>0 then goto m; end if;
/*  i := 1;
  LOOP
     gv_err_count:=0;
     Fill_LOYAL_New;
     if gv_err_count>0 then i := i + 1; if i<count_iter then DBMS_LOCK.Sleep(sleeptime); end if; end if;
     EXIT WHEN (i >= count_iter) or (gv_err_count=0) ;
  END LOOP;
*/  --ETL_PCK_NEW.Fill_LOYAL_New;
  if gv_err_count>0 then goto m; end if;
  count_iter1:=0;
  loop
    select count(*) into cnt_rec from Etl_Actions_Log t
    where trunc(t.updated) = trunc(sysdate) and t.action_name in ('FILL_W4_CONTRACT','FILL_TRANS_NEW')
          and t.state = 'COMPLETED';
    exit when cnt_rec >=2 or count_iter1>=24;
    DBMS_LOCK.Sleep(600);
    count_iter1:=count_iter1+1;
  end loop;
  if count_iter1>=24 then begin gv_err_count:=gv_err_count+1; goto m; end; end if;
  Fill_PayRoll_List_new;
  if gv_err_count>0 then goto m; end if;
  Fill_Payments_Schedulers;
  if gv_err_count>0 then goto m; end if;
  --RUN_JOB('ETL_IMP2PRIM_DASH_BOARD_JOB');
  fill_IB_regclient_fl;
  if gv_err_count>0 then goto m; end if;
  --RUN_JOB('ETL_IMP2PRIM_LOAN_PAYM_3_JOB');
  /*count_iter1:=0;
  loop
    select count(*) into cnt_rec from Etl_Actions_Log t
    where trunc(t.updated) = trunc(sysdate)
          and t.action_name in (
               'IMP2PRIM_DM_CIF_ADDR'
              ,'IMP2PRIM_DM_DELAY_CURR'
              ,'IMP2PRIM_OWS_CONTRACT'
              ,'IMP2PRIM_DM_ACC_BASE'
              ,'IMP2PRIM_DM_DEP_BASE'
              ,'IMP2PRIM_DM_LOAN_BASE'
              --,'IMP2PRIM_TRANSACTION_3'
              ,'IMP2PRIM_C_DEP'
              ,'IMP2PRIM_DM_BAL_SNAP'
              ,'IMP2PRIM_OWS_CLIENT_BUF'
              ,'IMP2PRIM_DM_CIF_BASE'
              ,'IMP2PRIM_IB_REGCLIENT_FL'
              ,'IMP2PRIM_DASH_BOARD'
              ,'IMP2PRIM_DM_LOAN_PAYM_3'
          )
          and t.state = 'COMPLETED';
    exit when cnt_rec >=13 or count_iter1>=24;
    DBMS_LOCK.Sleep(600);
    count_iter1:=count_iter1+1;
  end loop;
  if count_iter1>=24 then begin gv_err_count:=gv_err_count+1; goto m; end; end if;*/
  FINISH_ETL_RUN;
  if gv_err_count>0 then goto m; end if;
    <<m>>
  gc_Msg_tbl_info := 'DWH_BUFFER. Основной ETL (ETL_JOB)';
  l_s:=(gv_err_count=0);
  Send_Etl_Results2(sysdate,l_s);
  --DWH_SALES.ETL.run;
end;
procedure run_monthly
  is
 l_s boolean;
begin
  Fill_Bal_Regular;
  if gv_err_count>0 then goto m; end if;
  Fill_DM_LOAN_BAL_AGG;
  <<m>>
  gc_Msg_tbl_info := 'DWH_BUFFER. Ежемесячное обновление данных. (ETL_JOB_MONTHLY)';
  l_s:=(gv_err_count=0);
   Send_Etl_Results(sysdate,l_s);
end;
procedure ETL_NIGHT
  is
 l_s boolean;
begin
  fill_CASHANDGOFORRB_TMP;
  if gv_err_count>0 then goto m; end if;
  fill_CASHANDGOFORRB;
  if gv_err_count>0 then goto m; end if;
  fill_EKZ_PROCESS_RESULTS_TMP;
  if gv_err_count>0 then goto m; end if;
  fill_EKZ_PROCESS_RESULTS;
  if gv_err_count>0 then goto m; end if;
  --fill_clnt_analit_20141205;
  --if gv_err_count>0 then goto m; end if;
  --fill_clnt_analit_20141205_2;
  --if gv_err_count>0 then goto m; end if;
  --MV_CLNT_ANALIT_AGG_Refresh;
  --if gv_err_count>0 then goto m; end if;
  fill_EKZ_OpenWay;
  if gv_err_count>0 then goto m; end if;
  fill_EKZ_RET_GETSTEP;
  if gv_err_count>0 then goto m; end if;
  fill_ows_is_code_word;
  if gv_err_count>0 then goto m; end if;
  FILL_GSVP;
  if gv_err_count>0 then goto m; end if;
  --COLVIR_IMPORT;
  --if gv_err_count>0 then goto m; end if;
  FILL_W4_OPT_ACNT_BALANCE;
  if gv_err_count>0 then goto m; end if;
  /*fill_EKZ_Retail_getSteps_tmp;
  if gv_err_count>0 then goto m; end if;  */
    <<m>>
   gc_Msg_tbl_info := 'DWH_BUFFER. Вечерний запуск (ETL_JOB_STARTNIGHT)';
 l_s:=(gv_err_count=0);
  Send_Etl_Results(sysdate,l_s);
end;
begin
   SetColvirNlsParams;
end ETL_20151220;
/

