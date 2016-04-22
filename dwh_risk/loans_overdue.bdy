create or replace package body dwh_risk.LOANS_OVERDUE is
  
  procedure get_loans_overdue_test_mail is
  p_to smtp_mail.t_email_tab;
  p_cc smtp_mail.t_email_tab;
  begin
    p_to(1):='yuriy.khramtsov@atfbank.kz';
    get_loans_overdue_stat (p_to, p_cc);
  end;

  procedure get_loans_overdue_short_mail is
  p_to smtp_mail.t_email_tab;
  p_cc smtp_mail.t_email_tab;
  begin
    p_to(1):='yuriy.khramtsov@atfbank.kz';
    p_to(2):='daniil.sokolov@atfbank.kz';
    p_to(3):='galimzhan.shishingarin@atfbank.kz';
    p_to(4):='alexey.yevseyev@atfbank.kz';
    get_loans_overdue_stat (p_to, p_cc);
  end;

  procedure get_loans_overdue_full_mail is
  p_to smtp_mail.t_email_tab;
  p_cc smtp_mail.t_email_tab;
  begin
    p_to(1):='yuriy.khramtsov@atfbank.kz';
    p_to(2):='daniil.sokolov@atfbank.kz';
    p_to(3):='galimzhan.shishingarin@atfbank.kz';
    p_to(4):='alexey.yevseyev@atfbank.kz';
    get_loans_overdue_stat (p_to, p_cc);
  end;

  procedure get_loans_overdue_stat (p_to in smtp_mail.t_email_tab, p_cc in smtp_mail.t_email_tab) is
    p_attachmentlist_blob smtp_mail.t_attachment_tab;
    p_attach_blob smtp_mail.t_attachment;
    l_er varchar2(32767);
    attachment_blob blob;
    message_blob blob;
    min_days_ovedue integer := 0;
    max_days_ovedue integer := 90;
    top_loan_number_in_category integer :=50;
  begin
    execute immediate ('truncate table DWH_RISK.loans_with_fresh_overdue'); commit;
/*    get_loans_by_vcc('corporate','104611,104612,104613,104619,104710,104714,104715,104719,106612,106714,201320',0,max_days_ovedue,top_loan_number_in_category);
    get_loans_by_vcc('private','107310,107319,999994',0,max_days_ovedue,top_loan_number_in_category);
    get_loans_by_vcc('sme','104120,104810,104815,104819,999993',0,max_days_ovedue,top_loan_number_in_category);
    get_loans_by_vcc('retail','107320,107329,107330,107340,107390,999992',0,max_days_ovedue,top_loan_number_in_category);*/

    fetch_all_loans_with_overdue('corporate','104611,104612,104613,104619,104710,104714,104715,104719,106612,106714,201320');
    fetch_all_loans_with_overdue('private','107310,107319,999994');
    fetch_all_loans_with_overdue('sme','104120,104810,104815,104819,999993');
    fetch_all_loans_with_overdue('retail','107320,107329,107330,107340,107390,999992');
    
    p_attach_blob.p_attach_name:=to_char(sysdate-1, 'yyyymmdd')||' Largest loans with fresh (up to '||to_char(max_days_ovedue)||' days) overdue.csv';
    p_attach_blob.p_attach_mime:='text/plain';

    attachment_blob := to_blob(hextoraw('EFBBBF'));  /*message_blob:=ClobToBlob(table_to_clob('loans_with_fresh_overdue'),0);*/
    message_blob:=ClobToBlob(get_some_overdue_loans_as_csv('corporate', min_days_ovedue, max_days_ovedue, top_loan_number_in_category, true)||
                             get_some_overdue_loans_as_csv('private',   min_days_ovedue, max_days_ovedue, top_loan_number_in_category, false)||
                             get_some_overdue_loans_as_csv('sme',       min_days_ovedue, max_days_ovedue, top_loan_number_in_category, false)||
                             get_some_overdue_loans_as_csv('retail',    min_days_ovedue, max_days_ovedue, top_loan_number_in_category, false),0);

    dbms_lob.append(attachment_blob,message_blob);   p_attach_blob.p_attach_blob:=attachment_blob;

    p_attachmentlist_blob(1):=p_attach_blob;
    smtp_mail.send_mail_blob(p_to, 'risk_process_automatic@atfbank.kz', 'Loans with fresh overdue', 'Please find the file attached', p_cc, l_er, p_attachmentlist_blob, 0);
  end;

  procedure get_loans_by_vcc_grouped(business_segment_name varchar2, vcc_list in varchar2, overdue_l_days_non_incl number, overdue_u_days_incl number, rownum_to_return in number) is
  vcc_list_comma varchar2 (10000);
  begin
        vcc_list_comma := ',' || vcc_list|| ',';
        insert into loans_with_fresh_overdue (business_segment_name,client_code,client_name,vcc,principal_overdue_kzt,interest_overdue_kzt,outstanding_total_kzt,days_overdue_max,principal_regular_kzt)
        (select business_segment_name,c.code,b.full_name,b.vcc,a.principal_overdue_kzt,a.interest_overdue_kzt,a.outstanding_total_kzt,a.days_overdue_max,a.principal_regular_kzt
         from (select cli_id,cli_dep_id,sum(bal_od_sum) as principal_overdue_kzt,sum(bal_prc_sum) as interest_overdue_kzt,sum(bal_reg_od_sum+bal_od_sum + bal_prc_sum) as outstanding_total_kzt,max(max_delay) as days_overdue_max,sum(bal_reg_od_sum) as principal_regular_kzt
               from copy_risk_tmp_atf_prosr_de810b a
               where bal_od_sum+bal_prc_sum>0 and a.max_delay>overdue_l_days_non_incl and a.max_delay<=overdue_u_days_incl and a.dep_id is not null
               group by cli_id,cli_dep_id) a
         left join dwh_buffer.client@dwh b on a.cli_id = b.cli_id and a.cli_dep_id = b.dep_id
         left join colvir.g_cli@reps c on a.cli_id = c.id and a.cli_dep_id = c.dep_id  
         where instr(vcc_list_comma, ','||b.vcc||',') > 0 and rownum <=rownum_to_return)
         order by outstanding_total_kzt desc;
         commit;
  end;

  procedure get_loans_by_vcc(business_segment_name varchar2, vcc_list in varchar2, overdue_l_days_non_incl number, overdue_u_days_incl number, rownum_to_return in number) is
  vcc_list_comma varchar2 (10000);
  begin
        vcc_list_comma := ',' || vcc_list|| ',';
/*        insert into loans_with_fresh_overdue (business_segment_name,client_code,client_name,vcc,principal_overdue_kzt,interest_overdue_kzt,outstanding_total_kzt,days_overdue_max,principal_regular_kzt)
        (select business_segment_name,c.code,b.short_name as client_name,b.vcc,a.principal_overdue_kzt,a.interest_overdue_kzt,a.outstanding_total_kzt,a.days_overdue_max,a.principal_regular_kzt
         from (select cli_id,cli_dep_id,bal_od_sum as principal_overdue_kzt,bal_prc_sum as interest_overdue_kzt,bal_reg_od_sum+bal_od_sum + bal_prc_sum as outstanding_total_kzt,max_delay as days_overdue_max,bal_reg_od_sum as principal_regular_kzt
               from copy_risk_tmp_atf_prosr_de810b a
               where bal_od_sum+bal_prc_sum>0 and a.max_delay>overdue_l_days_non_incl and a.max_delay<=overdue_u_days_incl and a.dep_id is not null) a
         left join dwh_buffer.client@dwh b on a.cli_id = b.cli_id and a.cli_dep_id = b.dep_id
         left join colvir.g_cli@reps c on a.cli_id = c.id and a.cli_dep_id = c.dep_id  
         where instr(vcc_list_comma, ','||b.vcc||',') > 0 and rownum <=rownum_to_return)
         order by outstanding_total_kzt desc;
         commit;*/

        insert into loans_with_fresh_overdue (business_segment_name,client_code,client_name,loan_code,vcc,outstanding_total_kzt,
                                              principal_regular_kzt,principal_overdue_kzt,interest_overdue_kzt,days_overdue_max)
              (select business_segment_name,c.code,b.short_name,d.code,b.vcc,a.bal_reg_od_sum+a.bal_od_sum+a.bal_prc_sum,
                        a.bal_reg_od_sum,a.bal_od_sum,a.bal_prc_sum,a.max_delay
               from copy_risk_tmp_atf_prosr_dea818 a, dwh_buffer.client@dwh b, colvir.g_cli@reps c, colvir.t_ord@reps d
               where a.bal_od_sum+a.bal_prc_sum>0 and
                     a.max_delay>overdue_l_days_non_incl and a.max_delay<=overdue_u_days_incl and
                     a.dep_id is not null and 
                     a.cli_dep_id = b.dep_id and a.cli_id = b.cli_id and
                     a.cli_dep_id = c.dep_id and a.cli_id = c.id and
                     a.dep_id = d.dep_id and a.id = d.id and instr(vcc_list_comma, ','||b.vcc||',') > 0 /*and
                     rownum <=rownum_to_return*/)
               order by a.bal_reg_od_sum+a.bal_od_sum+a.bal_prc_sum desc;
         commit;
  end; 

  procedure fetch_all_loans_with_overdue(/*report_date date,*/ business_segment_name varchar2, vcc_list in varchar2) is
  vcc_list_comma varchar2(1000);
  begin
        vcc_list_comma := ',' || vcc_list|| ',';
        insert into loans_with_fresh_overdue (business_segment_name,client_code,client_name,loan_code,vcc,outstanding_total_kzt,
                                              principal_regular_kzt,principal_overdue_kzt,interest_overdue_kzt,days_overdue_max)
              (select business_segment_name,c.code,b.short_name,d.code,b.vcc,a.bal_reg_od_sum+a.bal_od_sum+a.bal_prc_sum,
                        a.bal_reg_od_sum,a.bal_od_sum,a.bal_prc_sum,a.max_delay
               from copy_risk_tmp_atf_prosr_dea818 a, dwh_buffer.client@dwh b, colvir.g_cli@reps c, colvir.t_ord@reps d
               where (a.bal_od_sum>0 or a.bal_prc_sum>0) and /*or*/ a.max_delay>0 and
                     a.cli_dep_id is not null and a.cli_id is not null and
                     a.cli_dep_id = b.dep_id and a.cli_id = b.cli_id and
                     a.cli_dep_id = c.dep_id and a.cli_id = c.id and
                     a.dep_id = d.dep_id and a.id = d.id and instr(vcc_list_comma, ','||b.vcc||',') > 0);
         commit;
  end; 

  function table_to_clob( p_tname in varchar2) return clob is
  output clob;
  l_theCursor     integer default dbms_sql.open_cursor;
  l_columnValue   varchar2(4000);
  l_status        long;
  l_query         varchar2(1000) default 'select * from ' || p_tname|| ' order by business_segment_name, outstanding_total_kzt desc';
  l_colCnt        number := 0;
  l_separator     varchar2(1);
  l_descTbl       dbms_sql.desc_tab;
  begin
    dbms_sql.parse(l_theCursor,  l_query, dbms_sql.native);
    dbms_sql.describe_columns(l_theCursor, l_colCnt, l_descTbl);
    for i in 1 .. l_colCnt loop
      output:=output||l_separator || '"' || l_descTbl(i).col_name || '"';
      dbms_sql.define_column( l_theCursor, i, l_columnValue, 4000 );
      l_separator := ';';
    end loop;
    output:=output||chr(13)||chr(10);
    l_status := dbms_sql.execute(l_theCursor);
    while ( dbms_sql.fetch_rows(l_theCursor) > 0 ) loop
      l_separator := '';
      for i in 1 .. l_colCnt loop
        dbms_sql.column_value( l_theCursor, i, l_columnValue );
        output:=output||l_separator || l_columnValue;
        l_separator := ';';
      end loop;
      output:=output||chr(13)||chr(10);
    end loop;
    dbms_sql.close_cursor(l_theCursor);
    return output;
  exception when others then raise;
  end;

  function get_some_overdue_loans_as_csv(business_segment_name in varchar2, overdue_l_days_non_incl in number, overdue_u_days_incl in number,
                                         rownum_to_return in number, add_header in boolean) return clob is
  l_query varchar2(2000);
  begin
    l_query := 'select * from (select * from loans_with_fresh_overdue where business_segment_name = '''||business_segment_name||'''
                and days_overdue_max > '||overdue_l_days_non_incl||' and days_overdue_max <= '||overdue_u_days_incl||
               ' order by outstanding_total_kzt desc) where rownum <= '||rownum_to_return;

    return select_to_csv(l_query, add_header);
  end;
 
  function select_to_csv(l_query in varchar2, add_header in boolean) return clob is
  output clob;
  l_theCursor     integer default dbms_sql.open_cursor;
  l_columnValue   varchar2(4000);
  l_status        long;
--  l_query         varchar2(1000) default 'select * from ' || p_tname|| ' order by business_segment_name, outstanding_total_kzt desc';
  l_colCnt        number := 0;
  l_separator     varchar2(1);
  l_descTbl       dbms_sql.desc_tab;
  begin
    dbms_sql.parse(l_theCursor,  l_query, dbms_sql.native);
    dbms_sql.describe_columns(l_theCursor, l_colCnt, l_descTbl);
    
    for i in 1 .. l_colCnt loop
      if add_header = true then output:=output||l_separator || '"' || l_descTbl(i).col_name || '"'; end if;
      dbms_sql.define_column( l_theCursor, i, l_columnValue, 4000 );
      l_separator := ';';
    end loop;
    if add_header = true then output:=output||chr(13)||chr(10); end if;
    
    l_status := dbms_sql.execute(l_theCursor);
    while ( dbms_sql.fetch_rows(l_theCursor) > 0 ) loop
      l_separator := '';
      for i in 1 .. l_colCnt loop
        dbms_sql.column_value( l_theCursor, i, l_columnValue );
        output:=output||l_separator || l_columnValue;
        l_separator := ';';
      end loop;
      output:=output||chr(13)||chr(10);
    end loop;
    dbms_sql.close_cursor(l_theCursor);
    return output;
  exception when others then raise;
  end;
  
  function ClobToBlob(p_clob in clob, p_csid number) return blob is
   l_dest_offset   integer := 1;
   l_source_offset integer := 1;
   l_lang_context  integer := DBMS_LOB.DEFAULT_LANG_CTX;
   l_warning       integer := DBMS_LOB.WARN_INCONVERTIBLE_CHAR;
   l_tmpblob blob;
  begin
    dbms_lob.createtemporary(l_tmpblob, true);
    DBMS_LOB.CONVERTTOBLOB(l_tmpblob,p_clob,DBMS_LOB.LOBMAXSIZE,l_dest_offset,l_source_offset,p_csid,l_lang_context,l_warning);
    return l_tmpblob;
  end;
  
begin
  null;
end LOANS_OVERDUE;
/

