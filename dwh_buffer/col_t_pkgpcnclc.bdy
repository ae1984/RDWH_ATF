create or replace package body dwh_buffer.col_T_PkgPcnClc is
  
 bNeedSavePcn boolean:= nvl(col_c_fPrm('INEEDSAVEPCN'),'0')='1';
  
sPcnSql varchar2(500):= 'begin
  update col_T_PCNRAT set PCNVAL= :fPcn, NEEDCLCFL= 0
  where DEP_ID= :nDep and ID= :nId and PCN_ID= :nIdPcn and FROMDATE= :dPcn;
  if SQL%NOTFOUND then
    insert into col_T_PCNRAT (DEP_ID,ID,PCN_ID,FROMDATE,PCNVAL,NEEDCLCFL)
    values (:nDep,:nId,:nIdPcn,:dPcn,:fPcn,0);
  end if;
end;';  
  
function FindPcnDetail(
iid         in col_t_pcnhst.id%type,
inver       in col_t_pcnhst.nver%type,
dfromdate   in col_t_pcnhst.fromdate%type,
rUP         in col_C_PkgSbjUtl.rUsedProcess
)return col_t_pcndtl.nord%type
as
  Decision  col_C_PkgDecTbl.tDecisionList;
  itbl_id   pls_integer;
  slongname col_t_pcndsc.longname%type;

begin

  select  tbl_id
  into    itbl_id
  from    col_t_pcnhst
  where   id=iid
  and     nver=inver
  and     fromdate=dfromdate;

  Decision := col_C_PkgDecTbl.fSbjDecision(itbl_id, rUP, True);

  if Decision.count>0 then
    Return Decision(Decision.First).NORD;
  else
    --При расчете процентной ставки "%0" (версия "%1",
    --дата ввода в действие "%2") не выполнилось ни одно из условий.
    select longname into slongname from col_t_pcndsc where id=iid and nver=inver;
    --c_pkgErr.pRegMsg(1449,'%0=>'||slongname||'%1=>'||inver||'%2=>'||to_char(dfromdate,'dd.mm.yyyy'),1);
  end if;

end;

-- получение значения %-й ставки с учетом границ
function fPrcWithCapAndFloorRate(
        fPercent   in float
      , dfromdate in col_t_pcnhst.fromdate%type
      , fcaprate   in col_t_pcnhst.caprate%type
      , ffloorrate in col_t_pcnhst.floorrate%type
      , dcapdate   in col_t_pcnhst.capdate%type default null
      , dfloordate in col_t_pcnhst.floordate%type default null
) return float as
  fResult float := fPercent;
begin
  if fcaprate is not null and (dcapdate is null or dcapdate > dfromdate) then
    fResult := least(fcaprate, fResult);
  end if;
  if ffloorrate is not null and (dfloordate is null or dfloordate > dfromdate) then
    fResult := greatest(ffloorrate, fResult);
  end if;
  return fResult;
end;

function GetPercentValue(
         iid       in col_t_pcnhst.id%type
       , inver     in col_t_pcnhst.nver%type
       , dfromdate in col_t_pcnhst.fromdate%type
       , rUP       in col_C_PkgSbjUtl.rUsedProcess
)return float
is
  fcaprate    col_t_pcnhst.caprate%type;
  dcapdate    col_t_pcnhst.capdate%type;
  ffloorrate  col_t_pcnhst.floorrate%type;
  dfloordate  col_t_pcnhst.floordate%type;
  fPercent      float;
begin
  fPercent := GetPercentValueEx(iid, inver, dfromdate, rUP, fcaprate, dcapdate, ffloorrate, dfloordate);
  return fPrcWithCapAndFloorRate(fPercent, dfromdate, fcaprate, ffloorrate, dcapdate, dfloordate);
end;

procedure GetPercentValue(
          iId      in col_t_pcn.id%type,
          dDate    in date default p_operday,
          rUP      in col_C_PkgSbjUtl.rUsedProcess,
          fPercent out float
) is
  fcaprate    col_t_pcnhst.caprate%type;
  dcapdate    col_t_pcnhst.capdate%type;
  ffloorrate  col_t_pcnhst.floorrate%type;
  dfloordate  col_t_pcnhst.floordate%type;
begin
  GetPercentValueEx(iId,dDate,rUP,fPercent,fcaprate,dcapdate,ffloorrate,dfloordate);
  fPercent := fPrcWithCapAndFloorRate(fPercent, dDate, fcaprate, ffloorrate, dcapdate, dfloordate);
end;

function GetPercentValue(
         iid         in col_t_pcnhst.id%type --id ставки
       , inver       in col_t_pcnhst.nver%type --номер версии
       , dfromdate   in col_t_pcnhst.fromdate%type
       , rUP         in col_C_PkgSbjUtl.rUsedProcess --дата начала действия значения ставки
       , nBaseSum    in number                   --База расчета
       , isbj_id     in int                      --ППО являющееся базой расчета
)return float
is
  spcn_type col_T_PCNDSC.pcn_type%type;
  iTblID    pls_integer;
  fPercent  float := 0;
  bExit     boolean;
  irnd_id   int;
  fAmount   float;
begin
  select h.tbl_id, d.pcn_type, d.rnd_id into itblid, spcn_type, irnd_ID
  from col_t_pcndsc d, col_t_pcnhst h where d.id=iid
    and d.nver=iNver and h.id=iid and h.nver=iNver
    and h.fromdate = dfromdate;

  if spcn_type<>'P' then
    --Raise_Application_Error (-20000,Localize('Метод не предназначен для расчета каких-либо типов ставки помимо прогрессивных', 'PKG', 'T_PKGPCNCLC'));
    null;
  end if;
  for rec in (select col_from_money(v.lf_value) as lf_value, col_from_money(v.rg_value) as rg_value,
                d.percent_add from col_c_tblcol_std c, col_c_tblval v, col_c_tblrow_std r, col_t_pcndtl d
                where c.id=itblid and c.sbj_id=isbj_id and v.id= itblid and v.nord_col=c.nord
                  and r.id=itblid and r.nord=v.nord and d.row_id=itblid and d.row_nord=v.nord
              order by r.npp ) loop
    bExit := (nBaseSum>= nvl(rec.lf_value,0)) and (rec.rg_value is null or nBaseSum<=rec.rg_value);
    if bExit then
      fAmount := (nBaseSum-nvl(rec.lf_value,0))*rec.percent_add/100;
    else
      fAmount := (rec.rg_value-nvl(rec.lf_value,0))*rec.percent_add / 100;
    end if;
    if irnd_id is not null and not bExit then
      --округляем, если требуетс
      fAmount := col_C_PkgRnd.Frndref(fAmount, col_p_natval, irnd_id);
    end if;
    fPercent := fPercent + fAmount;
    exit when bExit;
  end loop;
  return fPercent;
end;

function GetPercentValue(
         iid         in col_t_pcnhst.id%type        --id ставки
       , inver       in col_t_pcnhst.nver%type      --номер версии
       , dfromdate   in col_t_pcnhst.fromdate%type default p_operday  --дата начала действия значения ставки
)return float
is
  rUP col_C_PkgSbjUtl.rUsedProcess;
begin
  return( GetPercentValue( iid, inver, dfromdate, rUP ));
end;

function GetActualNver(
iid         in col_t_pcn.id%type
)return col_t_pcndsc.nver%type
is
  inver col_t_pcndsc.nver%type;
  slongname col_t_pcndsc.longname%type;
begin
  select  nver
  into    inver
  from    col_t_pcndsc
  where   id=iid
  and     ver_type=col_t_bspcn.ActVerType;

  return inver;
exception
  when no_data_found then
    begin
      --Не существует актуальной версии для новой процентной ставки "%0"
      select longname into slongname from col_t_pcndsc where id=iid and ver_type||''=col_t_bspcn.newvertype;
      --c_pkgErr.pRegMsg(1447,'%0=>'||slongname,1);
    exception
      when no_data_found then
        -- Хотя бы код ставки покажем
        select code into slongname from col_t_pcn where id=iid;
        --c_pkgErr.pRegMsg(1447,'%0=>'||slongname,1);
    end;
end;

procedure pGetRatPcn(
          nIdPcn in number
        , dPcn   in date default P_OPERDAY
        , rUP    in col_C_PkgSbjUtl.rUsedProcess
        , fPcn   out float
        , cNeed  out char
) as
begin
  select /*+ index_desc (R PK_T_PCNRAT) use_nl (R,M) */ R.PCNVAL,nvl(R.NEEDCLCFL,'0') into fPcn,cNeed from col_T_PCNRAT R, col_T_PROCMEM M
  where M.ID=rUP.PROC_ID and M.MAINFL='1' and R.DEP_ID=M.DEP_ID and R.ID=M.ORD_ID and R.PCN_ID=nIdPcn and R.FROMDATE<=dPcn and ROWNUM=1;
exception
  when NO_DATA_FOUND then
    fPcn:= null;
    cNeed:= '1';
end;


procedure pSetRatPcn(
          nIdPcn in number
        , dPcn   in date default P_OPERDAY
        , rUP    in col_C_PkgSbjUtl.rUsedProcess
        , fPcn   in float
) as
  pragma AUTONOMOUS_TRANSACTION;-- Specify Autonomous Transaction
  nDep number(10);
  nId  number(10);
begin
  select DEP_ID,ORD_ID into nDep,nId from col_T_PROCMEM
    where ID=rUP.PROC_ID  and BOP_ID=rUP.BOP_ID and MAINFL='1';
  /* Т. к. процедура GetPercentValue исспользуется в селектах на клиентских формах,
     применяем динамический SQL */
  execute immediate sPcnSql using fPcn,nDep,nId,nIdPcn,dPcn;
  commit;
  save_debug_log('col_T_PkgPcnClc.pSetRatPcn  "execute immediate" ');
exception
  when others then
    rollback;
end;

procedure GetPercentValue(
           iId      in col_t_pcn.id%type,
           dDate    in date default p_operday,
           rUP      in col_C_PkgSbjUtl.rUsedProcess,
           nBaseSum in number,
           iSbj_Id  in int,                      --ППО являющееся базой расчета
           fPercent out float
) is
  iNver     pls_integer;
  dFromdate date;
  fVal      float;
  cNeed     char(1);
begin
  iNver := GetActualNver(iId);
  select max(FROMDATE) into dFromdate from col_T_PCNHST where ID = iId and NVER = iNver and FROMDATE <= dDate;
  if dFromdate is null then
    -- ну и что тут делать? ругаться? так в запросах на клиенте вызывается...
    -- Raise_Application_Error (-20000,'В актуальной ставке нет данных на "'||ddate||'"');
    -- или дату подменить?
    -- select min(FROMDATE) into dfromdate from T_PCNHST where ID = iid and NVER = iNver;
    -- или null вернуть?
    return;
  end if;
  fPercent:= GetPercentValue(iId,iNver,dFromdate,rUP,nBaseSum,iSbj_Id);
  if bNeedSavePcn then
    pGetRatPcn (iId,dDate,rUp,fVal,cNeed);
    if (fVal is null and fPercent is not null) or fVal<>fPercent then
      col_T_PkgPcnClc.pSetRatPcn (iId,dFromdate,rUP,fPercent);
    end if;
  end if;
end;




function GetPercentValueEx(
         iid         in col_t_pcnhst.id%type
       , inver       in col_t_pcnhst.nver%type
       , dfromdate   in col_t_pcnhst.fromdate%type
       , rUP         in col_C_PkgSbjUtl.rUsedProcess
       , fcaprate    out col_t_pcnhst.caprate%type
       , dcapdate    out col_t_pcnhst.capdate%type
       , ffloorrate  out col_t_pcnhst.floorrate%type
       , dfloordate  out col_t_pcnhst.floordate%type
)return float
is
  spcn_type     col_t_pcndsc.pcn_type%type;
  iTblID        pls_integer;
  iNord         pls_integer;
  rPcnDtl       col_t_pcndtl%rowtype;
  fBasePercent  float;
  iBaseID       pls_integer;
  fpercent_mult float;
  fpercent_add  float;
  fPercent      float;
  dPcnHst       date;
  iPrcSbjId     pls_integer;
  fPrcSbj       float;
begin
  select max(FROMDATE) into dPcnHst from col_T_PCNHST where ID = iid and NVER = inver and FROMDATE <= dfromdate;
  if dPcnHst is null then
    -- ну и что тут делать? ругаться? так в запросах на клиенте вызывается...
    -- Raise_Application_Error (-20000,'В актуальной ставке нет данных на "'||ddate||'"');
    -- или дату подменить?
    -- select min(FROMDATE) into dPcnHst from T_PCNHST where ID = iid and NVER = iNver;
    -- или null вернуть?
    return null;
  end if;
  select h.tbl_id, d.pcn_type, h.Base_Id, h.percent_add, h.percent_mult, h.caprate, h.capdate, h.floorrate, h.floordate
    into itblid, spcn_type, iBaseID, fpercent_add, fpercent_mult, fcaprate, dcapdate, ffloorrate, dfloordate
  from col_t_pcndsc d, col_t_pcnhst h
    where d.id=iid and d.nver=iNver and h.id=iid
      and h.nver=iNver and h.fromdate = dPcnHst;

  if spcn_type='D' then
    iNord := FindPcnDetail(iid,inver,dPcnHst,rUP);
    select * into rPcnDtl from col_T_PCNDTL where ID=iid and NVER=iNver
      and FROMDATE = dPcnHst and ROW_NORD = iNord;
    ibaseID := rPcnDtl.base_id;
    fpercent_add := rPcnDtl.percent_add;
    fpercent_mult := rPcnDtl.percent_mult;
    iPrcSbjId := rPcnDtl.PERCENT_SBJ;
    fcaprate := rPcnDtl.caprate;
    dcapdate := rPcnDtl.capdate;
    ffloorrate := rPcnDtl.floorrate;
    dfloordate := rPcnDtl.floordate;
  end if;
  if dcapdate <= dfromdate then -- дата ограничения уже в прошлом
    fcaprate := null;
    dcapdate := null;
  end if;
  if dfloordate <= dfromdate then  -- дата ограничения уже в прошлом
    ffloorrate := null;
    dfloordate := null;
  end if;
  if iPrcSbjId is not null then
    --t_log.writel(1,'iPrcSbjId is not null');
    fPrcSbj := col_from_money(col_C_PkgSbjUtl.fGetItem(rUP, iPrcSbjId));
    fBasePercent := fPrcSbj;
  else
    if iBaseID is not null then
      GetPercentValue(iBaseid, dfromdate, rUP, fBasePercent);
    else
      fBasePercent := 100;
    end if;
  end if;
  fPercent := nvl(fBasePercent,0) * nvl(fpercent_mult,0) + nvl(fpercent_add,0);
  return fPercent;
end;

procedure GetPercentValueEx(
          iId      in col_t_pcn.id%type,
          dDate    in date default p_operday,
          rUP      in col_C_PkgSbjUtl.rUsedProcess,
          fPercent out float,
          fcaprate    out col_t_pcnhst.caprate%type,
          dcapdate    out col_t_pcnhst.capdate%type,
          ffloorrate  out col_t_pcnhst.floorrate%type,
          dfloordate  out col_t_pcnhst.floordate%type
) is
  iNver     pls_integer;
  cNeed     char(1);
  fVal      float;
begin
  iNver := GetActualNver(iId);
  fPercent:= GetPercentValueEx(iId, iNver, dDate, rUP, fcaprate, dcapdate, ffloorrate, dfloordate);
  if bNeedSavePcn then -- Смотрим есть ли данные в T_PCNRAT
    pGetRatPcn (iId,dDate,rUp,fVal,cNeed);
    if (fVal is null and fPercent is not null) or fVal<>fPercent then
      col_T_PkgPcnClc.pSetRatPcn (iId, dDate, rUP, fPercent);
    end if;
  end if;
end;

begin
  -- Initialization
  null;
end col_T_PkgPcnClc;
/

