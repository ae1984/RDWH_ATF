create or replace package dwh_risk.LOANS_OVERDUE is
  -- Author  : YURIY-KH
  -- Created : 24.07.15 24.07.15 
  procedure get_loans_overdue_test_mail;
  procedure get_loans_overdue_short_mail;
  procedure get_loans_overdue_full_mail;
  procedure get_loans_overdue_stat (p_to in smtp_mail.t_email_tab, p_cc in smtp_mail.t_email_tab);
  
  procedure get_loans_by_vcc_grouped(business_segment_name varchar2, vcc_list in varchar2, overdue_l_days_non_incl number, overdue_u_days_incl number, rownum_to_return in number);
  procedure get_loans_by_vcc(business_segment_name varchar2, vcc_list in varchar2, overdue_l_days_non_incl number, overdue_u_days_incl number, rownum_to_return in number);
  procedure fetch_all_loans_with_overdue(/*report_date date,*/ business_segment_name varchar2, vcc_list in varchar2);
  
  function table_to_clob(p_tname in varchar2) return clob;
  function get_some_overdue_loans_as_csv(business_segment_name in varchar2, overdue_l_days_non_incl in number, overdue_u_days_incl in number,
                                         rownum_to_return in number, add_header in boolean) return clob;
  function select_to_csv(l_query in varchar2, add_header in boolean) return clob;  

  function ClobToBlob(p_clob in clob, p_csid number) return blob;
   
end LOANS_OVERDUE;
/

