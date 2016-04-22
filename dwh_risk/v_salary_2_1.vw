create or replace force view dwh_risk.v_salary_2_1 as
select
    mm_p1 mm
   ,t.bin
   ,trunc(avg(t.is_stab_idx) / 0.1) * 0.1 is_stab_idx
from V_SALARY_2 t
group by
    mm_p1
   ,t.bin;

