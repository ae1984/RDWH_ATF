create or replace package body dwh_buffer.col_C_PKGDECTBL is
  -- внутренний тип для передачи атрибутов в расчетную функцию
  type tAttrList is table of varchar2(250) index by binary_integer;

  function fCmp(sType in char, sAttrVal in varchar2, sV in varchar2, sLV in varchar2, sRV in varchar2) return boolean as
    Result boolean := True;
    bExclude boolean;
    sCond  varchar2(250);
    sVal   varchar2(250);
    i pls_integer;
  begin
    if sType = 'C' then -- Условие
      Result := sAttrVal = sV;
    elsif sType = 'T' then -- Текст
      bExclude:= substr(sV,1,1)='*';
      if bExclude then
        sCond:= substr(sV,2);
      else
        sCond:= sV;
        Result:= false;
      end if;
      i:= 1;
      loop
        sVal:= col_C_pkgString.fToken2(sCond,i,',');
        exit when sVal is null;
        if sAttrVal=sVal then
          Result:= not bExclude;
          exit;
        end if;
        i:= i+1;
      end loop;
    elsif sType = 'E' then -- Множество
      --t_log.WRITEL(p_debug,'498  C_PkgString.fChkCond sV='||sV||' replace(sAttrVal='||replace(sAttrVal, '''', ''));
      Result := col_C_PkgString.fChkCond(sV, replace(sAttrVal, '''', ''));
    elsif sType = 'G' then -- Маска
      if NVL(sV,'') = NVL(sAttrVal,'') then
        Result := true;
      else
        Result := col_C_PkgString.fChkCond(sAttrVal,sV);
      end if;
    else
      if sV is not null then
        if sType in ('S','I','N') then -- Сумма
          Result := col_From_money(sV) = col_From_money(sAttrVal);
        elsif sType = 'D' then -- Дата
          Result := TO_DATE(sV) = TO_DATE(sAttrVal);
        elsif sType = 'M' then -- Врем
          Result := TO_DATE(sV, 'hh24:mi:ss') = TO_DATE(sAttrVal, 'hh24:mi:ss');
        elsif sType = 'F' then -- количество
          Result := TO_NUMBER(sV) = col_From_money(sAttrVal);
        end if;
      else
        if sLV is not null then
          if sType in ('S','I','N') then -- Сумма
            Result := col_From_money(sLV) < col_From_money(sAttrVal);
          elsif sType = 'D' then -- Дата
            Result := TO_DATE(sLV) < TO_DATE(sAttrVal);
          elsif sType = 'M' then -- Врем
            Result := TO_DATE(sLV, 'hh24:mi:ss') < TO_DATE(sAttrVal, 'hh24:mi:ss');
          elsif sType = 'F' then -- количество
            Result := col_From_money(sLV) < TO_NUMBER(sAttrVal);
          end if;
        end if;
        if sRV is not null then
          if sType in ('S','I','N') then -- Сумма
            Result := Result and col_From_money(sAttrVal) <= col_From_money(sRV);
          elsif sType = 'D' then -- Дата
            Result := Result and TO_DATE(sAttrVal) <= TO_DATE(sRV);
          elsif sType = 'M' then -- Врем
            Result := Result and TO_DATE(sAttrVal, 'hh24:mi:ss') <= TO_DATE(sRV, 'hh24:mi:ss');
          elsif sType = 'F' then -- количество
            Result := Result and TO_NUMBER(sAttrVal) <= col_From_money(sRV);
          end if;
        end if;
      end if;
    end if;
    return nvl(Result, false);
  exception
    when others then
      --t_log.writel(1, 'TYPE=>'||sType||', VALUE=>'||sAttrVal||', EXACT=>'||sV||', LEFT=>'||sLV||', RIGHT=>'||sRV);
      null;
      raise;
  end;
  
  -- основная решающая функция.
  function DecisionMainFnc(idTbl in integer, pAttrList in tAttrList, bFirst in boolean) return tDecisionList as
    bDecision boolean;
    Result tDecisionList;
    i pls_integer := 1;
    sAttrVal varchar2(250);
    AttrList tAttrList;
  begin
    AttrList := pAttrList;
    --t_log.WRITEL(p_debug,'idTbl =  '||idTbl);
    for rec in (select NORD from  col_C_TBLCOL_STD where ID = idTbl) loop
      if not AttrList.exists(rec.NORD) then
        AttrList(rec.NORD) := null;
      end if;
    end loop;
    for Row in (select ID, NORD, NPP, LONGNAME, SOLUTION from col_CV_TBLROW where ID = idTbl order by NPP) loop
      bDecision := True;
      for rec in (select c.ATR_TYPE, v.EX_VALUE, v.LF_VALUE, v.RG_VALUE, c.NORD from col_C_TBLVAL v, col_C_TBLCOL_STD c
        where v.ID = c.ID and v.NORD_COL = c.NORD and V.ID = Row.ID and v.NORD = Row.NORD
      ) loop
        sAttrVal  := AttrList(rec.NORD);
          --t_log.WRITEL(p_debug,'561 =  rec.ATR_TYPE='||rec.ATR_TYPE||' sAttrVal='||sAttrVal||' rec.EX_VALUE='||rec.EX_VALUE);
        if not fCmp(rec.ATR_TYPE, sAttrVal, rec.EX_VALUE, rec.LF_VALUE, rec.RG_VALUE) then
          bDecision := False;
          Exit;
        end if;
      end loop;
      if bDecision then
        Result(i).NPP := Row.NPP;
        Result(i).NORD := Row.NORD;
        Result(i).LONGNAME := Row.LONGNAME;
        Result(i).SOLUTION := Row.SOLUTION;
        --if T_Log.IsEnabled then
        --T_log.writel(P_Debug,LocalFrmt('>>  Результат по таблице решений: %0:s (%1:s)', vargs(Result(i).SOLUTION, Result(i).LONGNAME), 'PKG', 'C_PKGDECTBL'));
        --end if;
        i := i+1;
        exit when bFirst;
      end if;
    end loop;
    return Result;
  end;
  
    

  function SbjToInternalList(idTbl in integer, rUP in col_C_PkgSbjUtl.rUsedProcess) return tAttrList as
    Result tAttrList;
    sTmp varchar2(250);
    iReadFl pls_integer;
  begin
    iReadFl := rUP.READFL;
    /*if T_Log.IsEnabled then
      T_log.writel(P_Debug,LocalFrmt(
        '>   Значения ППО, переданные в таблицу решений "%0:s":', vargs(fTblName(idTbl)),'PKG', 'C_PKGDECTBL'));
    end if;*/
    for rec in (select NORD, SBJ_ID from col_C_TBLCOL_STD where ID = idTbl) loop
      sTmp := col_C_PkgSbjUtl.fValue(rec.SBJ_ID, rUp.PROC_ID, rUP.NJRN, rUP.BOP_ID, iReadFl, rUp.NOPER, 0);
      iReadFl := 0; -- после первоначального зачитывания можно сбросить флажок...
      --T_log.writel(P_Debug,'>     "'||C_PkgSbjArea.fGetCptName(rec.SBJ_ID)||'" = "'||sTmp||'"');
      Result(rec.NORD) := sTmp;
    end loop;
    return Result;
  end;
  
  function fSbjDecision(idTbl in integer, rUP in col_C_PkgSbjUtl.rUsedProcess, bFirst in boolean) return tDecisionList as
  begin
    return DecisionMainFnc(idTbl,SbjToInternalList(idTbl, rUP), bFirst);
  end;  

begin
  -- Initialization
  null;
end col_C_PKGDECTBL;
/

