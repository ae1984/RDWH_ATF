CREATE OR REPLACE PROCEDURE DWH_RISK.EXE_PROCESS_RESULTS_INSERT (
  P_PROCESS_GUID       VARCHAR2,
  P_PROCESS_CODE       VARCHAR2,
  P_PROCESS_VERSION    number,
  P_START_DATE         date,
  P_FINISH_DATE        date,
  P_PROCESS_STATUS     VARCHAR2,
  P_SUBDIVISION        VARCHAR2,
  P_STEP_COUNTER       number,
  P_INITIATOR_CODE     VARCHAR2,
  P_PROCESS_NUM        number,
  P_PROCESS_STATUS_EXT VARCHAR2,
  P_PROCESS_XML        OUT CLOB  
)
is
  i number;
begin
    select count(1) into i from EXE_PROCESS_RESULTS where PROCESS_GUID = P_PROCESS_GUID;
    if  i<=0 then
        Insert into EXE_PROCESS_RESULTS (
           PROCESS_GUID      
          ,PROCESS_CODE      
          ,PROCESS_VERSION   
          ,START_DATE        
          ,FINISH_DATE       
          ,PROCESS_STATUS    
          ,SUBDIVISION       
          ,STEP_COUNTER      
          ,INITIATOR_CODE    
          ,PROCESS_NUM       
          ,PROCESS_STATUS_EXT
          ,PROCESS_XML       
        )
        values(
           P_PROCESS_GUID      
          ,P_PROCESS_CODE      
          ,P_PROCESS_VERSION   
          ,P_START_DATE        
          ,P_FINISH_DATE       
          ,P_PROCESS_STATUS    
          ,P_SUBDIVISION       
          ,P_STEP_COUNTER      
          ,P_INITIATOR_CODE    
          ,P_PROCESS_NUM       
          ,P_PROCESS_STATUS_EXT
          ,EMPTY_CLOB()
        )
        RETURNING PROCESS_XML INTO P_PROCESS_XML;
    end if;
end;
/

