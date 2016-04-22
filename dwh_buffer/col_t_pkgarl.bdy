create or replace package body dwh_buffer.col_t_pkgarl is

  function fMethPrm(idClc in integer, cMeth in char, cCode in varchar) return varchar2 is
    cRet col_T_ARLMETHPRM.VALUE%type;
  begin
    select VALUE into cRet from col_T_ARLMETHPRM where ID = idClc and METH = cMeth and PAR_CODE = cCode;
    return cRet;
  exception when no_data_found then return null;
  end;
  -- Обработка значения по умолчанию параметра метода расчета или распределения
  -- для корректного отображения на клиенте (виды сумм шаблонов продуктов)
  function fCorrectParDefValue(sValue in varchar2, sType in char) return varchar2
    as
  begin
    if sType in ('B', 'C') then
      return trim(translate(sValue, '''', ' '));
    else
      return sValue;
    end if;
  end;
  
  -- значение %-й ставки для вывода на клиенте
  -- iRaiseFl - признак поднятия сообщения об ошибке,
  -- 0 - подавить сообщение об ошибке, в этом случае функция вернет null
  function fPcnVal(idDep in integer, idOrd in integer, idPcn in integer, dPcn in date default P_OPERDAY,
  iReadFl in integer default 1, iRaiseFl in integer default 1) return float as
    fPrc float;
    --dPcn date;
    rUP col_C_PkgSbjUtl.rUsedProcess; --PROC_ID integer, NJRN integer, BOP_ID integer, NOPER integer, READFL integer
  begin
    if idPcn is null then
      return null;
    end if;
    begin
      select p.ID, p.BOP_ID, iReadFl into rUP.PROC_ID, rUp.BOP_ID, rUP.READFL
        from col_T_PROCMEM p, col_T_DEA d where d.DEP_ID = p.DEP_ID and d.ID = p.ORD_ID and p.MAINFL = '1'
          and d.DEP_ID = idDep and d.ID = idOrd;
      col_T_PkgPcnClc.GetPercentValue(idPcn, dPcn, rUP, fPrc);
      return fPrc;
    exception
      when OTHERS then
        if iRaiseFl = 1 then
          raise;
        else
          return null;
        end if;
    end;
  end;

  
  function fPcnValFix(idDep in integer, idOrd in integer, nCLC_ID in number
    , dPcn in date, iReadFl in integer default 1, iRaiseFl in integer default 1) return float as
    fPrc float;
    rUP col_C_PkgSbjUtl.rUsedProcess; --PROC_ID integer, NJRN integer, BOP_ID integer, NOPER integer, READFL integer
    dFrom date;
    nDayCnt number(10);
    idPcn number(10);
    cSpecFl char(1);
    cPcnFixFl char(1);
    dTo date;
    cTimePer char(1);
    nPerCnt number; nPeriod integer;
    dFix date;
  begin
    -- Признак фиксации ставки берем с настройки продукта, так как при индивидуальной ставке в договор он не копируется
    select c.PCN_ID, nvl(c.INDIVIDUAL,'0'), nvl(cc.PCNFIXFL,'0')
      into idPcn, cSpecFl, cPcnFixFl
    from col_T_ARLCLC cc, col_T_ARLCLS ac, col_T_ARLCLC c, col_T_DEA d, col_T_ARLDEA ad
    where ad.CLC_ID=nCLC_ID and ad.DEP_ID=idDep and ad.ORD_ID=idOrd
      and d.DEP_ID=ad.DEP_ID and d.ID=ad.ORD_ID
      and c.ID=ad.CLC_ID
      and ac.DCL_ID=d.DCL_ID and cc.ID=ac.CLC_ID and cc.ARL_ID=c.ARL_ID;

    if idPcn is null then
      return null;
    end if;

    select m.ID, m.BOP_ID, iReadFl, d.FROMDATE into rUP.PROC_ID, rUp.BOP_ID, rUP.READFL, dFrom
    from col_T_PROCMEM m, col_T_DEA d where d.DEP_ID = idDep and d.ID = idOrd
      and m.MAINFL = '1' and d.DEP_ID=m.DEP_ID and d.ID=m.ORD_ID;

    if col_T_BsPcn.fSpec(idPcn)=1 then
      dFrom := P_OPERDAY;
    elsif nvl(cPcnFixFl,'0')='1' then
      --
      -- Выриант старого метода с фиксацией по дням
      --
      begin
        select nvl(VALUE,0) into nDayCnt from col_T_ARLMETHPRM
        where ID=nCLC_ID and PAR_CODE='DAYCNT' and nvl(ARCFL,'0')='0';
        --t_log.WRITEL(col_P_DEBUG,'nDayCnt->'||nDayCnt);
      exception
        when NO_DATA_FOUND then
          nDayCnt := 0;
      end;
      if nDayCnt != 0 then
        dTo:=dFrom;
        dFix := col_T_PkgDeaPrm.fParByCode(idOrd, idDep, 'D_FIXDATE');
        if dFix is null then
          while dTo < P_OPERDAY loop
            dTo := dTo + nDayCnt;
          end loop;
          if dTo = P_OPERDAY then
            dFrom := dTo;
          else
            dFrom := dTo-nDayCnt;
          end if;
        elsif dFrom <= dFix then
          while dTo < dFix loop
            dTo := dTo + nDayCnt;
          end loop;
          if dTo = dFix then
            dFrom := dTo;
          else
            dFrom := dTo-nDayCnt;
          end if;
        end if;
      else
        --
        -- Новый метод с выбором типа периода
        --
        cTimePer := fMethPrm(nCLC_ID, '1', 'CTIMEPER');
        if cTimePer is not null then
          dTo:=dFrom;
          nPerCnt := fMethPrm(nCLC_ID, '1', 'NCNT');
          -- Расчет длительности периода фиксации
          if cTimePer = 'D' then
            nPeriod := nvl(nPerCnt,0)/30;
          elsif cTimePer = 'M' then
            nPeriod := nvl(nPerCnt,0);
          else
            --Raise_Application_Error(-20001, Localize('Значение справочника Тип периода ставки фиксации "' || cTimePer || '" не поддерживается. Поддерживаются только значения "D" и "M".'));
            null;
          end if;
          dFrom := add_months(dFrom, trunc(months_between(P_OperDay, dFrom)/nPeriod)*nPeriod);
        end if;
      end if;
    else
      dFrom := P_OPERDAY;
    end if;
    begin
      col_T_PkgPcnClc.GetPercentValue(idPcn, dFrom, rUP, fPrc);
      return fPrc;
    exception
      when OTHERS then
        if iRaiseFl = 1 then
          raise;
        else
          return null;
        end if;
    end;
  end;


begin
  -- Initialization
  null;
end col_t_pkgarl;
/

