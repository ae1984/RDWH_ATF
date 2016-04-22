CREATE OR REPLACE PROCEDURE DWH_RISK.EXE_FCB_INSERT (
      p_id                VARCHAR2,
      p_creditordernumber VARCHAR2,
      p_rnn               VARCHAR2,
      p_reporttypeid      VARCHAR2,
      p_reporttypename    VARCHAR2,
      p_usercode          VARCHAR2,
      p_querydate         DATE,
      p_definition        OUT CLOB)
is
  i number;
begin
    select count(id) into i from EXE_FCB where id = p_id;
    if  i<=0 then
        Insert into EXE_FCB (
           id               
           ,creditordernumber
           ,rnn              
           ,reporttypeid     
           ,reporttypename   
           ,usercode         
           ,querydate        
           ,definition       

        )
        values(
           p_id               
          ,p_creditordernumber
          ,p_rnn              
          ,p_reporttypeid     
          ,p_reporttypename   
          ,p_usercode         
          ,p_querydate        
          ,EMPTY_CLOB()
        )
        RETURNING definition INTO p_definition;
    end if;
end;
/

