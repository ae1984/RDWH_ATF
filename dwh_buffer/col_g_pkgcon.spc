create or replace package dwh_buffer.col_G_PKGCON is

  -- Author  : ALEXEY-YE
  -- Created : 29.10.2015 10:23:30
  -- Purpose : 
  
/* функция нормализованного представления кода для вершин групп консолидации, iDisableNornal олтключает нормализацию */
function fCode(iId integer, iDisableNormal integer default 0) return varchar2 deterministic;

/* Вытаскмвает наименовнаие по ENT_ID, D_1, D_2, D_3*/
function fGetLName(idConHi in integer, IdEnt in integer, nID_1 in integer, nID_2 in integer default 0, nID_3 in integer default 0, cTypRet in varchar2 default 'L') return varchar2;

end col_G_PKGCON;
/

