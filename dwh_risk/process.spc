create or replace package dwh_risk.PROCESS is

  -- Author  : ALEXEY-YE
  -- Created : 03.07.2015 13:17:09
  -- Purpose : 
  
  procedure CREDIT_PROSROCHKA_TOMAIL;
  
  procedure table_refresh(src varchar2, dest varchar2);
  
  --procedure get_credit_portfolio ;
  --procedure get_credit_portfolio2 (v_dt date) ;
  --procedure get_credit_portfolio3 (v_f varchar2);
  procedure get_credit_portfolio4 (v_f varchar2);
  procedure get_w4_bal (v_dt date, v_ows_client_id  number) ;

  procedure GSVP_parsing;
  
  procedure FCB_parsing_1;
  procedure FCB_parsing_2;
  procedure FCB_parsing_3;
  procedure FCB_parsing_4_1;
  procedure FCB_parsing_4_2;
  function Fill_Info(
                       p_errcode in number default null,
                       p_errmsg in varchar2 default null,
                       p_err_stack in varchar2 default null,
                       p_err_call_st in varchar2 default null,
                       p_err_backtr in varchar2 default null
                       ) return xmltype deterministic parallel_enable;
  procedure AR; 
  procedure DCA_MAX;  
  procedure get_dp_covd2_v2;   
  procedure get_loyal_of_cp;                 
end PROCESS;
/

