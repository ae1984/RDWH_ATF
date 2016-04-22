create or replace force view dwh_buffer.v_dm_acc_base_20151027 as
select /*+ ORDERED parallel(a,16) USE_NL(a, ah, la, m, p, s) */
     a.id ID,
     a.dep_id DEP_ID,
     a.id || '_' || a.dep_id IN_SOURCE_ID,
     a.cha_id ID_BAL,
     ah.cli_id CLI_ID,
     ah.clidep_id CLI_DEP_ID,
     (select code from colvir.g_cli@reps where id=ah.cli_id and dep_id = ah.clidep_id) CLI_CODE,
     a.code ACC_CODE,
     la.CODE BAL_CODE,
     (select la3.code from colvir.LEDACC_std@reps LA3
       where la3.NLEVEL = 4
       connect by prior la3.ID_HI = la3.ID
       start with la3.id=la.id) BAL3,
     ah.longname ACC_NAME,
     ah.val_id   VAL_ID,
     (select code from colvir.T_VAL_STD@reps where id=ah.val_id)    VAL_CODE,
     s.name      ACC_STATE,
     ah.arcfl    STATE_ID,
     a.lsttrndt   LAST_TRN,
     a.dreg DATE_OPEN,
     (select min(ah1.fromdate) from colvir.G_ACCBLNHST@reps AH1 where ah1.id = a.id and ah1.dep_id = a.dep_id and ah1.arcfl = 1) DATE_CLOSE
from colvir.G_ACCBLN@reps       A,
       colvir.G_ACCBLNHST@reps    AH,
       colvir.LEDACC_std@reps         LA,
       colvir.T_PROCMEM@reps      m,
       colvir.t_Process@reps      p,
       colvir.T_BOP_STAT_STD@reps S
where a.id = ah.id
   and a.dep_id = ah.dep_id
   and sysdate between ah.fromdate and ah.todate
   and LA.ID = a.cha_id
   and m.ORD_ID = a.ORD_ID
   and m.DEP_ID = a.DEP_ID
   and m.MAINFL = '1'
   and p.ID = m.ID
   and p.bop_id = 1102
   and S.ID = P.BOP_ID
   and S.NORD = P.NSTAT;
grant select on DWH_BUFFER.V_DM_ACC_BASE_20151027 to AIBEK_BE;
grant select on DWH_BUFFER.V_DM_ACC_BASE_20151027 to DWH_PRIM;
grant select on DWH_BUFFER.V_DM_ACC_BASE_20151027 to DWH_RISK;
grant select on DWH_BUFFER.V_DM_ACC_BASE_20151027 to DWH_SALES;
grant select on DWH_BUFFER.V_DM_ACC_BASE_20151027 to HEAD_DENIS_PL;
grant select on DWH_BUFFER.V_DM_ACC_BASE_20151027 to HEAD_EVGENIY_PI;
grant select on DWH_BUFFER.V_DM_ACC_BASE_20151027 to KRISTINA_KO;
grant select on DWH_BUFFER.V_DM_ACC_BASE_20151027 to PROCESS_RISK;
grant select on DWH_BUFFER.V_DM_ACC_BASE_20151027 to PROCESS_SALES;


