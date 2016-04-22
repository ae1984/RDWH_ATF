create or replace type dwh_buffer.source_cli_phones_t as object (
  cli_id number,
  phone_type number,
  network_code varchar2(100),
  phone_number varchar2(100),
  full_number varchar2(100),
  like_mobile int
  )
/

