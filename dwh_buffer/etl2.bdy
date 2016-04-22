create or replace package body dwh_buffer.ETL2 is
    gc_bulk_limit constant integer:=80000;
    gc_Running constant varchar2(50 char):='RUNNING';
    gc_Completed constant varchar2(50 char):='COMPLETED';
    gc_Failed constant varchar2(50 char):='FAILED';
    gv_start number;
    gv_err_count number:=0;
    gc_Msg_tbl_info varchar2(100 char):='';

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

procedure Truncate_Table(p_table_name in varchar2, p_owner in varchar2 default 'DWH_BUFFER')
  is
begin
  execute immediate ('truncate table '||p_owner||'.'||p_table_name);
exception
  when others then
    RAISE;
end;


--------------------------------------------------------------------------------------------------------------------

procedure Loan_sched_refresh is
  l_act_name constant etl_actions_log.action_name%type:=Upper('Loan_sched_refresh');
  l_action  etl_actions_log.id%type;
  i number;
  cnt number;
begin
  if check_sysdate_state (l_act_name) is null then
    BEGIN
      gv_start:=dbms_utility.get_time;
      Store_Etl_Action(l_act_name,l_action);

      save_debug_log('Loan_sched_refresh : 1');
      colvir.ETL_DWH.run_thread_9@reps;
      save_debug_log('Loan_sched_refresh : 2');
      Truncate_Table('loan_sched_1');
      save_debug_log('Loan_sched_refresh : 3');
      --вылетает ошибка: ORA-00942: таблица или представление пользователя не существует ORA-02063: предшествующий line из REPS
      --DBMS_LOCK.Sleep(300); --пауза 5 мин
      select count(*) into cnt from colvir.ETL_LOAN_SCHED@reps where 1=2; --для проверки доступности таблицы
      save_debug_log('Loan_sched_refresh : 3.1');
      
      insert into loan_sched_1
      select t.*, sysdate as upd_dt from colvir.ETL_LOAN_SCHED@reps t;
      commit;
      save_debug_log('Loan_sched_refresh : 4');

      select count(*) into cnt from loan_sched_1;
      if cnt > 0 then
         save_debug_log('Loan_sched_refresh : 5');
         etl.ImportToDWH_PRIM('loan_sched_1');
         save_debug_log('Loan_sched_refresh : 6');
         
      end if;
      save_debug_log('Loan_sched_refresh : 7');

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

begin
   null;
end ETL2;
/

