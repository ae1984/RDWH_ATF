create or replace package body dwh_buffer.col_T_PkgVal is
 nFactor_NAT  pls_integer;
 
 
function fGetFac (nValid in integer, dDate in date default P_OPERDAY) return integer deterministic as
  nFactor integer;
begin
  if nValid=col_P_NATVAL and nFactor_NAT is not null then
    return nFactor_NAT;
  end if;
  select MULTIPLIER into nFactor from col_T_VAL_STD where Id=nValid;
  return(nFactor);
exception
  when NO_DATA_FOUND then
    return(0);
end;  

begin
  -- Initialization
  null;
end col_T_PkgVal;
/

