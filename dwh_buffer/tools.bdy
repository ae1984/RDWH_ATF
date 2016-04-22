create or replace package body dwh_buffer.TOOLS is

procedure Save_DWH_Current_Size
is
begin
  insert into DWH_Size_Stat
  select t.bytes mb, t.segment_name,t.segment_type, sysdate as sdt from user_segments t --c 9.4.15 mb хранит bytes
  order by bytes desc;
  commit;
end;

procedure kill_session
is
begin
  For rec in (  --select * from v$session where username is not null and status = 'ACTIVE' and osuser = 'daniil-so'
    select * from v$session where username is not null and logon_time< sysdate-2
  ) loop
    kill_my_session (/*SID*/ rec.sid , rec.serial# /*SERIAL*/);
  end loop;
end;


procedure GRANT_SELECT_ANY_TABLES is
  cursor c1 is 
     select t.OBJECT_NAME from user_objects t 
     where t.OBJECT_TYPE in ('TABLE','VIEW','MATERIALIZED VIEW') and t.OBJECT_NAME<>'V_DWH_SIZE_STAT';
  cmd varchar2(200);
begin
  for c in c1 loop
    cmd := 'GRANT SELECT ON '||c.OBJECT_NAME|| '  to DWH_PRIM ';
    execute immediate cmd;
    cmd := 'GRANT SELECT ON '||c.OBJECT_NAME|| '  to DWH_SALES ';
    execute immediate cmd;
    cmd := 'GRANT SELECT ON '||c.OBJECT_NAME|| '  to DWH_RISK ';
    execute immediate cmd;
    cmd := 'GRANT SELECT ON '||c.OBJECT_NAME|| '  to HEAD_EVGENIY_PI ';
    execute immediate cmd;
    cmd := 'GRANT SELECT ON '||c.OBJECT_NAME|| '  to PROCESS_SALES ';
    execute immediate cmd;    
    cmd := 'GRANT SELECT ON '||c.OBJECT_NAME|| '  to PROCESS_RISK ';
    execute immediate cmd; 
       
    cmd := 'GRANT SELECT ON '||c.OBJECT_NAME|| '  to HEAD_DENIS_PL ';
    execute immediate cmd;
    cmd := 'GRANT SELECT ON '||c.OBJECT_NAME|| '  to AIBEK_BE ';
    execute immediate cmd;
    cmd := 'GRANT SELECT ON '||c.OBJECT_NAME|| '  to KRISTINA_KO ';
    execute immediate cmd;
        
  end loop;
end;

procedure ExportToDWH_BUFFER(p_tablename in varchar2, p_owner in varchar2)
is
begin
 execute immediate 
    ('declare i number;
      begin
         select count(*) into i from USER_TABLES WHERE TABLE_NAME = upper('''||p_tablename||''');
         if i<=0 then
             execute immediate(''
               create table '||p_tablename||' as
               select * from '||p_owner||'.'||p_tablename||'
               where 1=2
             '');
         end if;
      end;
    ') ; 
     
 execute immediate 
    ('declare i number;
      begin
         select count(*) into i from '||p_owner||'.'||p_tablename||';
         if i>0 then
             execute immediate (''truncate table '||p_tablename||''');
             insert /*+ append parallel 128 */
             into '||p_tablename||' 
             select /*+ parallel 128 */ * from '||p_owner||'.'||p_tablename||'
             ;
             commit;   
             select count(*) into i from '||p_tablename||';
             insert into TABLES_LOG (TABLE_NAME,REC_COUNT)
             values('''||p_tablename||''',i);
             commit;            
         end if;
      end;
    ') ; 
exception
  when others then
    RAISE;
end;


procedure REBUILD_ALL_INDEX is
  cursor c1 is 
    select index_name from user_indexes  where status <> 'N/A' and not index_name like 'SYS%';
   cmd varchar2(200);
begin
  for c in c1 loop
       save_debug_log('REBUILD_ALL_INDEX: '||c.index_name);
       --dbms_output.put_line(c.index_name);
       --execute immediate ('ALTER INDEX '||c.index_name||' REBUILD tablespace DWH_BUFFER');
       execute immediate ('ALTER INDEX '||c.index_name||' REBUILD');
  end loop;  

end;

--begin

end TOOLS;
/
grant execute on DWH_BUFFER.TOOLS to HEAD_EVGENIY_PI;


