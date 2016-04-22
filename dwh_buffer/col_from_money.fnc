create or replace function dwh_buffer.col_From_Money
/* ����������� �������� �������� ������� � ���������� ������
   � �������, �������� � ����� �������������� ���������� �����.
   �� ������������ ������������� ��������!
   ������������� ��� ������������� ������������� � �������� � �������. */
(nSumm in varchar2, nFactor in integer default 0) return number as
  cRet   number(18,2);
begin
  cRet:=col_T_PkgMoney.fTrnMoneyToValue(nSumm,nFactor);
  return cRet;
end;
/

