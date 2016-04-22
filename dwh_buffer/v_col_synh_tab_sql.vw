create or replace force view dwh_buffer.v_col_synh_tab_sql as
select
   case when ( t.action in ('D','U','I') ) then 'delete from COL_'||t.tname||' where '
     ||case when length(t.pk1) > 0 and t.data_type1 = 'NUMBER'  then nvl(t.field1||' = '||t.pk1,' ')
            when length(t.pk1) > 0 and t.data_type1 in ('VARCHAR2','CHAR')  then nvl(t.field1||' = '''||t.pk1||'''',' ')
            when length(t.pk1) > 0 and t.data_type1 = 'DATE'  then nvl(t.field1||' = to_date('''||t.pk1||''')',' ')
       end
     ||case when length(t.pk2) > 0 and t.data_type2 = 'NUMBER'  then nvl(' and '||t.field2||' = '||t.pk2,' ')
            when length(t.pk2) > 0 and t.data_type2 in ('VARCHAR2','CHAR')  then nvl(' and '||t.field2||' = '''||t.pk2||'''',' ')
            when length(t.pk2) > 0 and t.data_type2 = 'DATE'  then nvl(' and '||t.field2||' = to_date('''||t.pk2||''')',' ')
       end
     ||case when length(t.pk3) > 0 and t.data_type3 = 'NUMBER'  then nvl(' and '||t.field3||' = '||t.pk3,' ')
            when length(t.pk3) > 0 and t.data_type3 in ('VARCHAR2','CHAR')  then nvl(' and '||t.field3||' = '''||t.pk3||'''',' ')
            when length(t.pk3) > 0 and t.data_type3 = 'DATE'  then nvl(' and '||t.field3||' = to_date('''||t.pk3||''')',' ')
       end
     ||case when length(t.pk4) > 0 and t.data_type4 = 'NUMBER'  then nvl(' and '||t.field4||' = '||t.pk4,' ')
            when length(t.pk4) > 0 and t.data_type4 in ('VARCHAR2','CHAR')  then nvl(' and '||t.field4||' = '''||t.pk4||'''',' ')
            when length(t.pk4) > 0 and t.data_type4 = 'DATE'  then nvl(' and '||t.field4||' = to_date('''||t.pk4||''')',' ')
       end
     ||case when length(t.pk5) > 0 and t.data_type5 = 'NUMBER'  then nvl(' and '||t.field5||' = '||t.pk5,' ')
            when length(t.pk5) > 0 and t.data_type5 in ('VARCHAR2','CHAR')  then nvl(' and '||t.field5||' = '''||t.pk5||'''',' ')
            when length(t.pk5) > 0 and t.data_type5 = 'DATE'  then nvl(' and '||t.field5||' = to_date('''||t.pk5||''')',' ')
       end
     ||case when length(t.pk6) > 0 and t.data_type6 = 'NUMBER'  then nvl(' and '||t.field6||' = '||t.pk6,' ')
            when length(t.pk6) > 0 and t.data_type6 in ('VARCHAR2','CHAR')  then nvl(' and '||t.field6||' = '''||t.pk6||'''',' ')
            when length(t.pk6) > 0 and t.data_type6 = 'DATE'  then nvl(' and '||t.field6||' = to_date('''||t.pk6||''')',' ')
       end
   else null end as sql_1

  ,case when ( t.action in ('U','I') ) then 'insert into '||t.table_name||'('
     ||t.columns_name||') '
     ||' select '|| t.columns_name || ' from colvir.'||t.tname||'@REPS where '
     ||case when length(t.pk1) > 0 and t.data_type1 = 'NUMBER'  then nvl(t.field1||' = '||t.pk1,' ')
            when length(t.pk1) > 0 and t.data_type1 in ('VARCHAR2','CHAR')  then nvl(t.field1||' = '''||t.pk1||'''',' ')
            when length(t.pk1) > 0 and t.data_type1 = 'DATE'  then nvl(t.field1||' = to_date('''||t.pk1||''')',' ')
       end
     ||case when length(t.pk2) > 0 and t.data_type2 = 'NUMBER'  then nvl(' and '||t.field2||' = '||t.pk2,' ')
            when length(t.pk2) > 0 and t.data_type2 in ('VARCHAR2','CHAR')  then nvl(' and '||t.field2||' = '''||t.pk2||'''',' ')
            when length(t.pk2) > 0 and t.data_type2 = 'DATE'  then nvl(' and '||t.field2||' = to_date('''||t.pk2||''')',' ')
       end
     ||case when length(t.pk3) > 0 and t.data_type3 = 'NUMBER'  then nvl(' and '||t.field3||' = '||t.pk3,' ')
            when length(t.pk3) > 0 and t.data_type3 in ('VARCHAR2','CHAR')  then nvl(' and '||t.field3||' = '''||t.pk3||'''',' ')
            when length(t.pk3) > 0 and t.data_type3 = 'DATE'  then nvl(' and '||t.field3||' = to_date('''||t.pk3||''')',' ')
       end
     ||case when length(t.pk4) > 0 and t.data_type4 = 'NUMBER'  then nvl(' and '||t.field4||' = '||t.pk4,' ')
            when length(t.pk4) > 0 and t.data_type4 in ('VARCHAR2','CHAR')  then nvl(' and '||t.field4||' = '''||t.pk4||'''',' ')
            when length(t.pk4) > 0 and t.data_type4 = 'DATE'  then nvl(' and '||t.field4||' = to_date('''||t.pk4||''')',' ')
       end
     ||case when length(t.pk5) > 0 and t.data_type5 = 'NUMBER'  then nvl(' and '||t.field5||' = '||t.pk5,' ')
            when length(t.pk5) > 0 and t.data_type5 in ('VARCHAR2','CHAR')  then nvl(' and '||t.field5||' = '''||t.pk5||'''',' ')
            when length(t.pk5) > 0 and t.data_type5 = 'DATE'  then nvl(' and '||t.field5||' = to_date('''||t.pk5||''')',' ')
       end
     ||case when length(t.pk6) > 0 and t.data_type6 = 'NUMBER'  then nvl(' and '||t.field6||' = '||t.pk6,' ')
            when length(t.pk6) > 0 and t.data_type6 in ('VARCHAR2','CHAR')  then nvl(' and '||t.field6||' = '''||t.pk6||'''',' ')
            when length(t.pk6) > 0 and t.data_type6 = 'DATE'  then nvl(' and '||t.field6||' = to_date('''||t.pk6||''')',' ')
       end
   else null end as sql_2
   ,t."TNAME",t."SND_DT",t."ID",t."ACTION",t."PK1",t."FIELD1",t."DATA_TYPE1",t."DATA_LENGTH1",t."PK2",t."FIELD2",t."DATA_TYPE2",t."DATA_LENGTH2",t."PK3",t."FIELD3",t."DATA_TYPE3",t."DATA_LENGTH3",t."PK4",t."FIELD4",t."DATA_TYPE4",t."DATA_LENGTH4",t."PK5",t."FIELD5",t."DATA_TYPE5",t."DATA_LENGTH5",t."PK6",t."FIELD6",t."DATA_TYPE6",t."DATA_LENGTH6",t."TABLE_NAME",t."COLUMNS_NAME"
from V_COL_SYNH_TAB t
where t.pk1 is not null
--where t.data_type5 is not null --in( 'VARCHAR2','CHAR', 'DATE')
;
grant select on DWH_BUFFER.V_COL_SYNH_TAB_SQL to AIBEK_BE;
grant select on DWH_BUFFER.V_COL_SYNH_TAB_SQL to DWH_PRIM;
grant select on DWH_BUFFER.V_COL_SYNH_TAB_SQL to DWH_RISK;
grant select on DWH_BUFFER.V_COL_SYNH_TAB_SQL to DWH_SALES;
grant select on DWH_BUFFER.V_COL_SYNH_TAB_SQL to HEAD_DENIS_PL;
grant select on DWH_BUFFER.V_COL_SYNH_TAB_SQL to HEAD_EVGENIY_PI;
grant select on DWH_BUFFER.V_COL_SYNH_TAB_SQL to KRISTINA_KO;
grant select on DWH_BUFFER.V_COL_SYNH_TAB_SQL to PROCESS_RISK;
grant select on DWH_BUFFER.V_COL_SYNH_TAB_SQL to PROCESS_SALES;


