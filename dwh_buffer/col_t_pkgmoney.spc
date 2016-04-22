create or replace package dwh_buffer.col_T_PkgMoney is

  -- Author  : ALEXEY-YE
  -- Created : 28.10.2015 12:36:53
  -- Purpose : 
  
/* ����������� ���������� ������ � �������� �������� ������� �� �������, ��������� � ����� �������������� ���������� �����.
   �� ������������ ������������� ��������! */
function fTrnMoneyToValue (cSumm in varchar2, nFactor in integer default 0) return number;


/* ����������� �������� �������� ������� � ���������� ������   � �������, �������� � ����� �������������� ���������� �����.
   �� ������������ ������������� ��������! */
function fTo_Money(nSumm in number, nFactor in integer default 0, nMask in integer
   default 2) return varchar2;
   
end col_T_PkgMoney;
/

