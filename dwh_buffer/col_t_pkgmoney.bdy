create or replace package body dwh_buffer.col_T_PkgMoney is

function fTrnMoneyToValue (cSumm in varchar2, nFactor in integer default 0) return number as
/* ѕреобразует символьную строку в значение денежной единицы
   из формата, прин€того в пол€х редактировани€ клиентской части.
   Ќе обрабатывает отрицательные значени€!
   ѕредназначена дл€ использовани€ исключительно с клиента. */

  nRet number;

begin
  nRet:= ROUND(TO_NUMBER(REPLACE(cSumm,' '))*POWER(10,nFactor),12);
  return (nRet);
exception
  when others then
    return (null);
end;


Function fTo_Money
/* ѕреобразует значение денежной единицы в символьную строку
   в формате, прин€том в пол€х редактировани€ клиентской части.
   Ќе обрабатывает отрицательные значени€!
   ѕредназначена дл€ использовани€ исключительно в запросах с клиента. */
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
  nPoint:=INSTRB(cStr,'.'); -- дл€ получени€ количества лидир. пробeлов=кол-ву зап€тых до первой
  if nPoint=1 then cStr:='0'||cStr; nSymv:=5;  -- значащей цифры
  elsif nPoint >0 then
    cRazd:=REPLACE(substr('0,000,000,000,000,000.',1,22-nPoint),'0','');
    if cRazd is null then nSymv:=0; else nSymv:=LENGTH(cRazd); end if;
  else return (cStr); -- чтобы не возникал exception
  end if;
  cRet:=LPAD(cStr,LENGTH(cStr)+nSymv);
  return (cRet);
end;


begin
  -- Initialization
  null;
end col_T_PkgMoney;
/

