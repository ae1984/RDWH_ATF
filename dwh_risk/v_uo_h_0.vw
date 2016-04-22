create or replace force view dwh_risk.v_uo_h_0 as
select
  t.report_dt
  ,trim(t.f1) f1
  ,trim(t.f2) f2
  ,trim(t.f3) f3
  ,trim(t.f4) f4
  ,trim(replace(t.f5,'.','')) f5
  ,trim(t.f6)   f6
  ,trim(t.f7)   f7
  ,trim(t.f8)   f8
  ,to_date(trim(t.f9))   f9
  ,case when length(trim(t.f10))=10 then to_date(trim(t.f10)) end   f10
  ,trim(t.f11)  f11
  ,nvl(to_number(trim(t.f12)),0)   f12
  ,nvl(to_number(trim(t.f13)),0)   f13
  ,trim(t.f14)  f14
  ,trim(t.f15)  f15
  ,trim(t.f16)  f16
  ,trim(t.f17)  f17
  ,trim(t.f18)  f18
  ,trim(t.f19)  f19
  ,trim(t.f20)  f20
  ,trim(t.f21)  f21
from XLS_H_UO_HIST t
where trim(upper(t.f1)) <> 'Ã‘Œ';

