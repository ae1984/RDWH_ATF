create or replace package dwh_buffer.col_C_PkgRnd is

  -- Author  : ALEXEY-YE
  -- Created : 28.10.2015 16:43:23
  -- Purpose : 
  
  -- Делает все то же самое, но параметры берет из справочника типов округлений c_rndmeth
  function fRndRef(nAMOUNT in number, idVal in integer, idRnd in integer) return number;


end col_C_PkgRnd;
/

