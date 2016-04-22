create or replace force view dwh_buffer.v_xls_h_nbrk_curr_rate as
select
  to_date(t.dt,'yyyy-mm-dd') as dt
  ,to_number(t.gbp) as gbr
  ,to_number(t.usd) as usd
  ,to_number(t.eur) as eur
  ,to_number(t.rub) as rub
from XLS_H_NBRK_CURR_RATE t;
grant select on DWH_BUFFER.V_XLS_H_NBRK_CURR_RATE to AIBEK_BE;
grant select on DWH_BUFFER.V_XLS_H_NBRK_CURR_RATE to DWH_PRIM;
grant select on DWH_BUFFER.V_XLS_H_NBRK_CURR_RATE to DWH_RISK;
grant select on DWH_BUFFER.V_XLS_H_NBRK_CURR_RATE to DWH_SALES;
grant select on DWH_BUFFER.V_XLS_H_NBRK_CURR_RATE to HEAD_DENIS_PL;
grant select on DWH_BUFFER.V_XLS_H_NBRK_CURR_RATE to HEAD_EVGENIY_PI;
grant select on DWH_BUFFER.V_XLS_H_NBRK_CURR_RATE to KRISTINA_KO;
grant select on DWH_BUFFER.V_XLS_H_NBRK_CURR_RATE to PROCESS_RISK;
grant select on DWH_BUFFER.V_XLS_H_NBRK_CURR_RATE to PROCESS_SALES;


