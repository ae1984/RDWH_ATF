create or replace package dwh_buffer.col_C_PKGDECTBL is

  -- Author  : ALEXEY-YE
  -- Created : 28.10.2015 12:07:13
  -- Purpose : 
  
  type tDecision is record (NPP integer, NORD integer, LONGNAME varchar2(250), SOLUTION varchar2(250));
  type tDecisionList is table of tDecision index by binary_integer;
  function fSbjDecision(idTbl in integer, rUP in col_C_PkgSbjUtl.rUsedProcess, bFirst in boolean) return tDecisionList;

end col_C_PKGDECTBL;
/

