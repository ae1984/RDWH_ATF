create or replace package dwh_buffer.col_C_PKGSBJUTL is

  -- Author  : ALEXEY-YE
  -- Created : 28.10.2015 9:43:21
  -- Purpose : 
  type tSbjConceptList is table of varchar2(250) index by binary_integer;
  SbjConceptList tSbjConceptList; -- ����� ��� ������ � ���������� ��� ��� ���������
  
    type rUsedProcess is record (PROC_ID integer, NJRN integer, BOP_ID integer, NOPER integer, READFL integer, DEP_ID integer, ORD_ID integer);
 
 -- ��������� �������� ��� � ��������� ��������� �������� (��������)
  -- �� ������, ��� �������������� ���� �������� ��� ��� ������� ��������,
  -- ���� ������� ��������������� ������� ��� ������ �������
  -- ����� � ������� ����������� �������� ������ � ���������� ���������� SbjConceptList (��. ����)
  function fValue (
    p_Sbj in integer,              -- ��� (������)
    p_Prc in integer default null, -- ������� (������), ����� �� �����������, ���� �� ����� ���������� � ���� ����� p_Bop
    p_Jrn in integer default null, -- �������� (����� � �������), �� ��������� ��� ��������� ��������, ������ ����� ��� ��������
    p_Bop in integer default null, -- �������� (������), �� ��������� ������������ �� ��������
    p_Read in integer default 0,   -- ������� (1/0), ���������� ��� (1) ��� ����� �� ������ (0)
    p_Nop in integer default null, -- ����� �������� �� �������� - ����� ������ ��� ������� ���, ��������� � ���������� ��������
    p_Raise in integer default 0   -- ������� �������� ������ � ������, ����� ��� �� ���������
  ) return varchar2;
  
  -- ���������� �������� ��� �� ������. �������� ���� ��� ��� ���
  function fGetItem (rProc in rUsedProcess, idSbj in integer) return varchar2;

end col_C_PKGSBJUTL;
/

