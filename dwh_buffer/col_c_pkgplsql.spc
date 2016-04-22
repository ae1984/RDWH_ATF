create or replace package dwh_buffer.col_C_PKGPLSQL as
  --Если на инстанции установлен Oracle 11, то перевести значение константы в TRUE
  c_OracleVersion11 constant boolean:= false;
end col_C_PKGPLSQL;
/

