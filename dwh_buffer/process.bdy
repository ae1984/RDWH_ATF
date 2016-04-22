create or replace package body dwh_buffer.PROCESS is

procedure table_refresh(src varchar2, dest varchar2)
 is
  i number;
begin
  select count(*) into i from user_tables t where t.TABLE_NAME = upper(dest); 
  if i > 0 then
     execute immediate ('drop table '||dest||' purge'); 
  end if;
  execute immediate ('create table '||dest||' as select t.*, sysdate as upd_DT1 from '||src||' t');
  execute immediate ('grant select on '||dest||' to RISK_REPORTER_ROLE');
end;

procedure get_colvir_t_bal(v_dt date)
is
  --TYPE   CurTyp IS REF CURSOR;  
  --cur1   CurTyp;  
  --l COL_T_BAL%rowtype;
  i number; 
begin
   select count(1) into i from COL_T_BAL t where t.FROMDATE = v_dt and rownum = 1;
   if i<=0 then
     --OPEN cur1 FOR  -- open cursor variable
     --     'select * from colvir.T_BAL@reps where FROMDATE = :s' USING v_dt;
     /*loop
        fetch cur1 into l ;
        EXIT WHEN cur1%NOTFOUND;
        if i<=0 then
           insert *+ append * 
           into COL_T_BAL values l;
        end if;      
     end loop;
     close cur1; */

     insert /*+ append */ 
     into COL_T_BAL 
     select * from colvir.T_BAL@reps where FROMDATE = v_dt;
     commit;
    

   end if; 
end;  

procedure upd_col_synh_log(p_id in number,p_stat in varchar2,p_duration in number, 
            p_num_rows_i in number,
            p_num_rows_u in number,
            p_num_rows_d in number
            , p_info in xmltype default null)
  is
 PRAGMA AUTONOMOUS_TRANSACTION;
begin
  update COL_SYNH_LOG e
  set e.stat=p_stat,
      e.duration=p_duration,
      e.FINISH_DT=sysdate,
      e.info=p_info,
      e.num_rows_i = P_num_rows_i,
      e.num_rows_u = P_num_rows_u,
      e.num_rows_d = P_num_rows_d
  where e.id=p_id ;
  commit;
end;

procedure crt_col_synh_log(p_tname in varchar2, P_COL_SYNH_ID in number ,p_id out number)
  is
 PRAGMA AUTONOMOUS_TRANSACTION;
 l_id COL_SYNH_LOG.id%type;
begin
  insert into COL_SYNH_LOG(
      ID
      ,TABLE_NAME
      ,START_DT
      ,FINISH_DT
      ,COL_SYNH_ID
      ,DURATION
      ,STAT
      ,INFO
      ,num_rows_i
      ,num_rows_u
      ,num_rows_d
  )
  values (
       COL_SYNH_LOG_SEQ.nextval
       ,p_tname
       ,sysdate
       ,null
       ,P_COL_SYNH_ID
       ,null
       ,'RUNNING'
       ,null
       ,null
       ,null
       ,null
       )
  returning id into l_id
  ;
  p_id:=l_id;
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


/*procedure colvir_synh
is
  v_ACTION varchar2(10);
  v_PK1 COL_SYNH.cvalue%type;
  v_PK2 COL_SYNH.cvalue%type;
  v_PK3 COL_SYNH.cvalue%type;
  v_PK4 COL_SYNH.cvalue%type;
  v_PK5 COL_SYNH.cvalue%type;
  v_PK6 COL_SYNH.cvalue%type;
  
  st number;
  v_col_synh_log_id  col_synh_log.id%type;
  v_num_rows_i number;
  v_num_rows_u number;
  v_num_rows_d number;
begin
  --первая версия импорта данный из ММС, нужно переписать на новую, универсальную 
  For rec in ( select t.snd_dt,t.id,t.cvalue from COL_SYNH t where t.code = 'TABLE_NAME' order by id) loop
    begin  
      v_num_rows_i:=0;
      v_num_rows_u:=0;
      v_num_rows_d:=0;
      st:=dbms_utility.get_time;
      crt_col_synh_log(rec.cvalue, rec.id ,v_col_synh_log_id);
      
      
      select cvalue into v_ACTION from COL_SYNH where id = rec.id and code = 'ACTION';
      select cvalue into v_PK1 from COL_SYNH where id = rec.id and code = 'PK1';
      select cvalue into v_PK2 from COL_SYNH where id = rec.id and code = 'PK2';
      select cvalue into v_PK3 from COL_SYNH where id = rec.id and code = 'PK3';
      select cvalue into v_PK4 from COL_SYNH where id = rec.id and code = 'PK4';
      select cvalue into v_PK5 from COL_SYNH where id = rec.id and code = 'PK5';
      select cvalue into v_PK6 from COL_SYNH where id = rec.id and code = 'PK6';
      
      --C_DOMAIN_STD
      if rec.cvalue = 'C_DOMAIN_STD' and v_ACTION in ('D','U','I') then
         delete from COL_C_DOMAIN_STD t where t.code = v_PK1;
         v_num_rows_d:= nvl(SQL%ROWCOUNT,0);
      end if;
      if rec.cvalue = 'C_DOMAIN_STD' and v_ACTION in ('U','I') then
        insert \*+ append *\ into COL_C_DOMAIN_STD
        select * from colvir.C_DOMAIN_STD@reps where code = v_PK1;
        v_num_rows_i:= nvl(SQL%ROWCOUNT,0);
      end if;
      
      --T_OPERJRN
      if rec.cvalue = 'T_OPERJRN' and v_ACTION in ('D','U','I') then
         delete from COL_T_OPERJRN t where t.ID= v_PK1 and t.NJRN = v_PK2;
         v_num_rows_d:= nvl(SQL%ROWCOUNT,0);
      end if;
      if rec.cvalue = 'T_OPERJRN' and v_ACTION in ('U','I') then
        insert \*+ append *\ into COL_T_OPERJRN
        select * from colvir.T_OPERJRN@reps where ID= v_PK1 and NJRN = v_PK2;
        v_num_rows_i:= nvl(SQL%ROWCOUNT,0);
      end if;
      
      
      commit;
      st:= (dbms_utility.get_time-st)/100;
      upd_col_synh_log(v_col_synh_log_id,'COMPLETED',st,v_num_rows_i,v_num_rows_u,v_num_rows_d,null);
    exception
      when others then
        rollback;
        --gv_err_count:=gv_err_count+1;
        upd_col_synh_log(v_col_synh_log_id,'FAILED',st,v_num_rows_i,v_num_rows_u,v_num_rows_d 
           ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
        );
                      
    end;
  end loop;
                 
  
end;*/


procedure colvir_synh
is
  l_cnt number;
  st number;
  v_col_synh_log_id  col_synh_log.id%type;
  v_num_rows_i number;
  v_num_rows_u number;
  v_num_rows_d number;
begin
    For rec in (select /*+parallel(128)*/ * from V_COL_SYNH_TAB_SQL --where id = 507270699
      order by id ) loop
      begin
          v_num_rows_i:=0;
          v_num_rows_u:=0;
          v_num_rows_d:=0;
          st:=dbms_utility.get_time;
          crt_col_synh_log(rec.tname, rec.id ,v_col_synh_log_id);        
          if rec.action in ('D','U','I') then
           --execute immediate 'begin ' || rec.sql_1 || '; :x := sql%rowcount; end;' using out l_cnt;
           --v_num_rows_d:=l_cnt;
           execute immediate (rec.sql_1);
           v_num_rows_d:=SQL%ROWCOUNT;
          end if; 
          if rec.action in ('U') then
           --execute immediate 'begin ' || rec.sql_2 || '; :x := sql%rowcount; end;' using out l_cnt;
           --v_num_rows_u:=l_cnt;
           execute immediate (rec.sql_2);
           v_num_rows_u:=SQL%ROWCOUNT;
          end if; 
          if rec.action in ('I') then
           --execute immediate 'begin ' || rec.sql_2 || '; :x := sql%rowcount; end;' using out l_cnt;
           --v_num_rows_i:=l_cnt;
           execute immediate (rec.sql_2);
           v_num_rows_u:=SQL%ROWCOUNT;
          end if; 
                  
        st:= (dbms_utility.get_time-st)/100;
        upd_col_synh_log(v_col_synh_log_id,'COMPLETED',st,v_num_rows_i,v_num_rows_u,v_num_rows_d,null);
      exception
        when others then
          rollback;
          --gv_err_count:=gv_err_count+1;
          upd_col_synh_log(v_col_synh_log_id,'FAILED',st,v_num_rows_i,v_num_rows_u,v_num_rows_d 
             ,Fill_Info(sqlcode,sqlerrm,Dbms_Utility.format_error_stack,Dbms_Utility.format_call_stack,Dbms_Utility.format_error_backtrace)
          );
      end;
    end loop;  
end;



procedure colvir_synh_0
is
begin
  --сообщения из ММС в виде кучи
  insert /*+parallel(8) append*/ into col_synh  
  select t.snd_dt, a.* from colvir.c_ntfjrn@reps t 
  left join colvir.C_NTFDET@reps a on a.id = t.id
  where t.dsc_id in (SELECT id FROM colvir.C_NTFDSC_STD@reps V WHERE V.CODE='Z_025_DWH') and t.status='0' and t.snd_dt>=trunc(sysdate-2)
  order by snd_dt;
  commit;
  --преобразование кучи в реляционный вид (таблицу)
  insert /*+parallel(64) append*/ into COL_SYNH_TAB 
  select 
         t.cvalue as tname
        ,t.snd_dt
        ,t.id
        ,a.cvalue as ACTION 
        ,b1.cvalue as PK1
        ,b2.cvalue as PK2
        ,b3.cvalue as PK3
        ,b4.cvalue as PK4
        ,b5.cvalue as PK5
        ,b6.cvalue as PK6
  from COL_SYNH t 
    join COL_SYNH a on a.id = t.id and a.code = 'ACTION'
    join COL_SYNH b1 on b1.id = t.id and b1.code = 'PK1'
    join COL_SYNH b2 on b2.id = t.id and b2.code = 'PK2'
    join COL_SYNH b3 on b3.id = t.id and b3.code = 'PK3'
    join COL_SYNH b4 on b4.id = t.id and b4.code = 'PK4'
    join COL_SYNH b5 on b5.id = t.id and b5.code = 'PK5'
    join COL_SYNH b6 on b6.id = t.id and b6.code = 'PK6'
  where t.code = 'TABLE_NAME';
  commit;
  -- результат в V_COL_SYNH_TAB  и   V_COL_SYNH_TAB_SQL
end;

procedure colvir_synh_1
is
begin
  --create table COL_SYNH_SCHEME2 as
  --синхронизация недостающих таблиц и полей и типов данных из ММС
  insert into COL_SYNH_SCHEME
  select t.tname, t.col_field,t.field, a.DATA_TYPE, a.DATA_LENGTH from COL_SYNH_SCHEME t
  left join user_tab_cols a on upper(a.TABLE_NAME) = 'COL_'||upper(t.tname) and upper(a.COLUMN_NAME) = upper(t.field)
  where t.tname not in (select distinct tname from COL_SYNH_SCHEME)
  order by t.tname, t.col_field;
  commit;
end;


procedure colvir_synh_2
is
  v_f varchar2(4000);
begin
  delete from COL_SYNH_2;
  commit;
  --определение наименований всех столбцов в таблице
  For rec in (select distinct a.TABLE_NAME from COL_SYNH_SCHEME t join user_tab_cols a on upper(a.TABLE_NAME) = 'COL_'||upper(t.tname)) loop
     v_f:='';
     For rec2 in (select a.COLUMN_NAME from user_tab_cols a where upper(a.TABLE_NAME) = rec.table_name  and a.HIDDEN_COLUMN = 'NO') loop
        if length(v_f) >0 then v_f:=v_f||', '; end if;
        v_f:=v_f||rec2.column_name;
     end loop;    
     insert into COL_SYNH_2 (TABLE_NAME,COLUMNS_NAME) values(rec.table_name,v_f);
     commit; 
  end loop;  

end;

procedure colvir_synh_00
is
begin
  --таблицы и поля которые учавствуют в выборке данных из ММС
  --create table col_synh_scheme as
  insert into col_synh_scheme
  select /*+parallel(8)*/ distinct tname, code as col_field, '-' as field, null,null from
    (
    select a.cvalue as tname ,t.* 
    from (select id, code, cvalue, snd_dt from COL_SYNH where code like 'PK%' and cvalue is not null) t
    join (select id, cvalue from COL_SYNH where code = 'TABLE_NAME') a on a.id = t.id
    ) t
  where t.tname not in (select distinct tname from COL_SYNH_SCHEME);
  commit;
end;


begin
  -- Initialization
  null;
end PROCESS;
/

