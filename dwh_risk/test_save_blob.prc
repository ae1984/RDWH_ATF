CREATE OR REPLACE PROCEDURE DWH_RISK.TEST_SAVE_BLOB(
    pclob in out clob)
AS

BEGIN
  
  insert into TMP_20150710(rep) values ( empty_clob() ) returning rep into pclob;
    
  commit;
  return;
END;
/

