create or replace function dwh_buffer.col_P_NatVal (iDep in integer default null, iUsr in integer default null) return integer deterministic as
/****************************************************************************
  $Id: $

  Copyright (c) 2000 By Colvir Software Solutions. All Rights Reserved.

  ���������� ������������� ������������ ������ ��� ������������
  �������� ������������� ������������ ������������ ��� �������������
****************************************************************************/
begin
  return (col_C_PkgSession.idNatVal);
end;
/

