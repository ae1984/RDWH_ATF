create or replace package dwh_buffer.col_rsatf_trf is

  -- Author  : ALEXEY-YE
  -- Created : 29.10.2015 10:19:10
  -- Purpose : 
  
  function fGetGl(sArea in varchar2, sCode in varchar2) return varchar2;


end col_rsatf_trf;
/

