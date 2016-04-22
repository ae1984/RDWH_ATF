create or replace package body dwh_buffer.col_C_PkgRnd is


  -- ��������� ���������� ����� � ������ "������" ��� ��������. ���������: �����, ������, [����� ������ �����
  -- ������� (0-�� �����, 2-�� �����, -2 - �� �����)], [������� ���������� � ������� (1) ��� ������� (-1) �������.
  -- �� ��������� (0) �� �������� ����������]
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

