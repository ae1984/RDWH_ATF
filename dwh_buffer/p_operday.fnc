create or replace function dwh_buffer.P_OperDay (iDep in integer default null, iUsr in integer default null) return date deterministic as
/****************************************************************************
  $Id: $

  Copyright (c) 2000 By Colvir Software Solutions. All Rights Reserved.

  ¬озвращает актуальный операционный день дл€ работающего пользовател€.
  параметры безразличны (присутствуют дл€ совместимости)
****************************************************************************/
begin
  --return (C_PkgSession.dOper);
  --return (trunc(sysdate)-1);
  return (null);
end;
/

