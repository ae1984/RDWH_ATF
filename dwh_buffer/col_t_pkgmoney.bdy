create or replace package body dwh_buffer.col_T_PkgMoney is

function fTrnMoneyToValue (cSumm in varchar2, nFactor in integer default 0) return number as
/* ����������� ���������� ������ � �������� �������� �������
   �� �������, ��������� � ����� �������������� ���������� �����.
   �� ������������ ������������� ��������!
   ������������� ��� ������������� ������������� � �������. */

  nRet number;

begin
  nRet:= ROUND(TO_NUMBER(REPLACE(cSumm,' '))*POWER(10,nFactor),12);
  return (nRet);
exception
  when others then
    return (null);
end;


Function fTo_Money
/* ����������� �������� �������� ������� � ���������� ������
   � �������, �������� � ����� �������������� ���������� �����.
   �� ������������ ������������� ��������!
   ������������� ��� ������������� ������������� � �������� � �������. */
(nSumm in number, nFactor in integer default 0, nMask in integer
   default 2) return varchar2 as
  cRet   varchar2(42);
  cStr   varchar2(42);
  cRazd  varchar2(5);
  ndMask pls_integer;
  nPoint pls_integer;
  nSum   number;
  nSymv pls_integer;
  cMask  varchar2(15):='9';

begin
  nSum:= abs(nSumm)/POWER(10,nFactor);
  if nFactor>0 then cMask:=RPAD(cMask,ABS(nFactor+1),'9'); end if;
  ndMask:=nMask-(ABS(nFactor)+2);
  if ndMask > 0 then cMask:=RPAD(cMask,Length(cMask)+ndMask,'9'); end if;
  cStr:=REPLACE(LTRIM(TO_CHAR(nSum,'0,999,999,999,999,999.99'||substr(cMask,2)),' 0,'),',',' ');
  nPoint:=INSTRB(cStr,'.'); -- ��� ��������� ���������� �����. ����e���=���-�� ������� �� ������
  if nPoint=1 then cStr:='0'||cStr; nSymv:=5;  -- �������� �����
  elsif nPoint >0 then
    cRazd:=REPLACE(substr('0,000,000,000,000,000.',1,22-nPoint),'0','');
    if cRazd is null then nSymv:=0; else nSymv:=LENGTH(cRazd); end if;
  else return (cStr); -- ����� �� �������� exception
  end if;
  cRet:=LPAD(cStr,LENGTH(cStr)+nSymv);
  return (cRet);
end;


begin
  -- Initialization
  null;
end col_T_PkgMoney;
/

