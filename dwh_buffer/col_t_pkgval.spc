create or replace package dwh_buffer.col_T_PkgVal is

  -- Author  : ALEXEY-YE
  -- Created : 28.10.2015 16:45:45
  -- Purpose : 
  
  /* Функция возвращает множитель по ид валюты и дате */
  function fGetFac (nValid in integer, dDate in date default P_OPERDAY) return integer deterministic;


end col_T_PkgVal;
/

