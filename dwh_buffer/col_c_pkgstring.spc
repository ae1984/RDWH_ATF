create or replace package dwh_buffer.col_C_pkgString is

  -- Author  : ALEXEY-YE
  -- Created : 28.10.2015 12:34:49
  -- Purpose : 
  
  -- ���������� ����� �� ������ cStr (iNum �� ������), ����������� ���� ���������� � cDelimiters
  -- ��� ������ ����������� ��������� ������ null
  -- ���� ����� �� ����� ���� ��������, �� ������������ null.
  function fToken2(cStr        in varchar2,
                   iNum        in integer,
                   cDelimiters in varchar2 default '.,') return varchar2;
                   
  /* ���������, �������� �� ������ cAttr ��� ������� cValue, ��� ���������
   ������ � ���� ������ ������� VAL10,VAL30:VAL50,VAL70,VAL9%,VAL_8.
    ������� ������� ������������� ��������, �� ������� �������� fTrnStrToWhere,
    ������ ����� �������� � ������� �� �������������� 30-� ���������.
  � ������ ���� �������� cValue ����� ������ ���������, ����� ������������ ������ ��� ����� $N ��� ��� ���� $D.
  ����� ��� ��������� ������ � ������ ������� ����� ����������������� � ����� ��� � ������ */
  function fChkCond(cAttr in varchar2, cValue in varchar2) return boolean;                   

end col_C_pkgString;
/

