create or replace procedure dwh_buffer.save_debug_log(p_val varchar2) is
  var_id number;
begin
  /*select max(id) into var_id from debug_log;
  if var_id is null then var_id := 0; end if;
  var_id := var_id +1;*/
  insert into debug_log (id, proc, val) values (debug_log_SEQ.Nextval, FN_WHO_AM_I(2) , p_val);

  commit;
end save_debug_log;
/

