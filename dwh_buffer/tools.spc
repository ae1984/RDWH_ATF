create or replace package dwh_buffer.TOOLS is

  -- Author  : ALEXEY-YE
  -- Created : 04.06.2015 15:29:04
  -- Purpose : 
  procedure Save_DWH_Current_Size;
  procedure GRANT_SELECT_ANY_TABLES;
  procedure ExportToDWH_BUFFER(p_tablename in varchar2, p_owner in varchar2);
  procedure REBUILD_ALL_INDEX ;
  procedure kill_session;
  
end TOOLS;
/
grant execute on DWH_BUFFER.TOOLS to HEAD_EVGENIY_PI;


