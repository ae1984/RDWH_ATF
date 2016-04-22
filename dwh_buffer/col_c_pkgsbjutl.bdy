create or replace package body dwh_buffer.col_C_PKGSBJUTL is

  function fValue (
    p_Sbj in integer,              -- ППО (ссылка)
    p_Prc in integer default null, -- процесс (ссылка), может не пердаваться, если не нужно зачитывать и если задан p_Bop
    p_Jrn in integer default null, -- операция (номер в журнале), по умолчанию без контекста операции, только общее для процесса
    p_Bop in integer default null, -- сценарий (ссылка), по умолчанию зачитывается из процесса
    p_Read in integer default 0,   -- признак (1/0), зачитывать ППО (1) или брать из памяти (0)
    p_Nop in integer default null, -- номер операции по сценарию - нужен только при наличии ППО, увязанных с атрибутами операции
    p_Raise in integer default 0   -- признак поднятия ошибки в случае, когда ППО не присвоено
  ) return varchar2 as
    idBop   pls_integer:= p_Bop;
    nOp     pls_integer:= p_Nop;
    cBsName varchar2(10);
    cRet    varchar2(500);
  begin
    if idBop is null and nOp is null then -- информации по сценарию нет
      if p_Jrn is not null and p_Prc is not null then -- передана ссылка на журнал операций
        select BOP_ID,NOPER into idBop,nOp from col_T_OPERJRN where ID=p_Prc and NJRN=p_Jrn;
      elsif p_Prc is not null then -- передана только ссылка на процесс
        select BOP_ID into idBop from col_T_PROCESS where ID=p_Prc;
      end if;
    elsif nOp is null and p_Jrn is not null then -- нет только информации по операции, но есть ссылка на журнал
      select NOPER into nOp from col_T_OPERJRN where ID=p_Prc and NJRN=p_Jrn;
    end if;
    if idBop is null then -- работа с глобальным контекстом
      if SbjConceptList.exists(p_Sbj) then
        cRet:= SbjConceptList(p_Sbj);
      else
        --C_PkgErr.pRegMsg(1444,'%0=>'||C_PkgSbjArea.fGetCptName(p_Sbj),'1');
        null;
      end if;
    else -- работа с конкретным сценарием
      cBsName:= 'BP$'||to_char(idBop);
      if p_Read=1 and p_Prc is not null then -- зачитывание контекста процесса
        --execute immediate 'begin '||cBsName||'.LoadConcept(:p1,:p2); end;' using p_Prc, p_Jrn;
        save_debug_log('col_C_PKGSBJUTL.fValue 1');
      end if;
      --execute immediate 'begin :v1 := '||cBsName||'.GetSbjVal(:p1,:p2,:p3,CurOp=>'||cBsName||'.journal$); end;' using out cRet, p_Sbj, nOp, p_Raise;
      save_debug_log('col_C_PKGSBJUTL.fValue 2');
    end if;
    return (cRet);
  end;
  
  -- Извлечение значения ППО из списка. Ругается если его там нет
  function fGetItem (rProc in rUsedProcess, idSbj in integer) return varchar2 as
  begin
    return (fValue (idSbj,rProc.PROC_ID,rProc.NJRN,rProc.BOP_ID,rProc.READFL,rProc.NOPER,1));
  end;
  
begin
  -- Initialization
  null;
end col_C_PKGSBJUTL;
/

