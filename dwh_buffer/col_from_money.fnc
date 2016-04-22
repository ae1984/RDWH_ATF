create or replace function dwh_buffer.col_From_Money
/* ѕреобразует значение денежной единицы в символьную строку
   в формате, прин€том в пол€х редактировани€ клиентской части.
   Ќе обрабатывает отрицательные значени€!
   ѕредназначена дл€ использовани€ исключительно в запросах с клиента. */
(nSumm in varchar2, nFactor in integer default 0) return number as
  cRet   number(18,2);
begin
  cRet:=col_T_PkgMoney.fTrnMoneyToValue(nSumm,nFactor);
  return cRet;
end;
/

