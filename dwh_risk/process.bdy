create or replace package body dwh_risk.PROCESS is
procedure SetColvirNlsParams -- Можно работать с данными nls параметрами, это нам погоды не сделает
  as
BEGIN
  dbms_session.Set_Nls ('nls_language', 'RUSSIAN');
  dbms_session.Set_NLS ('nls_territory','CIS');
  dbms_session.Set_NLS ('nls_numeric_characters','''.,''');
  dbms_session.Set_NLS ('nls_date_format','''DD.MM.RR''');
  dbms_session.Set_NLS ('nls_sort','BINARY');
  commit;
END;


procedure SetDwhNlsParams
  as
BEGIN
  dbms_session.Set_Nls('nls_language', 'RUSSIAN');
  dbms_session.Set_NLS ('nls_territory','CIS');
  dbms_session.Set_NLS ('nls_numeric_characters',''',''');
  dbms_session.Set_NLS ('nls_date_format','''DD.MM.RR''');
  dbms_session.Set_NLS ('nls_sort','BINARY');
  commit;
END;

function Fill_Info(
                       p_errcode in number default null,
                       p_errmsg in varchar2 default null,
                       p_err_stack in varchar2 default null,
                       p_err_call_st in varchar2 default null,
                       p_err_backtr in varchar2 default null
                       ) return xmltype deterministic parallel_enable
 is
l_result xmltype;
begin
  select
  XMLROOT(
   xmlelement("root",
    xmlelement("action"
     ,case when p_errcode is not null then
      xmlelement("error",xmlattributes(p_errcode as "sqlcode",p_errmsg as "sqlerrm")
       ,xmlelement("stacktrace",p_err_stack)
       ,xmlelement("callstack",p_err_call_st)
       ,xmlelement("backtrace",p_err_backtr)
      )
      end
    )
   )
  ,VERSION '1.0', STANDALONE YES)
  into l_result
  from dual
  ;
  return l_result;
end;


function CREDIT_PROSROCHKA_CSV(dt date, filtr varchar2, filtr1 varchar2, a number, b number) return clob
is
   cursor c is
/*   select
          'Код клиента;'
          ||'Номер контракта;'
          ||'ФИО;'
          ||'Выход на просрочку;'
          ||'Кол-во дней просрочки;'
          ||'Тип клиента;'
          ||'Период;'
          ||'статус контракта;'
          ||'ОД;'
          ||'Просроченный ОД;'
          ||'Оплаченный ОД;'
          ||'Остаток по ОД;'
          ||'Вся просроченная сумма;'
          ||'Сумма всех платижей;'
          ||'Всего к оплате'
          ||chr(13)||chr(10)||chr(13)||chr(10)
          as txt
   from dual
   union all
   select
          t.cli_code||';'
          ||t.contract_num||';'
          ||t.full_name||';'
          ||to_char(t.dt_vznosa_plan,'dd.mm.yyyy')||';'
          ||to_char(t.dni_prosrochki)||';'
          ||t.cl_type||';'
          ||t.period||';'
          ||t.state||';'
          ||to_char(t.od)||';'
          ||to_char(t.od_prosroch)||';'
          ||to_char(t.od_paid)||';'
          ||to_char(t.od_ost)||';'
          ||to_char(t.amt_p)||';'
          ||to_char(t.paid)||';'
          ||to_char(t.amt_plan)
          ||chr(13)||chr(10)
          as txt
   from CREDIT_PROSROCHKA_TOMAIL t
   where t.sdt = dt
   ;*/


/*   select '<!DOCTYPE html>
          <html>
             <head>
                <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
             </head>
             <body>
             <table border="1">' as txt
   from dual
   union all
   select   '<tr>'
          ||'<td>Код клиента;</td>'
          ||'<td>Номер контракта;</td>'
          ||'<td>ФИО;</td>'
          ||'<td>Выход на просрочку;</td>'
          ||'<td>Кол-во дней просрочки;</td>'
          ||'<td>Тип клиента;</td>'
          ||'<td>Период;</td>'
          ||'<td>статус контракта;</td>'
          ||'<td>ОД;</td>'
          ||'<td>Просроченный ОД;</td>'
          ||'<td>Оплаченный ОД;</td>'
          ||'<td>Остаток по ОД;</td>'
          ||'<td>Вся просроченная сумма;</td>'
          ||'<td>Сумма всех платижей;</td>'
          ||'<td>Всего к оплате</td>'
          ||'</tr>'
          ||chr(13)||chr(10)||chr(13)||chr(10)
          as txt
   from dual
   union all
   select txt from
   (select   '<tr>'
          ||'<td>'||t.cli_code||'</td>'
          ||'<td>'||t.contract_num||'</td>'
          ||'<td>'||t.full_name||'</td>'
          ||'<td>'||to_char(t.dt_vznosa_plan,'dd.mm.yyyy')||'</td>'
          ||'<td>'||to_char(t.dni_prosrochki)||'</td>'
          ||'<td>'||t.cl_type||'</td>'
          ||'<td>'||t.period||'</td>'
          ||'<td>'||t.state||'</td>'
          ||'<td>'||to_char(t.od)||'</td>'
          ||'<td>'||to_char(t.od_prosroch)||'</td>'
          ||'<td>'||to_char(t.od_paid)||'</td>'
          ||'<td>'||to_char(t.od_ost)||'</td>'
          ||'<td>'||to_char(t.amt_p)||'</td>'
          ||'<td>'||to_char(t.paid)||'</td>'
          ||'<td>'||to_char(t.amt_plan)||'</td>'
          ||'</tr>'
          ||chr(13)||chr(10)
          as txt
   from CREDIT_PROSROCHKA_TOMAIL t
   where t.sdt = dt and t.cl_type = filtr
   order by t.period desc, t.od_ost desc)
   union all
   select '</table>
           </body>
           </html> ' as txt
   from dual
   ;*/


   select '<!DOCTYPE html>
          <html>
             <head>
                <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
             </head>
             <body>
             <table border="1">' as txt
   from dual
   union all
   select   '<tr>'
          ||'<td>Филиал</td>'
          ||'<td>Код клиента</td>'
          ||'<td>Наименование клиента</td>'
          ||'<td>Номер договора</td>'
          ||'<td>ОД не просроченный</td>'
          ||'<td>ОД просроченный</td>'
          ||'<td>% не просроченный</td>'
          ||'<td>% просроченный</td>'
          ||'<td>Итого ОД + %</td>'
          ||'<td>Диапазон просрочки</td>'
          ||'<td>Кол-во дней просрочки</td>'

          ||'</tr>'
          ||chr(13)||chr(10)||chr(13)||chr(10)
          as txt
   from dual
   union all
   select txt from
   (select   '<tr>'
          ||'<td>'||substr(t.filial,1,200)||'</td>'
          ||'<td>'||t.cli_code||'</td>'
          ||'<td>'||substr(t.full_name,1,200)||'</td>'
          ||'<td>'||t.contract_num||'</td>'
          ||'<td>'||to_char(t.amt_od_np)||'</td>'
          ||'<td>'||to_char(t.od_prosroch)||'</td>'
          ||'<td>'||to_char(t.amt_prc_np)||'</td>'
          ||'<td>'||to_char(t.amt_prc)||'</td>'
          ||'<td>'||to_char(t.od)||'</td>'
          ||'<td>'||t.period||'</td>'
          ||'<td>'||to_char(t.dni_prosrochki)||'</td>'
          ||'</tr>'
          ||chr(13)||chr(10)
          as txt
   from CREDIT_PROSROCHKA_TOMAIL t
   where t.sdt = dt and t.cl_type = filtr and t.period = filtr1 and t.nn >= a and t.nn<=b
   order by t.period desc, t.od_ost desc)
   union all
   select '</table>
           </body>
           </html> ' as txt
   from dual
   ;


   type t_tab is table of c%rowtype;
   l_t t_tab;
   l_res clob;
begin
   open c;
   fetch c bulk collect into l_t;
   close c;

   dbms_lob.createtemporary(l_res,false,dbms_lob.call);

   for i in l_t.first..l_t.last loop
     dbms_lob.writeappend(l_res,length(l_t(i).txt),l_t(i).txt);
   end loop;

   return l_res;

 exception
   when others then
     if c%isopen then close c; end if;
     return null;
end CREDIT_PROSROCHKA_CSV;

procedure CREDIT_PROSROCHKA_TOMAIL
is
 p_to smtp_mail.t_email_tab;
 p_cc smtp_mail.t_email_tab;
 p_attachmentlist smtp_mail.t_attachmentsclob_tab;
 p_attach smtp_mail.t_attachmentClob;
 l_er varchar2(32767);

 dt date;
 i number;
 cursor cur1 is  select t.cl_type,t.period , count(*)as cnt from CREDIT_PROSROCHKA_TOMAIL t
              group by t.cl_type, t.period;

 v_cl_type  varchar2(100);
 v_period   varchar2(100);
 v_cnt     number;
 iter      number;
 j         number;
begin
    dt:=sysdate;

    --select count(*) into i from LOAN_SCHED t where trunc(t.upd_dt1) = trunc(dt);
    if i <= 0 then
       process.table_refresh('V_LOAN_SCHED','LOAN_SCHED');
    end if;

    select count(*) into i from credit_prosrochka_20150715 t where trunc(t.upd_dt1) = trunc(dt);
    if i <= 0 then
       process.table_refresh('v_credit_prosrochka_20150715','credit_prosrochka_20150715');
    end if;

    delete from CREDIT_PROSROCHKA_TOMAIL;
    commit;

    insert into CREDIT_PROSROCHKA_TOMAIL
    select dt as SDT, a.* from
    (select
      ROW_NUMBER() OVER (partition by t.cl_type, t.period ORDER BY t.od_ost desc) nn --номер по порядку
      ,t.*
    from credit_prosrochka_20150715 t
    where --Berlinbayeva Dinara:  займы со статусами: списан, удален, погашен и прощен брать в отчет не надо
          t.state not in ('Списан','Удалён','Погашен','Прощен')
          and t.cl_type <> '1. Retail'
          and t.period in ('1. <31','2. 31-60','3. 61-90','4. 91-120')
    ) a
    ;
    commit;

   p_to(1):='Alexey.Yevseyev@atfbank.kz';
   p_to(2):='daniil.sokolov@atfbank.kz';
   p_to(3):='Yuriy.Khramtsov@atfbank.kz';
--   p_to(4):='Gulnar.Tureshbayeva@atfbank.kz';
--   p_to(5):='Galimzhan.Shishingarin@atfbank.kz';
--   p_to(6):='Olessya.Imasheva@atfbank.kz';
--   p_to(7):='Gulnara.Balakhmetova@atfbank.kz';
--   p_to(8):='Anton.Li@atfbank.kz';
   j:=0;
   open cur1;
      loop
        fetch cur1 into v_cl_type,v_period,v_cnt;
        EXIT WHEN cur1%NOTFOUND;

        --if v_cnt <= 70 then
            j:=j+1;
            p_attach.p_attach_name:=v_cl_type||'_'||v_period||'_'||to_char(trunc(dt),'DD-MM-YYYY')||'.xls';
            p_attach.p_attach_mime:='text/plain';
            p_attach.p_attach_clob:=CREDIT_PROSROCHKA_CSV(dt,v_cl_type,v_period, 1, 70);
            p_attachmentlist(j):=p_attach;
        --end if;
        if v_cnt > 70 then
           iter:= trunc(v_cnt/70)+1;
           i:=1;
           loop
             EXIT WHEN i>iter;
             j:=j+1;
             p_attach.p_attach_name:=v_cl_type||'_'||v_period||'_'||to_char(i)||'_'||to_char(trunc(dt),'DD-MM-YYYY')||'.xls';
             p_attach.p_attach_mime:='text/plain';
             p_attach.p_attach_clob:=CREDIT_PROSROCHKA_CSV(dt,v_cl_type,v_period, (70*i)+1, (70*i)+70);
             p_attachmentlist(j):=p_attach;

             i:=i+1;
           end loop;

        end if;

   end loop;
   close cur1;




  smtp_mail.send_mail_clob(p_to => p_to,
                           p_from => 'RISK_PROCESS_AUTOMATIC@atfbank.kz',
                           p_subject => 'PROCESS (Процесс не может сформировать файл более 32Кбайт)',
                           p_text_msg => 'Задолженность по кредитам',
                           p_cc => p_cc,
                           p_failure => l_er,
                           p_attachmentlist => p_attachmentlist,
                           p_auto_text => 1);




end CREDIT_PROSROCHKA_TOMAIL;

/*procedure XLS_UWI_DETAIL_STAGES_refresh is
  i number;
begin
  select count(*) into i from user_tables t where t.TABLE_NAME = 'XLS_UWI_DETAIL_STAGES';
  if i > 0 then
     execute immediate ('drop table XLS_UWI_DETAIL_STAGES purge');
  end if;
  execute immediate ('create table XLS_UWI_DETAIL_STAGES as select t.*, sysdate as SDT from UWI_DETAIL_STAGES t');
  execute immediate ('grant select on XLS_UWI_DETAIL_STAGES to RISK_REPORTER_ROLE');

end;
*/

procedure table_refresh(src varchar2, dest varchar2)
 is
  i number;
begin
  select count(*) into i from user_tables t where t.TABLE_NAME = upper(dest);
  if i > 0 then
     execute immediate ('drop table '||dest||' purge');
  end if;
  execute immediate ('create table '||dest||' as select t.*, sysdate as upd_DT1 from '||src||' t');
  execute immediate ('grant select on '||dest||' to RISK_REPORTER_ROLE');

end;


procedure get_credit_portfolio
is
  TYPE   CurTyp IS REF CURSOR;  -- define weak REF CURSOR type
  cur1   CurTyp;  -- declare cursor variable
  l v_DM_LOAN_BASE_cln%rowtype;
  i number;
  v_state varchar2(500);
  v_dt date;
begin
   v_dt:= trunc(sysdate-1);
   OPEN cur1 FOR  -- open cursor variable
        'select * from v_DM_LOAN_BASE_cln where :s between FROMDATE and TODATE or state<>''Погашен''' USING v_dt;
   --open cur1;
   loop
      fetch cur1 into l ;
      EXIT WHEN cur1%NOTFOUND;
      v_state:=l.state;
      select count(1) into i from credit_portfolio2 t where t.refer = l.REFER_WH and t.dt = v_dt;
      if i<=0 then
            insert /*+ append */
            into CREDIT_PORTFOLIO2 values(
            sysdate --as SDT /*  дата создания записи  */
            ,v_dt --as DT  /*  дата за (<=)  */
            ,l.refer_wh --as REFER /*  референс  */
            ,l.contract_num --as CONTRACT_NUM  /*  номер договора  */
            ,l.val_code --as VAL_CODE  /*  Валюта  */
            ,l.full_name  --as CLIENT_NAME /*  Наименование  заемщика  */
            ,l.cli_code  --as CLIENT_CODE /*  Код клиента */
            ,l.iin  --as IIN /*  ИИН/БИН */
            ,l.sum_full --as AMOUNT  /*  "Валюта выдачи" */
            ,l.sum_full * Get_NBRK_Curr(v_dt,l.val_code,0)-- as AMOUNTKZT /*  "Валюта выдачи KZT" */
            ,l.rate --as RATE  /*  "Процентная ставка" */
            ,l.csln_fromdate --as STARTDATE /*  "Дата выдачи" */
            ,l.TODATE --as FINISHDATE  /*  "Дата погашения" */
            ,l.fil_code --as FIL_CODE  /*  Код филиала */
            ,l.fil_name --as FIL_NAME  /*  Наименование филиала  */
            ,l.sell_dep_id --as SELL_DEP_ID /*  Код точки продаж  */
            ,l.obj_id --as OBJ_ID  /*  Связка с катрочкой ХД (q_row) */
            ,l.prd_code --as PRD_CODE  /*  Код продукта  */
            ,l.prd_name --as PRD_NAME  /*  Наименование продукта */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 45 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 45),lh.sup_perc_cur)
              --as SUP_PERC_CUR  /*  Начисленные проценты в валюте */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 46 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 46),lh.sup_perc_equ )
              --as SUP_PERC_EQU  /*  Начисленные проценты в эквиваленте  */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 2 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 2),lh.debt_dea_cur)
              --as DEBT_DEA_CUR  /*  Остаток задолженности по договору в валюте  */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 3 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 3),lh.debt_dea_equ)
              --as DEBT_DEA_EQU  /*  Остаток задолженности по договору в эквиваленте */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 4 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 4),lh.ovrd_main_cur)
              --as OVRD_MAIN_CUR /*  Просроченная сумма по основному долгу в валюте  */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 5 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 5),lh.ovrd_main_equ)
              --as OVRD_MAIN_EQU /*  Просроченная сумма по основному долгу в эквиваленте */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 1 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 1),lh.interest_rate)
              --as INTEREST_RATE /*  Процентная ставка */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 1003 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 1003),lh.ovrd_prc_debt_b_cur)
             -- as OVRD_PRC_DEBT_B_CUR /*  Просроченные проценты баланс в валюте */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 1004 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 1004),lh.ovrd_prc_debt_b_equ)
              --as OVRD_PRC_DEBT_B_EQU /*  Просроченные проценты баланс в эквиваленте  */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 365 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 365),lh.ovrd_main)
              --as OVRD_MAIN /*  Срок текущей просроченной задолженности по основному долгу  */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 366 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 366),lh.ovrd_prc)
              --as OVRD_PRC  /*  Срок текущей просроченной задолженности по процентам  */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 1532 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 1532),lh.wr_pd_cur)
              --as WR_PD_CUR /*  Списанный ОД в валюте */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 1533 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 1533),lh.wr_pd_equ)
              --as WR_PD_EQU /*  Списанный ОД в эквиваленте  */
            ,v_state  --статус договора
            );
            commit;
      end if;
   end loop;
   close cur1;

end;




procedure get_credit_portfolio2 (v_dt date)
is

  TYPE   CurTyp IS REF CURSOR;  -- define weak REF CURSOR type
  cur1   CurTyp;  -- declare cursor variable
  l v_DM_LOAN_BASE_cln%rowtype;
  i number;
  v_state varchar2(500);
begin
   OPEN cur1 FOR  -- open cursor variable
        'select * from v_DM_LOAN_BASE_cln where :s between FROMDATE and TODATE' USING v_dt;

   --open cur1;
   loop
      fetch cur1 into l ;
      EXIT WHEN cur1%NOTFOUND;
      v_state:=null;
      select count(1) into i from credit_portfolio2 t where t.refer = l.REFER_WH and t.dt = v_dt;
      if i<=0 then
            insert /*+ append */
            into CREDIT_PORTFOLIO2 values(
            sysdate --as SDT /*  дата создания записи  */
            ,v_dt --as DT  /*  дата за (<=)  */
            ,l.refer_wh --as REFER /*  референс  */
            ,l.contract_num --as CONTRACT_NUM  /*  номер договора  */
            ,l.val_code --as VAL_CODE  /*  Валюта  */
            ,l.full_name  --as CLIENT_NAME /*  Наименование  заемщика  */
            ,l.cli_code  --as CLIENT_CODE /*  Код клиента */
            ,l.iin  --as IIN /*  ИИН/БИН */
            ,l.sum_full --as AMOUNT  /*  "Валюта выдачи" */
            ,l.sum_full * Get_NBRK_Curr(v_dt,l.val_code,0)-- as AMOUNTKZT /*  "Валюта выдачи KZT" */
            ,l.rate --as RATE  /*  "Процентная ставка" */
            ,l.csln_fromdate --as STARTDATE /*  "Дата выдачи" */
            ,l.TODATE --as FINISHDATE  /*  "Дата погашения" */
            ,l.fil_code --as FIL_CODE  /*  Код филиала */
            ,l.fil_name --as FIL_NAME  /*  Наименование филиала  */
            ,l.sell_dep_id --as SELL_DEP_ID /*  Код точки продаж  */
            ,l.obj_id --as OBJ_ID  /*  Связка с катрочкой ХД (q_row) */
            ,l.prd_code --as PRD_CODE  /*  Код продукта  */
            ,l.prd_name --as PRD_NAME  /*  Наименование продукта */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 45 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 45),lh.sup_perc_cur)
              --as SUP_PERC_CUR  /*  Начисленные проценты в валюте */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 46 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 46),lh.sup_perc_equ )
              --as SUP_PERC_EQU  /*  Начисленные проценты в эквиваленте  */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 2 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 2),lh.debt_dea_cur)
              --as DEBT_DEA_CUR  /*  Остаток задолженности по договору в валюте  */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 3 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 3),lh.debt_dea_equ)
              --as DEBT_DEA_EQU  /*  Остаток задолженности по договору в эквиваленте */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 4 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 4),lh.ovrd_main_cur)
              --as OVRD_MAIN_CUR /*  Просроченная сумма по основному долгу в валюте  */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 5 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 5),lh.ovrd_main_equ)
              --as OVRD_MAIN_EQU /*  Просроченная сумма по основному долгу в эквиваленте */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 1 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 1),lh.interest_rate)
              --as INTEREST_RATE /*  Процентная ставка */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 1003 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 1003),lh.ovrd_prc_debt_b_cur)
             -- as OVRD_PRC_DEBT_B_CUR /*  Просроченные проценты баланс в валюте */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 1004 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 1004),lh.ovrd_prc_debt_b_equ)
              --as OVRD_PRC_DEBT_B_EQU /*  Просроченные проценты баланс в эквиваленте  */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 365 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 365),lh.ovrd_main)
              --as OVRD_MAIN /*  Срок текущей просроченной задолженности по основному долгу  */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 366 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 366),lh.ovrd_prc)
              --as OVRD_PRC  /*  Срок текущей просроченной задолженности по процентам  */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 1532 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 1532),lh.wr_pd_cur)
              --as WR_PD_CUR /*  Списанный ОД в валюте */
            ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 1533 and xx.fromdate <= v_dt and rownum = 1)
            --,nvl((select rval from tmp_credit_portfolio where row_id = 1533),lh.wr_pd_equ)
              --as WR_PD_EQU /*  Списанный ОД в эквиваленте  */
            ,v_state  --статус договора
            );
            commit;
      end if;
   end loop;
   close cur1;


end;



procedure get_credit_portfolio3 (v_f varchar2)
is
  TYPE   CurTyp IS REF CURSOR;  -- define weak REF CURSOR type
  cur1   CurTyp;  -- declare cursor variable
  --l v_DM_LOAN_BASE_cln%rowtype;
  v_ref varchar2(100);
  i number;
begin
   OPEN cur1 FOR  -- open cursor variable
       v_f --'select * from v_DM_LOAN_BASE_cln' 
        ;

   --open cur1;
   loop
      fetch cur1 into v_ref; --l ;
      EXIT WHEN cur1%NOTFOUND;

      select count(1) into i from credit_portfolio3 t where t.REFER_WH = v_ref and t.dt >= trunc(to_date('04.10.2015'))-1 and rownum=1;
      if i<=0 then
          begin
            insert /*+ parallel(4) append */
            into CREDIT_PORTFOLIO3
            select
               t.refer_wh --as REFER /*  референс  */
               --,t.contract_num --as CONTRACT_NUM  /*  номер договора  */
               --,t.val_code --as VAL_CODE  /*  Валюта  */
               --,t.full_name  --as CLIENT_NAME /*  Наименование  заемщика  */
               --,t.cli_code  --as CLIENT_CODE /*  Код клиента */
               --,t.iin  --as IIN /*  ИИН/БИН */
               --,t.sum_full --as AMOUNT  /*  "Валюта выдачи" */
               --,t.sum_full * Get_NBRK_Curr(d.dt,t.val_code,0) as AMOUNTKZT /*  "Валюта выдачи KZT" */
               --,t.rate --as RATE  /*  "Процентная ставка" */
               --,t.fromdate
               --,t.csln_fromdate --as STARTDATE /*  "Дата выдачи" */
               --,t.TODATE --as FINISHDATE  /*  "Дата погашения" */
               --,t.fil_code --as FIL_CODE  /*  Код филиала */
               --,t.fil_name --as FIL_NAME  /*  Наименование филиала  */
               --,t.sell_dep_id --as SELL_DEP_ID /*  Код точки продаж  */
               --,t.obj_id --as OBJ_ID  /*  Связка с катрочкой ХД (q_row) */
               --,t.prd_code --as PRD_CODE  /*  Код продукта  */
               --,t.prd_name --as PRD_NAME  /*  Наименование продукта */
               ,d.dt
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 45 and xx.fromdate <= d.dt and rownum = 1)
                 as SUP_PERC_CUR  /*  Начисленные проценты в валюте */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 46 and xx.fromdate <= d.dt and rownum = 1)
                 as SUP_PERC_EQU  /*  Начисленные проценты в эквиваленте  */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 2 and xx.fromdate <= d.dt and rownum = 1)
                 as DEBT_DEA_CUR  /*  Остаток задолженности по договору в валюте  */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 3 and xx.fromdate <= d.dt and rownum = 1)
                 as DEBT_DEA_EQU  /*  Остаток задолженности по договору в эквиваленте */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 4 and xx.fromdate <= d.dt and rownum = 1)
                 as OVRD_MAIN_CUR /*  Просроченная сумма по основному долгу в валюте  */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 5 and xx.fromdate <= d.dt and rownum = 1)
                 as OVRD_MAIN_EQU /*  Просроченная сумма по основному долгу в эквиваленте */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 1 and xx.fromdate <= d.dt and rownum = 1)
                 as INTEREST_RATE /*  Процентная ставка */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 1003 and xx.fromdate <= d.dt and rownum = 1)
                 as OVRD_PRC_DEBT_B_CUR /*  Просроченные проценты баланс в валюте */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 1004 and xx.fromdate <= d.dt and rownum = 1)
                 as OVRD_PRC_DEBT_B_EQU /*  Просроченные проценты баланс в эквиваленте  */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 365 and xx.fromdate <= d.dt and rownum = 1)
                 as OVRD_MAIN /*  Срок текущей просроченной задолженности по основному долгу  */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 366 and xx.fromdate <= d.dt and rownum = 1)
                 as OVRD_PRC  /*  Срок текущей просроченной задолженности по процентам  */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 1532 and xx.fromdate <= d.dt and rownum = 1)
                 as WR_PD_CUR /*  Списанный ОД в валюте */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 1533 and xx.fromdate <= d.dt and rownum = 1)
                 as WR_PD_EQU /*  Списанный ОД в эквиваленте  */
            from v_DM_LOAN_BASE_cln t
            left join dm_date d on d.dt between /*t.fromdate*/ trunc(to_date('04.10.2015'))-1 and (case when t.state<>'Погашен' then trunc(to_date('17.11.2015'))-2 else t.todate end)
            where t.REFER_WH = v_ref and d.dt <=trunc(to_date('17.11.2015'))-1;
            commit;
          exception
            when others then null;
          end;
      end if;

   end loop;
   close cur1;
end;


procedure get_credit_portfolio4 (v_f varchar2)
is
  TYPE   CurTyp IS REF CURSOR;  -- define weak REF CURSOR type
  cur1   CurTyp;  -- declare cursor variable
  --l v_DM_LOAN_BASE_cln%rowtype;
  v_ref varchar2(100);
  i number;
  dt_max date;
  dt_to date;
begin
   dt_to:= trunc(sysdate)-2;
   OPEN cur1 FOR  -- open cursor variable
       v_f --'select * from v_DM_LOAN_BASE_cln' 
        ;

   --open cur1;
   loop
      fetch cur1 into v_ref; --l ;
      EXIT WHEN cur1%NOTFOUND;

      select max(t.dt) into dt_max from credit_portfolio3 t where t.REFER_WH = v_ref ;
      select count(1) into i from credit_portfolio3 t where t.REFER_WH = v_ref and t.dt >= dt_max+1 and rownum=1;
      if i<=0 then
          begin
            insert /*+ parallel(4) append */
            into CREDIT_PORTFOLIO3
            select
               t.refer_wh --as REFER /*  референс  */
               ,d.dt
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 45 and xx.fromdate <= d.dt and rownum = 1)
                 as SUP_PERC_CUR  /*  Начисленные проценты в валюте */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 46 and xx.fromdate <= d.dt and rownum = 1)
                 as SUP_PERC_EQU  /*  Начисленные проценты в эквиваленте  */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 2 and xx.fromdate <= d.dt and rownum = 1)
                 as DEBT_DEA_CUR  /*  Остаток задолженности по договору в валюте  */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 3 and xx.fromdate <= d.dt and rownum = 1)
                 as DEBT_DEA_EQU  /*  Остаток задолженности по договору в эквиваленте */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 4 and xx.fromdate <= d.dt and rownum = 1)
                 as OVRD_MAIN_CUR /*  Просроченная сумма по основному долгу в валюте  */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 5 and xx.fromdate <= d.dt and rownum = 1)
                 as OVRD_MAIN_EQU /*  Просроченная сумма по основному долгу в эквиваленте */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 1 and xx.fromdate <= d.dt and rownum = 1)
                 as INTEREST_RATE /*  Процентная ставка */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 1003 and xx.fromdate <= d.dt and rownum = 1)
                 as OVRD_PRC_DEBT_B_CUR /*  Просроченные проценты баланс в валюте */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 1004 and xx.fromdate <= d.dt and rownum = 1)
                 as OVRD_PRC_DEBT_B_EQU /*  Просроченные проценты баланс в эквиваленте  */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 365 and xx.fromdate <= d.dt and rownum = 1)
                 as OVRD_MAIN /*  Срок текущей просроченной задолженности по основному долгу  */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 366 and xx.fromdate <= d.dt and rownum = 1)
                 as OVRD_PRC  /*  Срок текущей просроченной задолженности по процентам  */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 1532 and xx.fromdate <= d.dt and rownum = 1)
                 as WR_PD_CUR /*  Списанный ОД в валюте */
               ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = t.OBJ_ID and xx.row_id = 1533 and xx.fromdate <= d.dt and rownum = 1)
                 as WR_PD_EQU /*  Списанный ОД в эквиваленте  */
            from v_DM_LOAN_BASE_cln t
            left join dm_date d on d.dt between /*t.fromdate*/ dt_max+1 and (case when t.state<>'Погашен' then dt_to else t.todate end)
            where t.REFER_WH = v_ref and d.dt <= dt_to;
            commit;
          exception
            when others then null;
          end;
      end if;

   end loop;
   close cur1;
end;


procedure get_w4_bal (v_dt date, v_ows_client_id  number)
is
begin

  For rec in (select a.ows_contract_id from dwh_buffer.OWS_CLIENT_BUF t
              left join dwh_buffer.OWS_CONTRACT_BUF a on a.ows_client_id = t.ows_client_id
              where t.ows_client_id = v_ows_client_id and a.acnt_contract__oid is null) loop
      insert /*+ append */
      into w_4_bal
      select
           decode(t1.name, null, 'N/D', t1.name) as  trans_from
           ,decode(t2.name, null, 'N/D', t2.name) as  trans_to
          ,doc.source_contract
          ,doc.target_contract
          ,tt.name as trans_type
          ,mt.posting_db_date
          ,doc.trans_date
          ,doc.trans_curr
          ,oc.currency_code
          ,mt.direction
          ,(mt.t_amount + mt.t_fee_amount)*(case when mt.direction = 1 then 1 else -1 end) as bal
          ,doc.source_number
          ,doc.target_number
          ,(SELECT ac.client__id ows_client_id
                   FROM ows.client@rpt c, ows.acnt_contract@rpt ac
                  WHERE     c.amnd_state = 'A'
                        AND ac.amnd_state = 'A'
                        AND c.ID = ac.client__id
                        AND ac.contract_number = target_number
                        AND ROWNUM < 2)
                   ows_client_id
          ,doc.target_contract as w4_contract
          ,rec.ows_contract_id  as billing_contract
      from dwh_buffer.W4_DOC doc
        join dwh_buffer.w4_trans_type tt on tt.id = DOC.trans_type
        join dwh_buffer.W4_M_TRANSACTION mt on mt.doc__oid = doc.id
        left join dwh_buffer.W4_MESS_CHANNEL t1 on t1.code =  doc.source_channel
        left join dwh_buffer.W4_MESS_CHANNEL t2 on t2.code =  doc.target_channel
        left join dwh_buffer.OWS_CONTRACT_BUF oc on oc.ows_contract_id = doc.target_contract
      where doc.target_contract in
              (select t.ows_contract_id from DWH_BUFFER.OWS_CONTRACT_BUF t
               connect by prior t.ows_contract_id = t.acnt_contract__oid
               start with t.billing_contract =  rec.ows_contract_id
                          and t.acnt_contract__oid is null)
            and MT.posting_status = 'P'
                AND doc.amnd_state = 'A'
                AND DOC.is_authorization = 'N'
                AND DOC.posting_status = 'P'
                and mt.trans_subtype is not null
                and doc.trans_date <=v_dt
      union all
      select
           decode(t1.name, null, 'N/D', t1.name) as  trans_from
           ,decode(t2.name, null, 'N/D', t2.name) as  trans_to
          ,doc.source_contract
          ,doc.target_contract
          ,tt.name as trans_type
          ,mt.posting_db_date
          ,doc.trans_date
          ,doc.trans_curr
          ,oc.currency_code
          ,mt.direction
          ,(mt.s_amount + mt.s_fee_amount)*-1 as bal
          ,doc.source_number
          ,doc.target_number
          ,(SELECT ac.client__id ows_client_id
                   FROM ows.client@rpt c, ows.acnt_contract@rpt ac
                  WHERE     c.amnd_state = 'A'
                        AND ac.amnd_state = 'A'
                        AND c.ID = ac.client__id
                        AND ac.contract_number = target_number
                        AND ROWNUM < 2)
                   ows_client_id
          ,doc.source_contract as w4_contract
          ,rec.ows_contract_id  as billing_contract
      from dwh_buffer.W4_DOC doc
        join dwh_buffer.w4_trans_type tt on tt.id = DOC.trans_type
        join dwh_buffer.W4_M_TRANSACTION mt on mt.doc__oid = doc.id
        left join dwh_buffer.W4_MESS_CHANNEL t1 on t1.code =  doc.source_channel
        left join dwh_buffer.W4_MESS_CHANNEL t2 on t2.code =  doc.target_channel
        left join dwh_buffer.OWS_CONTRACT_BUF oc on oc.ows_contract_id = doc.source_contract
      where doc.source_contract in
              (select t.ows_contract_id from DWH_BUFFER.OWS_CONTRACT_BUF t
               connect by prior t.ows_contract_id = t.acnt_contract__oid
               start with t.billing_contract = rec.ows_contract_id
                          and t.acnt_contract__oid is null)
            and MT.posting_status = 'P'
                AND doc.amnd_state = 'A'
                AND DOC.is_authorization = 'N'
                AND DOC.posting_status = 'P'
                and mt.trans_subtype is not null
                and doc.trans_date <=v_dt;
     commit;
  end loop;



end;



procedure GSVP_parsing is
   TYPE CurTyp IS REF CURSOR;  
   cur   CurTyp;  
   v_id varchar2(100);
begin
  OPEN cur FOR  
     'select t.id from dwh_buffer.EKZ_GSVP t 
      left join (select distinct id from gsvp_pars)a on a.id = t.id 
      left join gsvp_pars_err b on b.id = t.id 
      where a.id is null and b.id is null
      order by t.querydate desc'; -- USING v_max_id;
  loop
     fetch cur into v_id ;
     EXIT WHEN cur%NOTFOUND;

     begin
        insert into gsvp_pars 
        select 
           a.id 
           ,b.*
           ,c.*
        from(
           select id, xmltype(replace(t.xml_response,'utf-16','utf-8')) as xml from dwh_buffer.EKZ_GSVP t
           where t.id = v_id
        ) a
        ,XMLTable('deductionDetailedResponse' passing (a.xml) 
                          columns 
                                  birthDate varchar2(100) path 'request/person/birthDate' 
                                 ,iin varchar2(100) path 'request/person/iin' 
                                 ,fatherName varchar2(100) path 'request/person/fatherName' 
                                 ,name varchar2(100) path 'request/person/name' 
                                 ,surname varchar2(100) path 'request/person/surname' 
                          ) b  
        ,XMLTable('deductionDetailedResponse/deductions' passing (a.xml) 
                          columns 
                                  dt varchar2(100) path 'date' 
                                  ,company_name varchar2(1000) path 'name' 
                                  ,bin varchar2(100) path 'bin' 
                                  ,amount varchar2(100) path 'amount' 
              
                          ) c  ;
        commit;                                  
     exception
       when others then
         insert into gsvp_pars_err (id) values(v_id);
         commit;
         null;
     end;
     
  end loop;
  commit;
  close cur;     
end;
               
procedure FCB_parsing_1 is
   TYPE CurTyp IS REF CURSOR;  
   cur   CurTyp;  
   v_id varchar2(100);
   p_info  xmltype;   
begin
  OPEN cur FOR  
     'select distinct t.id from EXE_FCB t
      left join FCB_err a on a.id = t.id
      left join FCB_GENERAL_INFORMATION b on b.id = t.id
      where a.id is null and b.id is null'; -- USING v_max_id;
  loop
     fetch cur into v_id ;
     EXIT WHEN cur%NOTFOUND;

     begin
        insert 
        into FCB_General_information
        select 
           s.id
           ,s.creditordernumber as Loan_ID
           ,a.*
           --,s.*
        from
            (select t.id, t.creditordernumber, XMLType(t.definition) as xml from EXE_FCB t
            where  t.id = v_id) s
        ,XMLTable('CigResult' 
                          passing (s.xml) 
                          columns DateTime varchar2(100) path 'DateTime'
                          ,Version varchar2(100) path '@Version'
                          ,RNN  varchar2(20) path 'Result/Root/Header/RNN/@value'
                          ,IIN  varchar2(20) path 'Result/Root/Header/IIN/@value'
                          --Кол-во действующих договоров
                          ,NumberOfExistingContracts  varchar2(100) path 'Result/Root/SummaryInformationDebtor/NumberOfExistingContracts/NumberOfExistingContracts/@value'
                          ,NumberOfContracts  varchar2(100) path 'Result/Root/SummaryInformation/ExistingContracts/SubjectRole/NumberOfContracts/@value'
                          --Общая непогашенная сумма
                          ,TotalOutstandingDebt  varchar2(100) path 'Result/Root/SummaryInformationDebtor/TotalOutstandingDebt/TotalOutstandingDebt/@value'
                          ,TotalOutstandingDebt_ex  varchar2(100) path 'Result/Root/SummaryInformation/ExistingContracts/SubjectRole/TotalOutstandingDebt/@value'
                          ,TotalOutstandingDebtterm  varchar2(100) path 'Result/Root/SummaryInformation/TerminatedContracts/SubjectRole/TotalOutstandingDebt/@value'
                          --Завершенные договора
                          ,NumberOfTerminatedContracts   varchar2(100) path 'Result/Root/SummaryInformationDebtor/NumberOfTerminatedContracts/NumberOfTerminatedContracts/@value' 
                          ,NumberOfContracts_Terminated  varchar2(100) path 'Result/Root/SummaryInformation/TerminatedContracts/SubjectRole/NumberOfContracts/@value'

                          ,DateOfIssue  varchar2(100) path 'Result/Root/Footer/DateOfIssue/@value'
                          --Количество запросов (12м)
                          ,NumberOfInquiries  varchar2(100) path 'Result/Root/SummaryInformationDebtor/NumberOfInquiries/@value'
                          ,NumberOfInquiries1  varchar2(100) path 'Result/Root/SummaryInformation/NumberOfInquiries/@value'
                          --1- ый квартал	2- ый квартал	3- ый квартал	4- ый квартал
                          ,Q1  varchar2(100) path 'Result/Root/SummaryInformationDebtor/NumberOfInquiries/FirstQuarter/@value'
                          ,Q2  varchar2(100) path 'Result/Root/SummaryInformationDebtor/NumberOfInquiries/SecondQuarter/@value'
                          ,Q3  varchar2(100) path 'Result/Root/SummaryInformationDebtor/NumberOfInquiries/ThirdQuarter/@value'
                          ,Q4  varchar2(100) path 'Result/Root/SummaryInformationDebtor/NumberOfInquiries/FourthQuarter/@value'
                          
                          ,Q1_1  varchar2(100) path 'Result/Root/SummaryInformation/NumberOfInquiries/FirstQuarter/@value'
                          ,Q2_1  varchar2(100) path 'Result/Root/SummaryInformation/NumberOfInquiries/SecondQuarter/@value'
                          ,Q3_1  varchar2(100) path 'Result/Root/SummaryInformation/NumberOfInquiries/ThirdQuarter/@value'
                          ,Q4_1  varchar2(100) path 'Result/Root/SummaryInformation/NumberOfInquiries/FourthQuarter/@value'

                          --,ExistingContracts XMLType path 'Result/Root/TerminatedContracts'
                          ) a ; 
        commit;                                  
     exception
       when others then
         rollback;
         p_info:= Fill_Info(
                  sqlcode
                  ,sqlerrm
                  ,Dbms_Utility.format_error_stack
                  ,Dbms_Utility.format_call_stack
                  ,Dbms_Utility.format_error_backtrace
             );
         insert into FCB_err (id, info) values(v_id,p_info);
         commit;
         null;
     end;
     
  end loop;
  commit;
  close cur;     
end;


procedure FCB_parsing_2 is
   TYPE CurTyp IS REF CURSOR;  
   cur   CurTyp;  
   v_id varchar2(100);
   p_info  xmltype;   
   
begin
  OPEN cur FOR  
     'select distinct t.id from EXE_FCB t
      left join FCB_err a on a.id = t.id
      left join FCB_Contracts b on b.id = t.id
      where a.id is null and b.id is null'; -- USING v_max_id;
  loop
     fetch cur into v_id ;
     EXIT WHEN cur%NOTFOUND;

     begin
        insert 
        into FCB_Contracts
        select 
           s.id
           ,s.creditordernumber as Loan_ID
           ,'TerminatedContracts' as ContractType
           ,a.*
           --,s.*
        from
            (select t.id, t.creditordernumber, XMLType(t.definition) as xml from EXE_FCB t
            where  t.id = v_id) s
        ,XMLTable('CigResult/Result/Root/TerminatedContracts/Contract' --TerminatedContracts   ExistingContracts
                          passing (s.xml) 
                          columns 
                             CodeOfContract varchar2(70) path 'CodeOfContract/@value' --Код контракта
                             ,AgreementNumber varchar2(50) path 'AgreementNumber/@value'  --Номер договора
                             ,TypeOfFounding_id varchar2(10) path 'TypeOfFounding/@id'  --Вид финансирования
                             ,TypeOfFounding varchar2(50) path 'TypeOfFounding/@value'  --Вид финансирования
                             ,Currency varchar2(10) path 'CurrencyCode/@value' --Код валюты
                             ,ContractStatus_id varchar2(10) path 'ContractStatus/@id' --Статус договора
                             ,ContractStatus varchar2(50) path 'ContractStatus/@value' --Статус договора
                             ,DateOfCreditStart varchar2(50) path 'DateOfCreditStart/@value' --Дата начала срока действия договора
                             ,DateOfCreditEnd varchar2(50) path 'DateOfCreditEnd/@value' --Дата окончания срока действия договора
                             ,TotalAmount varchar2(50) path 'TotalAmount/@value'--Общая сумма кредита/валюта
                             ,CreditLimit varchar2(50) path 'CreditLimit/@value'--Сумма кредитного лимита
                             ,NumberOfOutstandingInstalments varchar2(50) path 'NumberOfOutstandingInstalments/@value' --Кол-во непогашенных (предстоящих) платежей
                             ,NumberOfInstalments varchar2(50) path 'NumberOfInstalments/@value' --Общее количество платежей
                             ,ResidualAmount varchar2(50) path 'ResidualAmount/@value' --Использованная сумма (подлежащая погашению) 
                             ,PeriodicityOfPayments_id varchar2(10) path 'PeriodicityOfPayments/@id' --Периодичность платежей
                             ,PeriodicityOfPayments varchar2(50) path 'PeriodicityOfPayments/@value' --Периодичность платежей
                             ,NumberOfOverdueInstalments varchar2(50) path 'NumberOfOverdueInstalments/@value' --Количество дней просрочки
                             ,OverdueAmount varchar2(50) path 'NumberOfOverdueInstalments/@value' --Сумма просроченных взносов
                             ,MonthlyInstalmentAmount varchar2(50) path 'MonthlyInstalmentAmount/@value' --Сумма ежемесячного платежа
                             ,NominalRate varchar2(10) path 'NominalRate/@value' --Номинальная ставка вознаграждения
                             ,InterestRate varchar2(10) path 'InterestRate/@value' --Номинальная ставка вознаграждения
                             ,FinancialInstitution_id varchar2(10) path 'FinancialInstitution/@id' --Источник информации (Кредитор)
                             ,FinancialInstitution varchar2(50) path 'FinancialInstitution/@value' --Источник информации (Кредитор)
                             ,SubjectRole_id varchar2(10) path 'SubjectRole/@number' --Роль субъекта
                             ,SubjectRole varchar2(50) path 'SubjectRole/@value' --Роль субъекта
                             ,LastUpdate varchar2(50) path 'LastUpdate/@value' --Дата последнего обновления

                          ) a;  
        insert into FCB_Contracts
        select 
           s.id
           ,s.creditordernumber as Loan_ID
           ,'ExistingContracts' as ContractType
           ,a.*
           --,s.*
        from
            (select t.id, t.creditordernumber, XMLType(t.definition) as xml from EXE_FCB t
            where  t.id = v_id) s
        ,XMLTable('CigResult/Result/Root/ExistingContracts/Contract' --TerminatedContracts   ExistingContracts
                          passing (s.xml) 
                          columns 
                             CodeOfContract varchar2(70) path 'CodeOfContract/@value' --Код контракта
                             ,AgreementNumber varchar2(50) path 'AgreementNumber/@value'  --Номер договора
                             ,TypeOfFounding_id varchar2(10) path 'TypeOfFounding/@id'  --Вид финансирования
                             ,TypeOfFounding varchar2(50) path 'TypeOfFounding/@value'  --Вид финансирования
                             ,Currency varchar2(10) path 'CurrencyCode/@value' --Код валюты
                             ,ContractStatus_id varchar2(10) path 'ContractStatus/@id' --Статус договора
                             ,ContractStatus varchar2(50) path 'ContractStatus/@value' --Статус договора
                             ,DateOfCreditStart varchar2(50) path 'DateOfCreditStart/@value' --Дата начала срока действия договора
                             ,DateOfCreditEnd varchar2(50) path 'DateOfCreditEnd/@value' --Дата окончания срока действия договора
                             ,TotalAmount varchar2(50) path 'TotalAmount/@value'--Общая сумма кредита/валюта
                             ,CreditLimit varchar2(50) path 'CreditLimit/@value'--Сумма кредитного лимита
                             ,NumberOfOutstandingInstalments varchar2(50) path 'NumberOfOutstandingInstalments/@value' --Кол-во непогашенных (предстоящих) платежей
                             ,NumberOfInstalments varchar2(50) path 'NumberOfInstalments/@value' --Общее количество платежей
                             ,ResidualAmount varchar2(50) path 'ResidualAmount/@value' --Использованная сумма (подлежащая погашению) 
                             ,PeriodicityOfPayments_id varchar2(10) path 'PeriodicityOfPayments/@id' --Периодичность платежей
                             ,PeriodicityOfPayments varchar2(50) path 'PeriodicityOfPayments/@value' --Периодичность платежей
                             ,NumberOfOverdueInstalments varchar2(50) path 'NumberOfOverdueInstalments/@value' --Количество дней просрочки
                             ,OverdueAmount varchar2(50) path 'NumberOfOverdueInstalments/@value' --Сумма просроченных взносов
                             ,MonthlyInstalmentAmount varchar2(50) path 'MonthlyInstalmentAmount/@value' --Сумма ежемесячного платежа
                             ,NominalRate varchar2(10) path 'NominalRate/@value' --Номинальная ставка вознаграждения
                             ,InterestRate varchar2(10) path 'InterestRate/@value' --Номинальная ставка вознаграждения
                             ,FinancialInstitution_id varchar2(10) path 'FinancialInstitution/@id' --Источник информации (Кредитор)
                             ,FinancialInstitution varchar2(50) path 'FinancialInstitution/@value' --Источник информации (Кредитор)
                             ,SubjectRole_id varchar2(10) path 'SubjectRole/@number' --Роль субъекта
                             ,SubjectRole varchar2(50) path 'SubjectRole/@value' --Роль субъекта
                             ,LastUpdate varchar2(50) path 'LastUpdate/@value' --Дата последнего обновления

                          ) a;  

        commit;                                  
     exception
       when others then
         rollback;
         p_info:= Fill_Info(
                  sqlcode
                  ,sqlerrm
                  ,Dbms_Utility.format_error_stack
                  ,Dbms_Utility.format_call_stack
                  ,Dbms_Utility.format_error_backtrace
             );
         insert into FCB_err (id, info) values(v_id,p_info);

         commit;
         null;
     end;
     
  end loop;
  commit;
  close cur;     
end;


procedure FCB_parsing_3 is
   TYPE CurTyp IS REF CURSOR;  
   cur   CurTyp;  
   v_id varchar2(100);
   p_info  xmltype;   
   
begin
  OPEN cur FOR  
     'select distinct t.id from EXE_FCB t
      left join FCB_err a on a.id = t.id
      left join FCB_Collateral b on b.id = t.id
      where a.id is null and b.id is null'; -- USING v_max_id;
  loop
     fetch cur into v_id ;
     EXIT WHEN cur%NOTFOUND;

     begin
        insert 
        into FCB_Collateral
        select 
           s.id
           ,s.creditordernumber as Loan_ID
           ,'ExistingContracts' as ContractType
           ,a.CodeOfContract
           ,a.AgreementNumber
           ,b.*
           --,s.*
        from
            (select t.id, t.creditordernumber, XMLType(t.definition) as xml from EXE_FCB t
            where  t.id = v_id) s
        ,XMLTable('CigResult/Result/Root/ExistingContracts/Contract' --TerminatedContracts   ExistingContracts
                          passing (s.xml) 
                          columns 
                             CodeOfContract varchar2(70) path 'CodeOfContract/@value' --Код контракта
                             ,AgreementNumber varchar2(50) path 'AgreementNumber/@value'  --Номер договора
                             ,Collateral XMLType path 'Collateral'
                          ) a  
        ,XMLTable('Collateral' 
                          passing (a.Collateral) 
                          columns 
                             TypeOfGuarantee  varchar2(50) path 'TypeOfGuarantee/@value' --Вид обеспечения
                             ,ValueOfGuarantee  varchar2(50) path 'ValueOfGuarantee/@value' --Стоимость обеспечения
                             ,TypeOfValueOfGuarantee  varchar2(50) path 'TypeOfValueOfGuarantee/@value' --Вид стоимости обеспечения
                          ) b  ;
        
        insert into FCB_Collateral
        select 
           s.id
           ,s.creditordernumber as Loan_ID
           ,'TerminatedContracts' as ContractType
           ,a.CodeOfContract
           ,a.AgreementNumber
           ,b.*
           --,s.*
        from
            (select t.id, t.creditordernumber, XMLType(t.definition) as xml from EXE_FCB t
            where  t.id = v_id) s
        ,XMLTable('CigResult/Result/Root/TerminatedContracts/Contract' --TerminatedContracts   ExistingContracts
                          passing (s.xml) 
                          columns 
                             CodeOfContract varchar2(70) path 'CodeOfContract/@value' --Код контракта
                             ,AgreementNumber varchar2(50) path 'AgreementNumber/@value'  --Номер договора
                             ,Collateral XMLType path 'Collateral'
                          ) a  
        ,XMLTable('Collateral' 
                          passing (a.Collateral) 
                          columns 
                             TypeOfGuarantee  varchar2(50) path 'TypeOfGuarantee/@value' --Вид обеспечения
                             ,ValueOfGuarantee  varchar2(50) path 'ValueOfGuarantee/@value' --Стоимость обеспечения
                             ,TypeOfValueOfGuarantee  varchar2(50) path 'TypeOfValueOfGuarantee/@value' --Вид стоимости обеспечения
                          ) b  ;                          
        commit;                                  
     exception
       when others then
         rollback;
         p_info:= Fill_Info(
                  sqlcode
                  ,sqlerrm
                  ,Dbms_Utility.format_error_stack
                  ,Dbms_Utility.format_call_stack
                  ,Dbms_Utility.format_error_backtrace
             );
         insert into FCB_err (id, info) values(v_id,p_info);

         commit;
         null;
     end;
     
  end loop;
  commit;
  close cur;     
end;

procedure FCB_parsing_4_1 is
   TYPE CurTyp IS REF CURSOR;  
   cur   CurTyp;  
   v_id varchar2(100);
   p_info  xmltype;   
   
begin
  OPEN cur FOR  
     'select distinct t.id from EXE_FCB t
      left join FCB_err a on a.id = t.id
      left join FCB_PaymentsCalendar b on b.id = t.id
      where a.id is null and b.id is null'; -- USING v_max_id;
  loop
     fetch cur into v_id ;
     EXIT WHEN cur%NOTFOUND;

     begin
        insert 
        into FCB_PaymentsCalendar
        select 
           s.id
           ,s.creditordernumber as Loan_ID
           ,'ExistingContracts' as ContractType
           ,a.CodeOfContract
           ,a.AgreementNumber
           ,'20'||substr(c.title, INSTR (c.title,'/')+1, length(c.title)) as yyyy
           ,substr(c.title, 1, INSTR (c.title,'/')-1) as mm   
           ,c.overdue_days
           ,cast ('' as VARCHAR2(50 BYTE)) as overdue
           --,s.*
        from
            (select t.id, t.creditordernumber, XMLType(t.definition) as xml from EXE_FCB t
            where  t.id = v_id) s
        ,XMLTable('CigResult/Result/Root/ExistingContracts/Contract' --TerminatedContracts   ExistingContracts
                          passing (s.xml) 
                          columns 
                             CodeOfContract varchar2(70) path 'CodeOfContract/@value' --Код контракта
                             ,AgreementNumber varchar2(50) path 'AgreementNumber/@value'  --Номер договора
                             ,PaymentsCalendar XMLType path 'PaymentsCalendar'
                          ) a
        ,XMLTable('PaymentsCalendar' 
                          passing (a.PaymentsCalendar) 
                          columns 
                              Payment  XMLType path 'Payment'  
                          ) b  
        ,XMLTable('Payment' 
                          passing (b.Payment) 
                          columns 
                               title  varchar2(100) path '@title' 
                              ,overdue_days varchar2(100) path '@value'
                  ) c;
        
        insert into FCB_PaymentsCalendar
        select 
           s.id
           ,s.creditordernumber as Loan_ID
           ,'TerminatedContracts' as ContractType
           ,a.CodeOfContract
           ,a.AgreementNumber
           ,'20'||substr(c.title, INSTR (c.title,'/')+1, length(c.title)) as yyyy
           ,substr(c.title, 1, INSTR (c.title,'/')-1) as mm   
           ,c.overdue_days
           ,cast ('' as VARCHAR2(50 BYTE)) as overdue
           --,s.*
        from
            (select t.id, t.creditordernumber, XMLType(t.definition) as xml from EXE_FCB t
            where  t.id = v_id) s
        ,XMLTable('CigResult/Result/Root/TerminatedContracts/Contract' --TerminatedContracts   ExistingContracts
                          passing (s.xml) 
                          columns 
                             CodeOfContract varchar2(70) path 'CodeOfContract/@value' --Код контракта
                             ,AgreementNumber varchar2(50) path 'AgreementNumber/@value'  --Номер договора
                             ,PaymentsCalendar XMLType path 'PaymentsCalendar'
                          ) a
        ,XMLTable('PaymentsCalendar' 
                          passing (a.PaymentsCalendar) 
                          columns 
                              Payment  XMLType path 'Payment'  
                          ) b  
        ,XMLTable('Payment' 
                          passing (b.Payment) 
                          columns 
                               title  varchar2(100) path '@title' 
                              ,overdue_days varchar2(100) path '@value'
                  ) c;                    
        commit;                                  
     exception
       when others then
         rollback;
         p_info:= Fill_Info(
                  sqlcode
                  ,sqlerrm
                  ,Dbms_Utility.format_error_stack
                  ,Dbms_Utility.format_call_stack
                  ,Dbms_Utility.format_error_backtrace
             );
         insert into FCB_err (id, info) values(v_id,p_info);

         commit;
         null;
     end;
     
  end loop;
  commit;
  close cur;     
end;


procedure FCB_parsing_4_2 is
   TYPE CurTyp IS REF CURSOR;  
   cur   CurTyp;  
   v_id varchar2(100);
   p_info  xmltype;   
   
begin
  OPEN cur FOR  
     'select distinct t.id from EXE_FCB t
      left join FCB_err a on a.id = t.id
      left join FCB_PaymentsCalendar b on b.id = t.id
      where a.id is null and b.id is null'; -- USING v_max_id;
  loop
     fetch cur into v_id ;
     EXIT WHEN cur%NOTFOUND;

     begin
        insert 
        into FCB_PaymentsCalendar
        select 
           s.id
           ,s.creditordernumber as Loan_ID
           ,'ExistingContracts' as ContractType
           ,a.CodeOfContract
           ,a.AgreementNumber
           ,b.title as yyyy
           ,c.number_ as mm   
           ,c.value_ as overdue_days
           ,c.overdue
           --,s.*
        from
            (select t.id, t.creditordernumber, XMLType(t.definition) as xml from EXE_FCB t
            where  t.id = v_id) s
        ,XMLTable('CigResult/Result/Root/ExistingContracts/Contract' --TerminatedContracts   ExistingContracts
                          passing (s.xml) 
                          columns 
                             CodeOfContract varchar2(70) path 'CodeOfContract/@value' --Код контракта
                             ,AgreementNumber varchar2(50) path 'AgreementNumber/@value'  --Номер договора
                             ,PaymentsCalendar XMLType path 'PaymentsCalendar'
                 ) a
        ,XMLTable('PaymentsCalendar/Year' 
                          passing (a.PaymentsCalendar) 
                          columns 
                              title varchar2(100) path '@title'
                              ,Payment  XMLType path 'Payment'  
                 ) b  
        ,XMLTable('Payment' 
                          passing (b.Payment) 
                          columns 
                              number_ varchar2(100) path '@number'
                              ,overdue varchar2(100) path '@overdue'
                              ,value_ varchar2(100) path '@value'
                  ) c;  

        insert into FCB_PaymentsCalendar
        select 
           s.id
           ,s.creditordernumber as Loan_ID
           ,'TerminatedContracts' as ContractType
           ,a.CodeOfContract
           ,a.AgreementNumber
           ,b.title as yyyy
           ,c.number_ as mm   
           ,c.value_ as overdue_days
           ,c.overdue
           --,s.*
        from
            (select t.id, t.creditordernumber, XMLType(t.definition) as xml from EXE_FCB t
            where  t.id = v_id) s
        ,XMLTable('CigResult/Result/Root/TerminatedContracts/Contract' --TerminatedContracts   ExistingContracts
                          passing (s.xml) 
                          columns 
                             CodeOfContract varchar2(70) path 'CodeOfContract/@value' --Код контракта
                             ,AgreementNumber varchar2(50) path 'AgreementNumber/@value'  --Номер договора
                             ,PaymentsCalendar XMLType path 'PaymentsCalendar'
                 ) a
        ,XMLTable('PaymentsCalendar/Year' 
                          passing (a.PaymentsCalendar) 
                          columns 
                              title varchar2(100) path '@title'
                              ,Payment  XMLType path 'Payment'  
                 ) b  
        ,XMLTable('Payment' 
                          passing (b.Payment) 
                          columns 
                              number_ varchar2(100) path '@number'
                              ,overdue varchar2(100) path '@overdue'
                              ,value_ varchar2(100) path '@value'
                  ) c;                             
        commit;                                  
     exception
       when others then
         rollback;
         p_info:= Fill_Info(
                  sqlcode
                  ,sqlerrm
                  ,Dbms_Utility.format_error_stack
                  ,Dbms_Utility.format_call_stack
                  ,Dbms_Utility.format_error_backtrace
             );
         insert into FCB_err (id, info) values(v_id,p_info);

         commit;
         null;
     end;
     
  end loop;
  commit;
  close cur;     
end;


procedure AR is
begin
  execute immediate ('truncate table LOAN_REQUEST_APPROV_SCOR');
  insert into  LOAN_REQUEST_APPROV_SCOR
  select * from V_LOAN_REQUEST_APPROV_SCOR t;
  commit;
  
  execute immediate ('truncate table LOAN_REQUEST_REJECT_CANCEL');
  insert into LOAN_REQUEST_REJECT_CANCEL
  select * from V_LOAN_REQUEST_REJECT_CANCEL t;
  commit;
  
  execute immediate ('truncate table UWI_DETAIL_STAGES');
  insert /*+ parallel(8) append*/
  into UWI_DETAIL_STAGES
  select * from UWI_DETAIL_STAGES_0_1
  ;
  commit;
  execute immediate ('truncate table UWI_DETAIL_STAGES_2');
  insert /*+ parallel(8) append*/
  into UWI_DETAIL_STAGES_2
  select distinct * from UWI_DETAIL_STAGES_0_2
  ;
  commit;

  execute immediate ('truncate table UWI_DETAIL_STAGES_3');
  insert /*+ parallel(8) append*/
  into UWI_DETAIL_STAGES_3
  select distinct * from UWI_DETAIL_STAGES_0_3
  ;
  commit;

end;

procedure DCA_MAX is
begin
  execute immediate ('truncate table DCA_MAX_CLI');
  insert /*+ append */ 
  into DCA_MAX_CLI
  select load_id , rpt_date, code,  max(pd) as pd
  from DWH.DCA_TRGT_PD
  where pd_type = 1 and trunc(rpt_date, 'MM') >=trunc(to_date('01.05.2015'), 'MM') and load_id not in 
      --(select load_id from DCA_EXCEPTION) 
      (1000261,1000200)
  group by code, rpt_date, load_id;  
  
  execute immediate ('truncate table DCA_MAX_IIN');
  insert /*+ append */ 
  into DCA_MAX_IIN
  select t.load_id , t.rpt_date, a.iin,  max(t.pd) as pd from dca_max_cli t
  left join (
      select distinct iin,cli_code  from
      (select * from dwh_buffer.dm_cif_base
       union all 
       select * from dwh_buffer.dm_cif_base_20151229
      )
  ) a on a.cli_code = t.code
  where a.iin is not null
  group by iin, rpt_date, load_id;       

  /*select t.load_id , t.rpt_date, a.iin,  max(t.pd) as pd from dca_max_cli t
  left join dwh_buffer.dm_cif_base a on a.cli_code = t.code
  where a.iin is not null
  group by iin, rpt_date, load_id; */
  
end;


procedure get_dp_covd2_v2 is
begin
  execute immediate ('truncate table dp_covd2_v2_tmp');
/*история периодов непрерывных просрочек на основе истории начисления просрочек по телу кредита
грейс по сумме просрочки(по телу) <1000*/
--CREATE TABLE dp_covd2_v2 AS
insert /*+ parallel(32) append */ into dp_covd2_v2_tmp
SELECT refer,
  SUM(1) over (partition BY refer order by ovd_cnter) AS ovd_cnter,
  start_date,
  end_date
FROM
  (SELECT a4.refer,
    a4.ovd_cnter,
    DECODE(start_date, DATE '3999-01-01',end_date,start_date) AS start_date,                                          --обяз апдейт. необходим для корректного рассчета истории по записям с 0й просрочкой
    DECODE(end_date,   DATE '1900-01-01', /*on_date*/ (select max(zz.dt) from dwh_risk.CREDIT_PORTFOLIO3 zz where zz.refer_wh = a4.refer) ,                                                                    --on_date - опецрационный день - макс. доступный fromdate из архива просроченных ОД
    DECODE(SIGN(DECODE(start_date, DATE '3999-01-01',end_date,start_date)-end_date),1, /*on_date*/
      (select max(zz.dt) from dwh_risk.CREDIT_PORTFOLIO3 zz where zz.refer_wh = a4.refer)
      ,end_date )) AS end_date --обяз. апдейт, необходим для корректного рассчета истории по сделкам находившихся в просрочке на момент выгрузки
  FROM
    (SELECT a3.refer,
      MAX(a3.ovd_fromdate_max) AS ovd_fromdate_max,
      ovd_cnter,                                           --счетчик выхода в просрочку(+1 за каждый новый период)
      MIN(NVL(ovd_date, DATE '3999-01-01')) AS start_date, --начала периода непрерывной просрочки
      MAX(NVL(end__date,DATE '1900-01-01')) AS end_date    --завершение периода непрерывной просрочки
    FROM
      (SELECT a2.ovd_fromdate_max,
        a2.refer,
        a2.end_date AS end__date,
        a2.ovd_date,
        SUM(DECODE(ovd_date,NULL,1,0)) over (partition BY refer order by fromdate) AS ovd_cnter
      FROM
        (SELECT a1.ovd_fromdate_max,
          a1.refer,
          a1.fromdate,
          a1.rval,
          CASE
            WHEN NVL(rval_lead,0) < 1000
            THEN fromdate_lead
            ELSE NULL
          END AS end_date,
          CASE
            WHEN NVL(rval,0) < 1000
            THEN NULL
            ELSE fromdate
          END AS ovd_date
        FROM
          (SELECT aa.*,
            lead(rval,1) over(partition BY refer order by fromdate)                        AS rval_lead,
            lead(fromdate,1) over(partition BY refer order by fromdate)                    AS fromdate_lead,
            lag(rval,1) over(partition BY refer order by fromdate)                         AS rval_lag,
            MAX(DECODE(SIGN(rval),1,fromdate,DATE '1900-01-01')) over (partition BY refer) AS ovd_fromdate_max
          FROM --dp_tod_corp_id_e2 
             (select REFER_WH as REFER , ovrd_main_equ as RVAL, dt as fromdate from dwh_risk.CREDIT_PORTFOLIO3 --where 1=2
               --where REFER_WH = '020602001203065356690'
             )aa

            --WHERE refer = '020802001006222926432'--'040104001411256463482'
          ) a1
        WHERE (NVL(a1.rval,0)<>NVL(a1.rval_lag,0)
        OR NVL(a1.rval,0)    <> 0)
        ) a2
      ) a3
    WHERE ovd_date IS NOT NULL
    OR end__date   IS NOT NULL
    GROUP BY a3.refer,
      a3.ovd_cnter
    ) a4
  WHERE DECODE(start_date, DATE '3999-01-01',end_date,start_date) <> DECODE(end_date,DATE '1900-01-01', TRUNC(sysdate), end_date)
  ) a5
  
--where 1=2
;
commit;

execute immediate ('truncate table dp_covd2_v2');
insert /*+ parallel(4) append */ into dp_covd2_v2
SELECT * from dp_covd2_v2_tmp; 
commit;

end;

procedure get_loyal_of_cp is
   v_dt date;
begin
/*
Условие
05.11.2015

Лояльные клиенты АО «АТФБанк»  – физические лица, соответствующие всем следующим минимальным требованиям:
-+  срок обслуживания займа в АО «АТФБанк» (как действующего, так и погашенного) не менее  6 (шести) месяцев;
-+-  отсутствие на момент рассмотрения заявки просрочки по действующим займам АО «АТФБанк»;
-+-  погашенная просрочка не более 30 (тридцати) дней и не более 1 (одного) раза за последние 6 (шесть) 
   месяцев обслуживания займа в АО «АТФБанк»;
-+  давность погашения займа не более 24 (двадцати четырех) месяцев на момент подачи заявления.

*/
  /*execute immediate ('truncate table calc_loyal_01');
  insert \*+append*\ into calc_loyal_01
  select distinct t.F7 IIN from v_cp_h t
  left join XLS_H_TAXPAYER_KAZ a on a.bin = t.F7
  where a.bin is null;
  commit;*/
  
  select max(t.report_dt) into v_dt from v_cp_h t;
  
  execute immediate ('truncate table calc_loyal_01');
  insert /*+append*/ into calc_loyal_01
  select  t.f7 as iin
          ,t.report_dt
          ,trunc(t.report_dt,'MM') mm
          ,max(t.F82) as ovrd_max
          ,count(distinct t.report_dt) over (partition by t.f7) as cnt
          ,case when t.report_dt >= add_months(sysdate,-6) and  max(t.F82) > 30 then 1 else 0 end as is_ovrd30_6m
          ,case when t.report_dt >= add_months(sysdate,-6) and  max(t.F82) > 0 then 1 else 0 end as is_ovrd_6m
          ,case when t.report_dt = v_dt and max(t.F82) > 30 then 1 else 0 end as is_ovrd_cur
  from v_cp_h t --КП от Галыма
  left join (select distinct bin from XLS_H_TAXPAYER_KAZ) a on a.bin = t.F7 --база полученная с НК
  where trunc(t.report_dt,'MM') >= add_months(sysdate,-24) --давность погашения займа не более 24 (двадцати четырех) месяцев на момент подачи заявления
        and a.bin is null -- не ЮЛ
  group by t.f7, t.report_dt;
  
  execute immediate ('truncate table calc_loyal_02');
  insert /*+append*/ into calc_loyal_02
  select distinct iin as iin 
  from calc_loyal_01 t
  where t.cnt >=6 -- срок обслуживания займа не менее 6 месяцев
        and t.is_ovrd30_6m = 0 -- просрочка не более 30 дней 
        and t.is_ovrd_cur = 0 --отсутствие на момент рассмотрения заявки просрочки по действующим займам
  group by  iin
  having sum(t.is_ovrd_6m) <2; --погашенная просрочка не более 1 раза за последние 6 месяцев   
  commit;
  
  delete from dwh_buffer.LOYAL_FIN;
  commit;
  insert into dwh_buffer.LOYAL_FIN
  select null,null ,t.iin, null,null from calc_loyal_02 t;
  commit;
  
end;

BEGIN
   --SetColvirNlsParams; -- NLS параметры Колвира
   --SetDwhNlsParams;
   null;

end PROCESS;
/

