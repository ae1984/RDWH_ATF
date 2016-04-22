create or replace package dwh_buffer.col_t_pkgarl is

  -- Author  : ALEXEY-YE
  -- Created : 28.10.2015 9:42:21
  -- Purpose : 
  -- значение %-й ставки для вывода на клиенте
  -- iRaiseFl - признак поднятия сообщения об ошибке,
  -- 0 - подавить сообщение об ошибке, в этом случае функция вернет null
  function fPcnVal(idDep in integer, idOrd in integer, idPcn in integer, dPcn in date default P_OPERDAY,
  iReadFl in integer default 1, iRaiseFl in integer default 1) return float;
  
    
  function fPcnValFix(idDep in integer, idOrd in integer, nCLC_ID in number
    , dPcn in date, iReadFl in integer default 1, iRaiseFl in integer default 1) return float;

end col_t_pkgarl;
/

