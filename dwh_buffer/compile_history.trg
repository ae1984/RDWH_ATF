create or replace trigger dwh_buffer.compile_history
  before create on schema
declare
  l_date  date := sysdate;
  l_ver   number;
begin
  if (ora_dict_obj_type in
            ( 'PACKAGE'
             ,'PACKAGE BODY'
             ,'PROCEDURE'
             ,'FUNCTION'
             ,'TYPE'
             ,'TRIGGER' ) )
  then
    select version_seq.nextval
         into l_ver from dual;
    insert into old_code
    select user, l_ver, l_date, user_source.*
      from user_source
     where name = ora_dict_obj_name
       and type = ora_dict_obj_type;
  end if;
end;
/

