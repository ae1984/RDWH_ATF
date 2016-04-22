create or replace force view dwh_buffer.sdbo_registeredclients as
select t."Id",t."FirstName",t."LastName",t."MiddleName",t."Idn",t."Login",t."UserStatus",t."RegDate",t."LastSessionDate", sysdate as SDT from v_RegisteredClients@sdbo_db t;
grant select on DWH_BUFFER.SDBO_REGISTEREDCLIENTS to AIBEK_BE;
grant select on DWH_BUFFER.SDBO_REGISTEREDCLIENTS to DWH_PRIM;
grant select on DWH_BUFFER.SDBO_REGISTEREDCLIENTS to DWH_RISK;
grant select on DWH_BUFFER.SDBO_REGISTEREDCLIENTS to DWH_SALES;
grant select on DWH_BUFFER.SDBO_REGISTEREDCLIENTS to HEAD_DENIS_PL;
grant select on DWH_BUFFER.SDBO_REGISTEREDCLIENTS to HEAD_EVGENIY_PI;
grant select on DWH_BUFFER.SDBO_REGISTEREDCLIENTS to KRISTINA_KO;
grant select on DWH_BUFFER.SDBO_REGISTEREDCLIENTS to PROCESS_RISK;
grant select on DWH_BUFFER.SDBO_REGISTEREDCLIENTS to PROCESS_SALES;


