create or replace package body dwh_buffer.SMTP_MAIL is

  -- Author  : Yuriy-Ch
  -- Created : 11.07.2014 15:03:50
  -- Purpose : SEND EMAILS

gc_smtp_host constant varchar2(100):='10.185.10.50'; --'CYRAX.corp.atfbank.kz';
gc_smtp_port constant number:=25;
gc_auto_text constant varchar2(500):='Данное сообщение создано автоматически. Ответ на него не требуется.';
--gc_user constant varchar2(100):='';
--gc_user_pwd constant varchar2(100):='';
gc_boundary    VARCHAR2(50) := '----=*#abc1234321cba#*=------@dasd+++====';

---------------
FUNCTION address_email( p_string IN VARCHAR2,
                        p_recipients IN t_email_tab,
                        p_mailcon in out nocopy UTL_SMTP.connection 
                       ) RETURN VARCHAR2 
IS
 l_recipients LONG;
 i pls_integer;
 l_reply utl_smtp.reply;
BEGIN
 IF p_recipients.count>0 then
   i:=p_recipients.first; 
   while i is not null
   LOOP
     l_reply:=utl_smtp.rcpt(p_mailcon, p_recipients(i) );

     IF ( l_recipients IS NULL )
     THEN
     l_recipients := p_string || p_recipients(i) ;
     ELSE
     l_recipients := l_recipients || ', ' || p_recipients(i);
     END IF;
     i:=p_recipients.next(i);
   END LOOP;
 END IF;
 RETURN l_recipients;
END;
---------------
PROCEDURE send_mail (p_to          IN t_email_tab, --Куда будем отправлять
                     p_from        IN VARCHAR2, --От кого отправим
                     p_subject     IN VARCHAR2, --Тема письма
                     p_text_msg    IN VARCHAR2 DEFAULT NULL, --Тело письма (само письмо)
                     p_cc          IN t_email_tab , --Кого поставим в копию письма
                     p_failure     out varchar2, --Код и описание ошибки
                     p_auto_text   in pls_integer default 1 --Добавлять автотекст или нет
                    )

AS
  l_mail_conn   UTL_SMTP.connection;
  l_to_list LONG;
  l_cc_list LONG;
  --l_reply     utl_smtp.reply;
  l_subject varchar2(2000);
  l_text_msg varchar2(6000);
BEGIN
  l_mail_conn := UTL_SMTP.open_connection(gc_smtp_host, gc_smtp_port);
  UTL_SMTP.helo(l_mail_conn, gc_smtp_port);
  --UTL_SMTP.COMMAND(l_mail_conn,'AUTH LOGIN');
  --UTL_SMTP.COMMAND(l_mail_conn,utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(gc_user))));
  --UTL_SMTP.COMMAND(l_mail_conn,utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(gc_user_pwd))));
  --l_reply:=utl_smtp.rcpt(l_mail_conn, p_from );
  UTL_SMTP.mail(l_mail_conn, p_from);

  l_to_list := address_email('To: ', p_to, l_mail_conn);

  if (p_cc is not null and p_cc.count>0) then
     l_cc_list := address_email( 'Cc: ', p_cc, l_mail_conn );
  end if;

  l_subject:=p_subject;
  l_text_msg:=p_text_msg;


  UTL_SMTP.open_data(l_mail_conn);

  UTL_SMTP.write_data(l_mail_conn, 'Date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || UTL_TCP.crlf);

  UTL_SMTP.write_data(l_mail_conn, 'From: ' || p_from || UTL_TCP.crlf);

  UTL_SMTP.write_raw_data(l_mail_conn,    UTL_RAW.cast_to_raw('Subject: ' || NVL(l_subject, '(no subject)') || UTL_TCP.crlf));

  Utl_smtp.write_data( l_mail_conn, l_to_list || UTL_TCP.crlf );

  IF ( l_cc_list IS NOT NULL )  THEN
      Utl_smtp.write_data( l_mail_conn, l_cc_list || UTL_TCP.crlf );
  END IF;

  -- UTL_SMTP.write_data(l_mail_conn, 'Reply-To: ' || p_from || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'MIME-Version: 1.0' || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Content-Type: multipart/mixed; boundary="' || gc_boundary || '"' || UTL_TCP.crlf || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Content-Transfer-Encoding: 8bit' || UTL_TCP.crlf);

  IF p_text_msg IS NOT NULL THEN
     UTL_SMTP.write_data(l_mail_conn, '--' || gc_boundary || UTL_TCP.crlf);
     UTL_SMTP.write_data(l_mail_conn, 'Content-Type: text/plain; charset ="utf8"' || UTL_TCP.crlf || UTL_TCP.crlf); --charset="windows-1251"
     UTL_SMTP.write_raw_data(l_mail_conn,utl_raw.cast_to_raw(l_text_msg));
     UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
  END IF;

  if (p_auto_text=1) then
   UTL_SMTP.write_raw_data(l_mail_conn,utl_raw.cast_to_raw(gc_auto_text));
   UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
  end if;

  UTL_SMTP.write_data(l_mail_conn, '--' || gc_boundary || '--' || UTL_TCP.crlf);
  UTL_SMTP.close_data(l_mail_conn);

  UTL_SMTP.quit(l_mail_conn);

  exception
   when others then
    p_failure:=sqlerrm;
    begin UTL_SMTP.quit(l_mail_conn); exception when others then null; end;
end;


------------
--WITH BLOB
PROCEDURE send_mail_blob (p_to             IN t_email_tab , --Куда будем отправлять
                          p_from           IN VARCHAR2, --От кого отправим
                          p_subject        IN VARCHAR2, --Тема письма
                          p_text_msg       IN VARCHAR2 DEFAULT NULL, --Тело письма (само письмо)
                          p_cc             IN t_email_tab , --Кого поставим в копию письма
                          p_failure        out varchar2, --Код и описание ошибки
                          p_AttachmentList in t_attachment_tab,
                          p_auto_text      in pls_integer default 1 --Добавлять автотекст или нет
                         )
AS
  l_mail_conn   UTL_SMTP.connection;
  l_step        PLS_INTEGER  := 18000;
  l_to_list LONG;
  l_cc_list LONG;
  --l_reply     utl_smtp.reply;
  l_subject varchar2(2000);
  l_text_msg varchar2(5000);
BEGIN
  l_mail_conn := UTL_SMTP.open_connection(gc_smtp_host, gc_smtp_port);
  UTL_SMTP.helo(l_mail_conn, gc_smtp_host);
  --UTL_SMTP.COMMAND(l_mail_conn,'AUTH LOGIN');
  --UTL_SMTP.COMMAND(l_mail_conn,utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(p_user))));
  --UTL_SMTP.COMMAND(l_mail_conn,utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(p_user_pwd))));
  UTL_SMTP.mail(l_mail_conn, p_from);
  l_to_list := address_email( 'To: ', p_to,l_mail_conn );

  if (p_cc is not null ) then
      -- if p_cc(1) is not null then
      l_cc_list := address_email( 'Cc: ', p_cc, l_mail_conn );
      --end if;
  end if;

  l_subject:=p_subject;
  l_text_msg:=p_text_msg;

  UTL_SMTP.open_data(l_mail_conn);

  UTL_SMTP.write_data(l_mail_conn, 'Date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || UTL_TCP.crlf);

  UTL_SMTP.write_data(l_mail_conn, 'From: ' || p_from || UTL_TCP.crlf);

  UTL_SMTP.write_raw_data(l_mail_conn,    UTL_RAW.cast_to_raw('Subject: ' ||NVL(l_subject, '(no subject)') || UTL_TCP.crlf));

  Utl_smtp.write_data( l_mail_conn, l_to_list || UTL_TCP.crlf );

  IF ( l_cc_list IS NOT NULL ) THEN
     Utl_smtp.write_data( l_mail_conn, l_cc_list || UTL_TCP.crlf );
  END IF;

  UTL_SMTP.write_data(l_mail_conn, 'Reply-To: ' || p_from || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'MIME-Version: 1.0' || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Content-Type: multipart/mixed; boundary="' || gc_boundary || '"' || UTL_TCP.crlf || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Content-Transfer-Encoding: 8bit' || UTL_TCP.crlf);

  IF p_text_msg IS NOT NULL THEN
     UTL_SMTP.write_data(l_mail_conn, '--' || gc_boundary || UTL_TCP.crlf);
     UTL_SMTP.write_data(l_mail_conn, 'Content-Type: text/plain; charset="utf8"' || UTL_TCP.crlf || UTL_TCP.crlf); --windows-1251

     UTL_SMTP.write_raw_data(l_mail_conn,utl_raw.cast_to_raw(l_text_msg));
     UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
  END IF;

  if (p_auto_text=1) then
     UTL_SMTP.write_raw_data(l_mail_conn,utl_raw.cast_to_raw(gc_auto_text));
     UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
  end if;

  if p_AttachmentList.count>0 then
    for i in 1..p_AttachmentList.count loop
        IF p_AttachmentList(i).p_attach_name IS NOT NULL THEN
          UTL_SMTP.write_data(l_mail_conn, '--' || gc_boundary || UTL_TCP.crlf);
          UTL_SMTP.write_data(l_mail_conn, 'Content-Type: ' || p_AttachmentList(i).p_attach_mime || '; name="' || p_AttachmentList(i).p_attach_name || '"' || UTL_TCP.crlf);
          UTL_SMTP.write_data(l_mail_conn, 'Content-Transfer-Encoding: base64' || UTL_TCP.crlf);
          UTL_SMTP.write_data(l_mail_conn, 'Content-Disposition: attachment; filename="' || p_AttachmentList(i).p_attach_name || '"' || UTL_TCP.crlf || UTL_TCP.crlf);

          FOR j IN 0 .. TRUNC((DBMS_LOB.getlength(p_AttachmentList(i).p_attach_blob) - 1 )/l_step) LOOP
            UTL_SMTP.write_data(l_mail_conn, UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(DBMS_LOB.substr(p_AttachmentList(i).p_attach_blob, l_step, j * l_step + 1))));
          END LOOP;

          UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
        END IF;
    end loop;
  end if;

  UTL_SMTP.write_data(l_mail_conn, '--' || gc_boundary || '--' || UTL_TCP.crlf);
  UTL_SMTP.close_data(l_mail_conn);

  UTL_SMTP.quit(l_mail_conn);

  exception
   when others then
    p_failure:=sqlerrm;
    begin UTL_SMTP.quit(l_mail_conn); exception when others then null; end;
end;

/*PROCEDURE send_mail_html (             p_to          IN ARRAY , --Куда будем отправлять
                                       p_from        IN VARCHAR2, --От кого отправим
                                       p_subject     IN VARCHAR2, --Тема письма
                                       p_text_msg    IN clob DEFAULT NULL, --Тело письма (само письмо)
                                       p_cc IN ARRAY , --Кого поставим в копию письма
                                       p_gc_auto_text in pls_integer, --Добавлять автотекст или нет
                                       serr out varchar2 --Код и описание ошибки
                                       )

 AS
  l_mail_conn   UTL_SMTP.connection;
  gc_boundary    VARCHAR2(50) := '----=*#abc1234321cba#*=';
  l_to_list LONG;
  l_cc_list LONG;
  l_reply     utl_smtp.reply;
  l_subject varchar2(2000);
  l_text_msg clob;
  l_text_raw raw(8000);

FUNCTION address_email( p_string IN VARCHAR2,
 p_recipients IN ARRAY) RETURN VARCHAR2 IS
 l_recipients LONG;
 BEGIN
 FOR i IN 1 .. p_recipients.COUNT
 LOOP

 l_reply:=utl_smtp.rcpt(l_mail_conn, p_recipients(i) );


 IF ( l_recipients IS NULL )
 THEN
 l_recipients := p_string || p_recipients(i) ;
 ELSE
 l_recipients := l_recipients || ', ' || p_recipients(i);
 END IF;
 END LOOP;
 RETURN l_recipients;
 END;

BEGIN
  l_mail_conn := UTL_SMTP.open_connection(gc_smtp_host, gc_smtp_port);
  UTL_SMTP.helo(l_mail_conn, gc_smtp_host);
  UTL_SMTP.COMMAND(l_mail_conn,'AUTH LOGIN');
  UTL_SMTP.COMMAND(l_mail_conn,utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(p_user))));
  UTL_SMTP.COMMAND(l_mail_conn,utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(p_user_pwd))));
  UTL_SMTP.mail(l_mail_conn, p_from);
  l_to_list := address_email( 'To: ', p_to );

  if (p_cc is not null ) then
     l_cc_list := address_email( 'Cc: ', p_cc );
  end if;

  l_subject:=p_subject;
  l_text_msg:=p_text_msg;

  if pklib.pfDbN<>'VB6M' then
   l_subject:='Тест. '||l_subject;
   l_text_msg:='Данное сообщение отправлено с тестового сервера. '||chr(13)||chr(10)||l_text_msg;
  end if;

  UTL_SMTP.open_data(l_mail_conn);

  UTL_SMTP.write_data(l_mail_conn, 'Date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || UTL_TCP.crlf);

  UTL_SMTP.write_data(l_mail_conn, 'From: ' || p_from || UTL_TCP.crlf);

  UTL_SMTP.write_raw_data(l_mail_conn,    UTL_RAW.cast_to_raw('Subject: ' || SUBJ_ENCODE(NVL(l_subject, '(no subject)')) || UTL_TCP.crlf));


  Utl_smtp.write_data( l_mail_conn, l_to_list || UTL_TCP.crlf );

   IF ( l_cc_list IS NOT NULL )
   THEN
   Utl_smtp.write_data( l_mail_conn, l_cc_list || UTL_TCP.crlf );
   END IF;

 -- UTL_SMTP.write_data(l_mail_conn, 'Reply-To: ' || p_from || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'MIME-Version: 1.0' || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Content-Type: multipart/mixed; boundary="' || gc_boundary || '"' || UTL_TCP.crlf || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Content-Transfer-Encoding: 8bit' || UTL_TCP.crlf);

  IF p_text_msg IS NOT NULL THEN
    UTL_SMTP.write_data(l_mail_conn, '--' || gc_boundary || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Content-Type: text/html; charset ="utf8"' || UTL_TCP.crlf || UTL_TCP.crlf); --charset="windows-1251"
    l_text_msg := TEXT_ENCODE_HTML(l_text_msg);
    while length(l_text_msg) > 0 loop
      l_text_raw := utl_raw.cast_to_raw(substr(l_text_msg,1,4000));
      l_text_msg := substr(l_text_msg,4001);
      UTL_SMTP.write_raw_data(l_mail_conn,l_text_raw);
   end loop;
--   UTL_SMTP.write_raw_data(l_mail_conn,utl_raw.cast_to_raw( TEXT_ENCODE_HTML(l_text_msg) ));

   UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
  END IF;

  if (p_gc_auto_text=1) then
   --utl_smtp.write_data(l_mail_conn, '<br><br>');
   UTL_SMTP.write_raw_data(l_mail_conn,utl_raw.cast_to_raw(TEXT_ENCODE(gc_auto_text)));
   UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);

   end if;



  UTL_SMTP.write_data(l_mail_conn, '--' || gc_boundary || '--' || UTL_TCP.crlf);
  UTL_SMTP.close_data(l_mail_conn);

  UTL_SMTP.quit(l_mail_conn);

  exception
   when others then
    serr:=sqlerrm;
    begin UTL_SMTP.quit(l_mail_conn); exception when others then null; end;

end;

*/

---------------------------
--WITH CLOB
PROCEDURE send_mail_clob (p_to             IN t_email_tab , --Куда будем отправлять
                          p_from           IN VARCHAR2, --От кого отправим
                          p_subject        IN VARCHAR2, --Тема письма
                          p_text_msg       IN VARCHAR2 DEFAULT NULL, --Тело письма (само письмо)
                          p_cc             IN t_email_tab , --Кого поставим в копию письма
                          p_failure        out varchar2, --Код и описание ошибки
                          p_AttachmentList in t_AttachmentsClob_tab,
                          p_auto_text      in pls_integer default 1 --Добавлять автотекст или нет
                         )
AS
  l_mail_conn   UTL_SMTP.connection;
  l_step        PLS_INTEGER  := 18000;
  l_to_list LONG;
  l_cc_list LONG;
  --l_reply     utl_smtp.reply;
  l_subject varchar2(2000);
  l_text_msg varchar2(5000);
BEGIN
  l_mail_conn := UTL_SMTP.open_connection(gc_smtp_host, gc_smtp_port);
  UTL_SMTP.helo(l_mail_conn, gc_smtp_host);
  --UTL_SMTP.COMMAND(l_mail_conn,'AUTH LOGIN');
  --UTL_SMTP.COMMAND(l_mail_conn,utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(p_user))));
  --UTL_SMTP.COMMAND(l_mail_conn,utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(p_user_pwd))));
  UTL_SMTP.mail(l_mail_conn, p_from);
  l_to_list := address_email( 'To: ', p_to, l_mail_conn );

  if (p_cc is not null ) then
      -- if p_cc(1) is not null then
      l_cc_list := address_email( 'Cc: ', p_cc, l_mail_conn );
      --end if;
  end if;

  l_subject:=p_subject;
  l_text_msg:=p_text_msg;

  UTL_SMTP.open_data(l_mail_conn);

  UTL_SMTP.write_data(l_mail_conn, 'Date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || UTL_TCP.crlf);

  UTL_SMTP.write_data(l_mail_conn, 'From: ' || p_from || UTL_TCP.crlf);

  UTL_SMTP.write_raw_data(l_mail_conn,    UTL_RAW.cast_to_raw('Subject: ' || NVL(l_subject, '(no subject)') || UTL_TCP.crlf));


  Utl_smtp.write_data( l_mail_conn, l_to_list || UTL_TCP.crlf );

  IF ( l_cc_list IS NOT NULL )  THEN
       Utl_smtp.write_data( l_mail_conn, l_cc_list || UTL_TCP.crlf );
  END IF;

  UTL_SMTP.write_data(l_mail_conn, 'Reply-To: ' || p_from || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'MIME-Version: 1.0' || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Content-Type: multipart/mixed; boundary="' || gc_boundary || '"' || UTL_TCP.crlf || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Content-Transfer-Encoding: 8bit' || UTL_TCP.crlf);

  IF p_text_msg IS NOT NULL THEN
    UTL_SMTP.write_data(l_mail_conn, '--' || gc_boundary || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Content-Type: text/plain; charset="utf8"' || UTL_TCP.crlf || UTL_TCP.crlf); --windows-1251
    UTL_SMTP.write_raw_data(l_mail_conn,utl_raw.cast_to_raw(l_text_msg));
    UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
  END IF;

  if (p_auto_text=1) then
     --utl_smtp.write_data(l_mail_conn, '<br><br>');
     UTL_SMTP.write_raw_data(l_mail_conn,utl_raw.cast_to_raw(gc_auto_text));
     UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
  end if;

  if p_AttachmentList.count>0 then
    for i in 1..p_AttachmentList.count loop
        IF p_AttachmentList(i).p_attach_name IS NOT NULL THEN
          UTL_SMTP.write_data(l_mail_conn, '--' || gc_boundary || UTL_TCP.crlf);
          UTL_SMTP.write_data(l_mail_conn, 'Content-Type: ' || p_AttachmentList(i).p_attach_mime || '; name="' || p_AttachmentList(i).p_attach_name || '"' || UTL_TCP.crlf);
          UTL_SMTP.write_data(l_mail_conn, 'Content-Transfer-Encoding: base64' || UTL_TCP.crlf);
          UTL_SMTP.write_data(l_mail_conn, 'Content-Disposition: attachment; filename="' || p_AttachmentList(i).p_attach_name || '"' || UTL_TCP.crlf || UTL_TCP.crlf);
          --UTL_SMTP.write_data(l_mail_conn, 'Content-Disposition: attachment; filename="' || p_AttachmentList(i).p_attach_name||'.'||p_AttachmentList(i).p_attach_mime || '"' || UTL_TCP.crlf || UTL_TCP.crlf);

          FOR j IN 0 .. TRUNC((DBMS_LOB.getlength(p_AttachmentList(i).p_attach_clob) - 1 )/l_step) LOOP
            --UTL_SMTP.write_data(l_mail_conn, UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(utl_raw.cast_to_raw(STRTOUTF8(DBMS_LOB.substr(p_AttachmentList(i).p_attach_clob, l_step, j * l_step + 1))   ) )));
            --dbms_output.put_line(UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(utl_raw.cast_to_raw(STRTOUTF8(DBMS_LOB.substr(p_AttachmentList(i).p_attach_clob, l_step, j * l_step + 1))   ) )) );
            --dbms_output.put_line('+++++++++++++');
            UTL_SMTP.write_data(l_mail_conn, UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(utl_raw.cast_to_raw(DBMS_LOB.substr(p_AttachmentList(i).p_attach_clob, l_step, j * l_step + 1)   ) )));
          END LOOP;

          UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
        END IF;
    end loop;
  end if;

  UTL_SMTP.write_data(l_mail_conn, '--' || gc_boundary || '--' || UTL_TCP.crlf);
  UTL_SMTP.close_data(l_mail_conn);

  UTL_SMTP.quit(l_mail_conn);

  exception
   when others then
    p_failure:=sqlerrm;
   begin UTL_SMTP.quit(l_mail_conn); exception when others then null; end;
end;

-------------------------
end SMTP_MAIL;
/

