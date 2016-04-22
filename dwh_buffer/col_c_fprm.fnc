create or replace function dwh_buffer.col_C_FPRM
(cCode varchar2, iDep integer default null, iUsr integer default null, iOrd in integer default null)
$if col_C_pkgPLSQL.c_OracleVersion11
$then
  return varchar2 result_cache relies_on(C_PRMVAL, C_PRMCLS_STD, C_PRMCLS_LOC) deterministic
$else
  return varchar2 deterministic
$end
/***********************************************************
 $Header:   K:\CSSB\ARCHIVE\Core\ADMFUNC\c_fPrm.sqv   1.4   May 06 2008 19:52:08   AKuterin  $

 Copyright (c) 2000 By Colvir Software Solutions. All Rights Reserved.

 Description: ���������� �������� ���������� ��������� �� ��� ����.
    C ������ ���������� ��� ������������� � �������������, �������� �� ���������.
 ���������:
   cCode - ��� ���������;
   iDep  - ID �������������;
   iUsr  - ID ������������;
   iOrd  - ����� � ������ (���������� ��� ����������-��������),
     �� ��������� ��� ������� ���������� �������� � ���� ������ ����� �������.
 Bo�����: �������� ��������� ���� null ���� ������ �� �������.
***********************************************************/
as
  ret varchar2(4000);
begin
  col_c_pPrm (cCode,ret,iDep,iUsr,iOrd);
  return (ret);
exception
  when others then
    return (null);
end col_C_FPRM;
/

