create or replace function dwh_buffer.col_To_Money
/* ����������� �������� �������� ������� � ���������� ������
   � �������, �������� � ����� �������������� ���������� �����.
   �� ������������ ������������� ��������!
   ������������� ��� ������������� ������������� � �������� � �������. */
(nSumm in number, nFactor in integer default 0, nMask in integer default 2) return varchar2 as
  cRet   varchar2(42);
begin
  cRet:=col_T_PkgMoney.fTO_MONEY(nSumm,nFactor, nMask);
  return cRet;
end;
/

