create or replace package body dwh_buffer.MV_UPD_PCK is

-----------
procedure Update_every_30_min
  is
BEGIN
  DBMS_MVIEW.REFRESH(LIST => 'loan_request', METHOD => 'C');
  ETL.ImportToDWH_PRIM('loan_request');

  DBMS_MVIEW.REFRESH(LIST => 'loan_request_CLNT', METHOD => 'C');
  ETL.ImportToDWH_PRIM('loan_request_CLNT');
  --DBMS_MVIEW.REFRESH(LIST => 'MV_GENESYS_INCALL', METHOD => 'C');
  
end;
-----------
procedure Update_Every_3_hour
  is
BEGIN
  --DBMS_MVIEW.REFRESH(LIST => 'mv_call_response_report', METHOD => 'C');
  
  --DBMS_MVIEW.REFRESH(LIST => 'mv_communication_response', METHOD => 'C');
 
  --DBMS_MVIEW.REFRESH(LIST => 'v_genesys_calls_report', METHOD => 'C'); 
   null;
  
END;

end MV_UPD_PCK;
/

