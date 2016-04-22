create or replace trigger dwh_buffer.T_TABLES_LOG_ID
  before insert on TABLES_LOG
  for each row
declare
begin
    :new.id := TABLES_LOG_SEQ.Nextval;
    :new.SDT := sysdate;
end T_TABLES_LOG_ID;
/

