create or replace package dwh_buffer.col_C_pkgPrm is

  -- Author  : ALEXEY-YE
  -- Created : 28.10.2015 17:02:16
  -- Purpose : 
  
  -- Получение идентификатора параметра по коду параиметра
  function fCode2Id (cCode varchar2) return integer deterministic;

end col_C_pkgPrm;
/

