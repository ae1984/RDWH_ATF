create or replace package dwh_risk.TOOLS is

  -- Author  : ALEXEY-YE
  -- Created : 04.06.2015 15:29:04
  -- Purpose : 
  procedure Save_DWH_Current_Size;
  procedure GRANT_SELECT_ANY_TABLES;
  procedure ExportToDWH_RISK(p_tablename in varchar2, p_owner in varchar2);
  procedure CreateViewFromDWH_PRIM;
  procedure kill_session;

end TOOLS;
/
grant execute on DWH_RISK.TOOLS to HEAD_EVGENIY_PI;


