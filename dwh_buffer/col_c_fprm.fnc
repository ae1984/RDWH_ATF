create or replace function dwh_buffer.col_C_FPRM
(cCode varchar2, iDep integer default null, iUsr integer default null, iOrd in integer default null)
$if col_C_pkgPLSQL.c_OracleVersion11
$then
  return varchar2 result_cache relies_on(C_PRMVAL, C_PRMCLS_STD, C_PRMCLS_LOC) deterministic
$else
  return varchar2 deterministic
$end
/***********************************************************
 $Header:   K:\CSSB\ARCHIVE\Core\ADMFUNC\c_fPrm.sqv   1.4   May 06 2008 19:52:08   AKuterin  $

 Copyright (c) 2000 By Colvir Software Solutions. All Rights Reserved.

 Description: Возвращает значение системного параметра по его коду.
    C учетом назначений для пользователей и подразделений, значения по умолчанию.
 Параметры:
   cCode - код параметра;
   iDep  - ID подразделения;
   iUsr  - ID пользователя;
   iOrd  - номер в списке (передавать для параметров-массивов),
     по умолчанию для массива возвращает значение в виде списка через запятую.
 Boзврат: значение параметра либо null если ничего не найдено.
***********************************************************/
as
  ret varchar2(4000);
begin
  col_c_pPrm (cCode,ret,iDep,iUsr,iOrd);
  return (ret);
exception
  when others then
    return (null);
end col_C_FPRM;
/

