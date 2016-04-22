create or replace force view dwh_risk.v_salary_mm as
select /*+ parallel(32) */
      t.mm
     ,t.iin_cl
     ,t.bin
     ,is_have_bin
     ,sum(amt) amt
from (
  select
     trunc(t.posting_date,'MM') mm
     ,t.iin_cl
     ,nvl(t.bin,'-') as bin
     ,t.trans_amount amt
     ,case when t.bin is null then 0 else 1 end is_have_bin
  from dwh_buffer.SAL_TRANS t
  --where t.bin is not null
) t
group by
      t.mm
     ,t.iin_cl
     ,t.bin
     ,is_have_bin
;

