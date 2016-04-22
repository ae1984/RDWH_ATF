create or replace force view dwh_buffer.v_col_synh_tab as
select /*+parallel(8)*/
   t.tname
   ,t.snd_dt
   ,t.id
   ,upper(t.action) action
   ,trim(t.pk1) pk1
   ,b1.field        as field1
   ,b1.data_type    as data_type1
   ,b1.data_length  as data_length1
   ,trim(t.pk2) pk2
   ,b2.field        as field2
   ,b2.data_type    as data_type2
   ,b2.data_length  as data_length2
   ,trim(t.pk3) pk3
   ,b3.field        as field3
   ,b3.data_type    as data_type3
   ,b3.data_length  as data_length3
   ,trim(t.pk4) pk4
   ,b4.field        as field4
   ,b4.data_type    as data_type4
   ,b4.data_length  as data_length4
   ,trim(t.pk5) pk5
   ,b5.field        as field5
   ,b5.data_type    as data_type5
   ,b5.data_length  as data_length5
   ,trim(t.pk6) pk6
   ,b6.field        as field6
   ,b6.data_type    as data_type6
   ,b6.data_length  as data_length6
   ,a.table_name
   ,a.columns_name
from COL_SYNH_TAB t
  left join COL_SYNH_SCHEME b1 on b1.tname = t.tname and b1.col_field = 'PK1'
  left join COL_SYNH_SCHEME b2 on b2.tname = t.tname and b2.col_field = 'PK2'
  left join COL_SYNH_SCHEME b3 on b3.tname = t.tname and b3.col_field = 'PK3'
  left join COL_SYNH_SCHEME b4 on b4.tname = t.tname and b4.col_field = 'PK4'
  left join COL_SYNH_SCHEME b5 on b5.tname = t.tname and b5.col_field = 'PK5'
  left join COL_SYNH_SCHEME b6 on b6.tname = t.tname and b6.col_field = 'PK6'
  join COL_SYNH_2 a on a.table_name = upper('COL_'||t.tname);
grant select on DWH_BUFFER.V_COL_SYNH_TAB to AIBEK_BE;
grant select on DWH_BUFFER.V_COL_SYNH_TAB to DWH_PRIM;
grant select on DWH_BUFFER.V_COL_SYNH_TAB to DWH_RISK;
grant select on DWH_BUFFER.V_COL_SYNH_TAB to DWH_SALES;
grant select on DWH_BUFFER.V_COL_SYNH_TAB to HEAD_DENIS_PL;
grant select on DWH_BUFFER.V_COL_SYNH_TAB to HEAD_EVGENIY_PI;
grant select on DWH_BUFFER.V_COL_SYNH_TAB to KRISTINA_KO;
grant select on DWH_BUFFER.V_COL_SYNH_TAB to PROCESS_RISK;
grant select on DWH_BUFFER.V_COL_SYNH_TAB to PROCESS_SALES;


