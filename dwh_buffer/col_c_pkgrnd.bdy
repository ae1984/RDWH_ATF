create or replace package body dwh_buffer.col_C_PkgRnd is


  -- Округляет переданную сумму с учетом "сдвига" при хранении. Параметры: сумма, валюта, [число знаков после
  -- запятой (0-до целых, 2-до сотых, -2 - до сотен)], [признак округления в большую (1) или меньшую (-1) сторону.
  -- по умолчанию (0) по правилам арифметики]
  function fRound(nAMOUNT in number, idVal in integer, nDec in integer default 0, iHiLow in integer default 0) return number as
    nFactor integer;
    Result number(18,2);
    iSign  integer;
  begin
    nFactor := nDec - col_T_PkgVal.fGetFac(idVal);
    Result := Round(nAMOUNT,nFactor);
    iSign := Sign(nAMOUNT - Result);
    if iHiLow = iSign then
      Result := Result + iSign*POWER(10,-nFactor);
    end if;
    return Result;
  end fRound;
  
  
  function fRndRef(nAMOUNT in number, idVal in integer, idRnd in integer) return number as
    nDec integer;
    iHiLow integer;
  begin
    if idRnd is null then
      return nAMOUNT;
    else
      select NDEC, HILOW into nDec, iHiLow from col_C_RNDMETH where ID = idRnd;
      return fRound(nAMOUNT, idVal, nDec, iHiLow);
    end if;
  end;

begin
  -- Initialization
  null;
end col_C_PkgRnd;
/

