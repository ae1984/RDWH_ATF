create or replace procedure dwh_buffer.col_C_PPRM
(cCode in varchar2, ret out varchar2, iDep in integer default null, iUsr in integer default null, iOrd in integer default null)
/***********************************************************
 $Header:   K:\CSSB\ARCHIVE\Core\ADMPROC\c_pPrm.sqv   1.8   May 06 2008 19:49:44   AKuterin  $

 Copyright (c) 2000 By Colvir Software Solutions. All Rights Reserved.

 Description: Возвращает значение системного параметра по его коду.
    C учетом назначений для пользователей и подразделений, значения по умолчанию.
 Параметры:
   cCode - код параметра;
   iDep  - ID подразделения;
   iUsr  - ID пользователя;
   iOrd  - номер в списке (передавать для параметров-массивов),
     по умолчанию для массива возвращает значение в виде списка через запятую.
 Boзврат:
   ret - значение параметра, если код неверен, поднимается ошибка
***********************************************************/
as
  idCls col_C_PRMCLS.ID%type;
  cVal  varchar2(4000);
  cursor crDep is
    select /*+ index (C_PRMVAL AK_C_PRMVAL_VALUE) */ SQL_VALUE from col_C_PRMVAL
    where PRM_ID=idCls and DEP_ID=iDep and TUS_ID is null and NORD=nvl(iOrd,NORD);
  cursor crUsr is
    select /*+ index (C_PRMVAL IE_C_PRMVAL_USR_PRM) */ trim(SQL_VALUE) from col_C_PRMVAL
    where PRM_ID=idCls and TUS_ID=iUsr and NORD=nvl(iOrd,NORD);
  cursor crAll_by_Nord is
    select /*+ index (V AK_C_PRMVAL_VALUE) */ nvl(V.SQL_VALUE,C.SQL_VALUE) from col_C_PRMVAL V, col_C_PRMCLS_STD C
    where C.ID=idCls and V.PRM_ID(+)=C.ID and V.DEP_ID is null and V.TUS_ID is null and V.NORD=iOrd;
  cursor crAll is
    select /*+ index (V AK_C_PRMVAL_VALUE) */ nvl(V.SQL_VALUE,C.SQL_VALUE) from col_C_PRMVAL V, col_C_PRMCLS_STD C
    where C.ID=idCls and V.PRM_ID(+)=C.ID and V.DEP_ID is null and V.TUS_ID is null;
begin
  idCls:= col_C_pkgPrm.fCode2Id(cCode);
  if nvl(iUsr,0)<>0 then
    open crUsr;
    loop
      fetch crUsr into cVal;
      exit when crUsr%NOTFOUND;
      if ret is not null then
        ret:= ret||',';
      end if;
      ret:= ret||cVal;
    end loop;
    close crUsr;
    if ret is not null then
       return;
    end if;
  end if;
  if nvl(iDep,0)<>0 then
    open crDep;
    loop
      fetch crDep into cVal;
      exit when crDep%NOTFOUND;
      if ret is not null then
        ret:= ret||',';
      end if;
      ret:= ret||cVal;
    end loop;
    close crDep;
    if ret is not null then
      return;
    end if;
  end if;
  if iOrd is not null then
    open crAll_by_Nord;
    loop
      fetch crAll_by_Nord into cVal;
      exit when crAll_by_Nord%NOTFOUND;
      if ret is not null then
        ret:= ret||',';
      end if;
      ret:= ret||cVal;
    end loop;
    close crAll_by_Nord;
  else
    open crAll;
    loop
      fetch crAll into cVal;
      exit when crAll%NOTFOUND;
      if ret is not null then
        ret:= ret||',';
      end if;
      ret:= ret||cVal;
    end loop;
    close crAll;
  end if;
  if ret is null then
    select SQL_VALUE into ret from col_C_PRMCLS where ID=idCls;
  end if;
end col_C_PPRM;
/

