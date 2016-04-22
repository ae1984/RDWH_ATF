create or replace package body dwh_buffer.TOOLS2 is


procedure GRANT_SELECT_ANY_TABLES is
  cursor c1 is select t.OBJECT_NAME from user_objects t where t.OBJECT_TYPE in ('TABLE','VIEW','MATERIALIZED VIEW');
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
  end loop;
end;

procedure ExportToDWH_BUFFER(p_tablename in varchar2, p_owner in varchar2)
is
  i number;
begin
 select count(*) into i from TABLES_LOG t where t.table_name = p_tablename;
 if i<=0  then
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
 end if;
exception
  when others then
    RAISE;
end;

--begin

end TOOLS2;
/
grant execute on DWH_BUFFER.TOOLS2 to HEAD_EVGENIY_PI;


