create or replace package body dwh_buffer.col_T_PkgDeaPrm is
  --  Для буферизации параметров классификатора сделок
  type rPrmCls is record (
    ID   col_T_DEAPRMDSC_STD.ID%type,
    CODE col_T_DEAPRMDSC_STD.CODE%type,
    MARK      pls_integer);
  type tPrmCls is table of rPrmCls index by binary_integer;
  PrmBuf        tPrmCls;
  iBufSize      pls_integer;
  type rSearch is record (
    DCL_ID    col_T_DEAPRMRUL.DEA_ID%type,
    PRM_ID    col_T_DEAPRMRUL.PAR_ID%type,
    VALUE     col_T_DEAPRMRUL.PARVALUE%type,
    MARK      pls_integer);
  type tSearch is table of rSearch index by binary_integer;
  ValBuf        tSearch;

  function fGetParId(sCode in varchar2) return integer as
    idPar    col_T_DEAPRMDSC_STD.ID%type;
    iMinMark pls_integer:= 0;
    iMaxMark pls_integer:= 0;
    iSize    pls_integer:= PrmBuf.count;
    idx      pls_integer;
  begin
    -- Поиск среди буферизованных значений
    if iBufSize>0 then
      for i in 1..iSize loop
        if iMaxMark<PrmBuf(i).MARK then
          iMaxMark:= PrmBuf(i).MARK;
        end if;
        if PrmBuf(i).CODE=sCode then
          PrmBuf(i).MARK:= iMaxMark+1;
          return (PrmBuf(i).ID);
        elsif iSize=iBufSize and (iMinMark=0 or PrmBuf(i).MARK<iMinMark) then
          iMinMark:= PrmBuf(i).MARK;
          idx:= i;
        end if;
      end loop;
    end if;
    -- Поиск по таблице
    select id into idPar from col_T_DEAPRMDSC_STD where CODE = sCode;
    -- Буферизация
    if iBufSize>0 then
      if iSize<iBufSize then
        idx:= iSize+1;
      end if;
      PrmBuf(idx).ID:= idPar;
      PrmBuf(idx).CODE:= sCode;
      PrmBuf(idx).MARK:= iMaxMark+1;
    end if;
    return (idPar);
  exception
    when NO_DATA_FOUND then
      null; --Raise_Application_Error (-20000,LocalFrmt('Параметр продукта с кодом "%0:s" отсутствует в классификаторе параметров', vargs(sCode), 'PKG', 'T_PKGDEAPRM'));
  end;

  function GetPar(idDea in int, depDea in int, idPar in int) return varchar2 as
   cRet col_T_DEAPRM.PARVALUE%TYPE;
  begin
    select PARVALUE into cRet from col_T_DEAPRM where DEP_ID = DepDea and ID = idDea and DEA_ID = idPar;
    return cRet;
  end;


  function fClsPar(idDcl in integer, idPar in integer, sDefValue in varchar2 default null) return varchar2 as
    cRet col_T_DEAPRM.PARVALUE%TYPE;
    iMinMark pls_integer:= 0;
    iMaxMark pls_integer:= 0;
    iSize    pls_integer:= ValBuf.count;
    idx      pls_integer;
  begin
    -- Поиск среди буферизованных значений
    if iBufSize>0 then
      for i in 1..iSize loop
        if iMaxMark<ValBuf(i).MARK then
          iMaxMark:= ValBuf(i).MARK;
        end if;
        if ValBuf(i).DCL_ID=idDcl and ValBuf(i).PRM_ID=idPar then
          ValBuf(i).MARK:= iMaxMark+1;
          return (nvl(ValBuf(i).VALUE,sDefValue));
        elsif iSize=iBufSize and (iMinMark=0 or ValBuf(i).MARK<iMinMark) then
          iMinMark:= ValBuf(i).MARK;
          idx:= i;
        end if;
      end loop;
    end if;
    -- поиск по таблице
    select p.PARVALUE into cRet from col_T_DEAPRMRUL p,
      (select ID from col_T_DEACLS_STD connect by prior ID_HI = ID start with ID = idDcl) d
    where p.DEA_ID = d.ID and p.PAR_ID+0 = idPar and ROWNUM = 1;
    -- буферизация
    if iBufSize>0 then
      if iSize<iBufSize then
        idx:= iSize+1;
      end if;
      ValBuf(idx).DCL_ID:= idDcl;
      ValBuf(idx).PRM_ID:= idPar;
      ValBuf(idx).VALUE:= cRet;
      ValBuf(idx).MARK:= iMaxMark+1;
    end if;
    return (nvl(cRet,sDefValue));
  exception
    when NO_DATA_FOUND then
      return (sDefValue);
  end;

  
  function fPar (idDea in int, depDea in int, idPar in int) return varchar2 as
  /*  Получение значения параметра сделки
      Параметры: idDea    -    идентификатор сделки
                 DepDea   -    идентификатор подразделения сделки.
                 idPar    -    идентификатор параметра  */
   idDcl pls_integer;
  begin
    return GetPar(idDea, depDea, idPar);
  exception
    when NO_DATA_FOUND then begin -- в договоре такого параметра нет, ищем в шаблоне
    --t_log.WRITEL(1,'idDea='||idDea||',DepDea='||DepDea);
      select DCL_ID into idDcl from col_T_DEA where ID = idDea and DEP_ID = DepDea;
      return fClsPar(idDcl, idPar);
    end;
  end;


function fParByCode (idDea in int, depDea in int, par_code in varchar2) return varchar2 as
  idPar integer;
begin
  idPar := fGetParId(par_code);
  return col_T_PkgDeaPrm.fPar(idDea, depDea, idPar);
end;


-- Получение значения параметра договора, если не находит, то в шаблон не смотрит
function fDeaParByCode (idDea in int, depDea in int, par_code in varchar2) return varchar2 as
begin
  return GetPar(idDea, depDea, fGetParId(par_code));
exception
  when NO_DATA_FOUND then -- в договоре такого параметра нет, в шаблоне не ищем
    return null;
end;

function fDeaParByCode (rDea in col_GL_ANL.rAnlKey, par_code in varchar2) return varchar2 as
begin
  return fDeaParByCode(to_number(rDea.PK2), to_number(rDea.PK1), par_code);
end;

begin
  -- Initialization
  iBufSize:= 20; --nvl(C_fPrm('IBUFFERSIZE'),20);;
end col_T_PkgDeaPrm;
/

