create or replace package dwh_buffer.SMTP_MAIL is

  -- Author  : Yuriy-Ch
  -- Created : 11.07.2014 15:03:50
  -- Purpose : SEND EMAILS

  TYPE t_email_tab IS TABLE OF VARCHAR2(255) index by pls_integer;

  type t_attachment is record (
   p_attach_name  VARCHAR2(500) DEFAULT NULL, --�������� �������������� �����
   p_attach_mime  VARCHAR2(50) DEFAULT NULL, --��� �������������� �����
   p_attach_blob  BLOB DEFAULT NULL --���� ��� ������
   );

   type t_attachment_tab is table of t_attachment index by pls_integer;

   type t_attachmentClob is record (
   p_attach_name  VARCHAR2(500) DEFAULT NULL, --�������� �������������� �����
   p_attach_mime  VARCHAR2(50) DEFAULT NULL, --��� �������������� �����
   p_attach_clob  CLOB DEFAULT NULL --C��� ��� ������
   );

   type t_AttachmentsClob_tab is table of t_attachmentClob index by pls_integer;

-----------------------------------------------
PROCEDURE send_mail (p_to IN t_email_tab, --���� ����� ����������
                     p_from        IN VARCHAR2, --�� ���� ��������
                     p_subject     IN VARCHAR2, --���� ������
                     p_text_msg    IN VARCHAR2 DEFAULT NULL, --���� ������ (���� ������)
                     p_cc IN t_email_tab , --���� �������� � ����� ������
                     p_failure out varchar2, --��� � �������� ������
                     p_auto_text in pls_integer default 1 --��������� ��������� ��� ���
                     );

------------
--WITH BLOB
PROCEDURE send_mail_blob (p_to IN t_email_tab , --���� ����� ����������
                                       p_from        IN VARCHAR2, --�� ���� ��������
                                       p_subject     IN VARCHAR2, --���� ������
                                       p_text_msg    IN VARCHAR2 DEFAULT NULL, --���� ������ (���� ������)
                                       p_cc IN t_email_tab , --���� �������� � ����� ������
                                       p_failure out varchar2, --��� � �������� ������
                                       p_AttachmentList in t_attachment_tab,
                                       p_auto_text in pls_integer default 1 --��������� ��������� ��� ���
                                       );
 -------
PROCEDURE send_mail_clob (p_to IN t_email_tab , --���� ����� ����������
                                       p_from        IN VARCHAR2, --�� ���� ��������
                                       p_subject     IN VARCHAR2, --���� ������
                                       p_text_msg    IN VARCHAR2 DEFAULT NULL, --���� ������ (���� ������)
                                       p_cc IN t_email_tab , --���� �������� � ����� ������
                                       p_failure out varchar2, --��� � �������� ������
                                       p_AttachmentList in t_AttachmentsClob_tab,
                                       p_auto_text in pls_integer default 1 --��������� ��������� ��� ���
                                       );
--------
end SMTP_MAIL;
/

