create or replace package dwh_buffer.col_GL_ANL is

  -- Author  : ALEXEY-YE
  -- Created : 28.10.2015 13:02:14
  -- Purpose : 

  type rAnlKey is record (       -- ���� �������������� ��������
    PK1          varchar2(18),   -- ������ ���� �����
    PK2          varchar2(18));  -- ������ ���� �����
  type tAnlKey is table of rAnlKey index by binary_integer;

end col_GL_ANL;
/

