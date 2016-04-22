create or replace package body dwh_buffer.col_G_PKGCON is

  function fCode(iId integer, iDisableNormal integer default 0) return varchar2 deterministic as
    idHi       col_G_CON_STD.ID_HI%TYPE;
    cFirstCode col_G_CON_STD.CODE%TYPE;
    cCode      col_G_CON_STD.CODE%TYPE;
  begin
    select ID_HI, CODE into idHi, cCode from col_G_CON_STD where ID=IID;
    if idHi is not null and iDisableNormal=0 then
      select CODE into cFirstCode from col_G_CON_STD where ID_HI is null start with ID=iID connect by prior ID_HI=ID;
      cFirstCode:=substr(cFirstCode||'.',1,30);
      return(replace(cCode,cFirstCode,''));
    else
      return (cCode);
    end if;
  end;

  /* Вытаскивает G_CON.ID по ENT_ID, D_1, D_2, D_3*/
  function fGetLId(idConHi in integer, IdEnt in integer, nID_1 in integer, nID_2 in integer default 0, nID_3 in integer default 0) return integer as
    iResult pls_integer;
  begin
    select C.ID into iResult from col_G_CON_STD C, col_G_CONMEM M
      where c.id = m.con_id and M.ID_OBJ = IdEnt and M.ID_1 = nID_1 and M.ID_2 = nID_2 and M.ID_3 = nID_3
        and m.chi_id=idConHi;
    return iResult;
  exception
    when NO_DATA_FOUND then
      return null;
  end;

  function fName(iId integer) return varchar2 deterministic as
    idHi       col_G_CON_STD.ID_HI%TYPE;
    cFirstCODE col_G_CON_STD.CODE%TYPE;
    cName      col_G_CON_STD.LONGNAME%TYPE;
  begin
    select ID_HI, LONGNAME into idHi, cName from col_G_CON where ID=IID;
    if idHi is not null then
      select CODE into cFirstCODE from col_G_CON_STD where ID_HI is null start with ID=iID connect by prior ID_HI=ID;
      cFirstCODE:=substr(cFirstCODE||'.',1,30);
      return(replace(cName,cFirstCODE,''));
    else return (cName);
    end if;
  end;


  /* Вытаскмвает наименовнаие по ENT_ID, D_1, D_2, D_3*/
  function fGetLName(idConHi in integer,
                     IdEnt   in integer,
                     nID_1   in integer,
                     nID_2   in integer default 0,
                     nID_3   in integer default 0,
                     cTypRet in varchar2 default 'L') return varchar2 as
    iID integer;
  begin
    iID := fGetLId(idConHi, IdEnt, nID_1, nID_2, nID_3);
    if cTypRet <> 'L' then
      if col_rsatf_trf.fGetGl('EDITANL', '1') = 1 then
        return col_fRsPeriod(nID_1, nID_2, col_G_PkgCon.fCode(idConHi), 0);
      else
        return col_G_PkgCon.fCode(iId);
      end if;
    else
      if col_rsatf_trf.fGetGl('EDITANL', '1') = 1 then
        return col_fRsPeriod(nID_1, nID_2, col_G_PkgCon.fCode(idConHi), 1);
      else
        return col_G_PkgCon.fName(iId);
      end if;
    end if;
  exception
    when NO_DATA_FOUND then
      return null;
  end;

begin
  -- Initialization
  null;
end col_G_PKGCON;
/

