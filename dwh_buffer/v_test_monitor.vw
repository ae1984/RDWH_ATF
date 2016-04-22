create or replace force view dwh_buffer.v_test_monitor as
select
  trunc(t.startdt) as dt
  ,to_char(t.startdt, 'HH24') as HH24
  ,case when to_char(t.startdt, 'HH24') in ('00','01') then '00-01'
        when to_char(t.startdt, 'HH24') in ('02','03') then '02-03'
        when to_char(t.startdt, 'HH24') in ('04','05') then '04-05'
        when to_char(t.startdt, 'HH24') in ('06','07') then '06-07'
        when to_char(t.startdt, 'HH24') in ('08','09') then '08-09'
        when to_char(t.startdt, 'HH24') in ('10','11') then '10-11'
        when to_char(t.startdt, 'HH24') in ('12','13') then '12-13'
        when to_char(t.startdt, 'HH24') in ('14','15') then '14-15'
        when to_char(t.startdt, 'HH24') in ('16','17') then '16-17'
        when to_char(t.startdt, 'HH24') in ('18','19') then '18-19'
        when to_char(t.startdt, 'HH24') in ('20','21') then '20-21'
        when to_char(t.startdt, 'HH24') in ('22','23') then '22-23'
   end as HH2
  ,case when to_char(t.startdt, 'HH24') in ('00','01','02') then '00-02'
        when to_char(t.startdt, 'HH24') in ('03','04','05') then '03-05'
        when to_char(t.startdt, 'HH24') in ('06','07','08') then '06-08'
        when to_char(t.startdt, 'HH24') in ('09','10','11') then '09-11'
        when to_char(t.startdt, 'HH24') in ('12','13','14') then '12-14'
        when to_char(t.startdt, 'HH24') in ('15','16','17') then '15-17'
        when to_char(t.startdt, 'HH24') in ('18','19','20') then '18-20'
        when to_char(t.startdt, 'HH24') in ('21','22','23') then '21-23'
   end as HH3
  ,case when to_char(t.startdt, 'HH24') in ('00','01','02','03','04','05') then '00-05'
        when to_char(t.startdt, 'HH24') in ('06','07','08','09','10','11') then '06-11'
        when to_char(t.startdt, 'HH24') in ('12','13','14','15','16','17') then '12-17'
        when to_char(t.startdt, 'HH24') in ('18','19','20','21','22','23') then '18-23'
   end as HH6
  ,case when t.NAME in ('TEST_DBLINK','TEST_DELETE') then 'TEST1_JOB'
        when t.NAME in ('TEST_INSERT','TEST_UPDATE','TEST_TRANCATE') then 'TEST2_JOB'
        when t.NAME in ('TEST_DBLINK_W4','TEST_UPDATE2','TEST_DELETE_W4') then 'TEST3_JOB'
        when t.NAME in ('TEST_JOIN','TEST_TRANCATE_JOIN') then 'TEST4_JOB'
   end as GRP
  ,t."ID",t."NAME",t."STARTDT",t."ENDDT",t."DURATION"
from TEST_MONITOR t
where t.startdt >= to_date('07.10.2015 18:00','dd.mm.yyyy hh24:mi');
grant select on DWH_BUFFER.V_TEST_MONITOR to AIBEK_BE;
grant select on DWH_BUFFER.V_TEST_MONITOR to DWH_PRIM;
grant select on DWH_BUFFER.V_TEST_MONITOR to DWH_RISK;
grant select on DWH_BUFFER.V_TEST_MONITOR to DWH_SALES;
grant select on DWH_BUFFER.V_TEST_MONITOR to HEAD_DENIS_PL;
grant select on DWH_BUFFER.V_TEST_MONITOR to HEAD_EVGENIY_PI;
grant select on DWH_BUFFER.V_TEST_MONITOR to KRISTINA_KO;
grant select on DWH_BUFFER.V_TEST_MONITOR to PROCESS_RISK;
grant select on DWH_BUFFER.V_TEST_MONITOR to PROCESS_SALES;


