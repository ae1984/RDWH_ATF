create or replace package dwh_buffer.col_GL_ANL is

  -- Author  : ALEXEY-YE
  -- Created : 28.10.2015 13:02:14
  -- Purpose : 

  type rAnlKey is record (       -- ключ аналитического признака
    PK1          varchar2(18),   -- первое поле ключа
    PK2          varchar2(18));  -- второе поле ключа
  type tAnlKey is table of rAnlKey index by binary_integer;

end col_GL_ANL;
/

