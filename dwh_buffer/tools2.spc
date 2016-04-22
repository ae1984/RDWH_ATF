create or replace package dwh_buffer.TOOLS2 is

  -- Author  : ALEXEY-YE
  -- Created : 04.06.2015 15:29:04
  -- Purpose : 
  
  procedure GRANT_SELECT_ANY_TABLES;
  procedure ExportToDWH_BUFFER(p_tablename in varchar2, p_owner in varchar2);

end TOOLS2;
/
grant execute on DWH_BUFFER.TOOLS2 to HEAD_EVGENIY_PI;


