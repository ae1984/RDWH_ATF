create or replace package body dwh_buffer.col_C_pkgPrm is

  function fCode2Id (cCode varchar2) return integer deterministic as
    iRet pls_integer;
  begin
    select ID into iRet from col_C_PRMCLS_STD where CODE=upper(cCode);
    return (iRet);
  exception
    when NO_DATA_FOUND then
      --C_PkgErr.pRegMsg('14','%0=>'||upper(cCode),1);
      null;
  end;

begin
  -- Initialization
  null;
end col_C_pkgPrm;
/

