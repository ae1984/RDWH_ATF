create or replace package dwh_buffer.col_C_PKGSBJUTL is

  -- Author  : ALEXEY-YE
  -- Created : 28.10.2015 9:43:21
  -- Purpose : 
  type tSbjConceptList is table of varchar2(250) index by binary_integer;
  SbjConceptList tSbjConceptList; -- буфер для работы с контекстом ППО вне сценариев
  
    type rUsedProcess is record (PROC_ID integer, NJRN integer, BOP_ID integer, NOPER integer, READFL integer, DEP_ID integer, ORD_ID integer);
 
 -- Получение значения ППО в контексте заданного процесса (операции)
  -- Не забыть, что предварительно надо зачитать ППО для данного процесса,
  -- либо указать соответствующий признак при вызове функции
  -- Вызов с пустыми параметрами означает работу с глобальным контекстом SbjConceptList (см. выше)
  function fValue (
    p_Sbj in integer,              -- ППО (ссылка)
    p_Prc in integer default null, -- процесс (ссылка), может не пердаваться, если не нужно зачитывать и если задан p_Bop
    p_Jrn in integer default null, -- операция (номер в журнале), по умолчанию без контекста операции, только общее для процесса
    p_Bop in integer default null, -- сценарий (ссылка), по умолчанию зачитывается из процесса
    p_Read in integer default 0,   -- признак (1/0), зачитывать ППО (1) или брать из памяти (0)
    p_Nop in integer default null, -- номер операции по сценарию - нужен только при наличии ППО, увязанных с атрибутами операции
    p_Raise in integer default 0   -- признак поднятия ошибки в случае, когда ППО не присвоено
  ) return varchar2;
  
  -- Извлечение значения ППО из списка. Ругается если его там нет
  function fGetItem (rProc in rUsedProcess, idSbj in integer) return varchar2;

end col_C_PKGSBJUTL;
/

