CREATE OR REPLACE PROCEDURE DWH_RISK.EXE_ScoringRBPLogs_INSERT (
  p_variant      NUMBER,  
  p_process_guid VARCHAR2,  
  p_regnumber    VARCHAR2,  
  p_status       NUMBER,  
  p_pd           NUMBER,  
  p_tenortun     NUMBER,  
  p_loanamount   NUMBER,  
  p_loanrate     NUMBER,  
  p_commorg      NUMBER,  
  p_commsupport  NUMBER,  
  p_payment      NUMBER,  
  p_irr          NUMBER,  
  p_profit       NUMBER,  
  p_isinsurance  NUMBER,  
  p_tarif        NUMBER  
)
is
  i number;
begin
    select count(1) into i from EXE_ScoringRBPLogs where variant = p_variant;
    if  i<=0 then
        Insert /*+append*/ into EXE_ScoringRBPLogs (
            variant         
           ,process_guid
           ,regnumber   
           ,status      
           ,pd          
           ,tenortun    
           ,loanamount  
           ,loanrate    
           ,commorg     
           ,commsupport 
           ,payment     
           ,irr         
           ,profit      
           ,isinsurance 
           ,tarif       
        )
        values(
            p_variant      
           ,p_process_guid 
           ,p_regnumber    
           ,p_status       
           ,p_pd           
           ,p_tenortun     
           ,p_loanamount   
           ,p_loanrate     
           ,p_commorg      
           ,p_commsupport  
           ,p_payment      
           ,p_irr          
           ,p_profit       
           ,p_isinsurance  
           ,p_tarif        
        );
    end if;
end;
/

