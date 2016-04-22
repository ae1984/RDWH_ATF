create or replace package body dwh_risk.TOOLS is

procedure Save_DWH_Current_Size
is
begin
  insert into DWH_Size_Stat
  select t.bytes mb, t.segment_name,t.segment_type, sysdate as sdt from user_segments t 
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
  cursor c1 is select t.OBJECT_NAME from user_objects t where t.OBJECT_TYPE in ('TABLE','MATERIALIZED VIEW');
  cmd varchar2(200);
begin
  for c in c1 loop
    cmd := 'GRANT SELECT ON '||c.OBJECT_NAME|| '  to PROCESS_RISK ';
    execute immediate cmd;
    cmd := 'GRANT SELECT ON '||c.OBJECT_NAME|| '  to HEAD_DENIS_PL ';
    execute immediate cmd;
    cmd := 'GRANT SELECT ON '||c.OBJECT_NAME|| '  to AIBEK_BE ';
    execute immediate cmd;
    cmd := 'GRANT SELECT ON '||c.OBJECT_NAME|| '  to KRISTINA_KO ';
    execute immediate cmd;

    /*cmd := 'GRANT SELECT ON '||c.OBJECT_NAME|| '  to DWH_PRIM ';
    execute immediate cmd;
    cmd := 'GRANT SELECT ON '||c.OBJECT_NAME|| '  to DWH_SALES ';
    execute immediate cmd;
    cmd := 'GRANT SELECT ON '||c.OBJECT_NAME|| '  to HEAD_EVGENIY_PI ';
    execute immediate cmd;*/
  end loop;
end;

procedure ExportToDWH_RISK(p_tablename in varchar2, p_owner in varchar2)
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
             insert /*+ append */
             into '||p_tablename||' 
             select * from '||p_owner||'.'||p_tablename||'
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


procedure CreateViewFromDWH_PRIM is
  cursor c1 is select t.OBJECT_NAME from all_objects t where t.owner = 'DWH_PRIM' and t.OBJECT_TYPE in ('TABLE','VIEW','MATERIALIZED VIEW');
  cmd varchar2(200);
begin
  for c in c1 loop
    cmd:='create or replace view '||c.OBJECT_NAME||' as select * from DWH_PRIM.'||c.OBJECT_NAME;
    execute immediate cmd;
  end loop;
end;


--begin

end TOOLS;
/
grant execute on DWH_RISK.TOOLS to HEAD_EVGENIY_PI;


