CREATE OR REPLACE FORCE VIEW DWH_BUFFER.V_ETL_SCHED AS
SELECT
   t.id
   ,t.action_name
   , null as options
   , null as state
   , null as eventtype
   , trunc(t.created) AS ActualStart
   , trunc(nvl(t.updated,sysdate)) AS ActualFinish
   , null as location_id
   , null as  locationname
   ,case
       when t.state = 'COMPLETED' then 10025880
       when t.state = 'FAILED' then 6506495
       when t.state = 'STOPPED' then 12632256
       else 65535
    end as  labelcolor
   --, 10025880 as  labelcolor --успешно
   --, 12632256 as  labelcolor --остановлен
   --, 6506495 as  labelcolor --ошибка
   --, 65535 as  labelcolor --в процессе
   , t.created as startdt
   , nvl(t.updated,sysdate) as enddt
   , nvl(to_char(t.duration),'в процессе...') AS label
FROM ETL_ACTIONS_LOG t
where t.created >= trunc(sysdate-31)
order by id desc
;
grant select on DWH_BUFFER.V_ETL_SCHED to AIBEK_BE;
grant select on DWH_BUFFER.V_ETL_SCHED to DWH_PRIM;
grant select on DWH_BUFFER.V_ETL_SCHED to DWH_RISK;
grant select on DWH_BUFFER.V_ETL_SCHED to DWH_SALES;
grant select on DWH_BUFFER.V_ETL_SCHED to HEAD_DENIS_PL;
grant select on DWH_BUFFER.V_ETL_SCHED to HEAD_EVGENIY_PI;
grant select on DWH_BUFFER.V_ETL_SCHED to KRISTINA_KO;
grant select on DWH_BUFFER.V_ETL_SCHED to PROCESS_RISK;
grant select on DWH_BUFFER.V_ETL_SCHED to PROCESS_SALES;


