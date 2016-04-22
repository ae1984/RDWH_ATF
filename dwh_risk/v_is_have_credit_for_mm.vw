create or replace force view dwh_risk.v_is_have_credit_for_mm as
select distinct
  trunc(t.report_dt,'mm') mm
  ,t.F7 IIN
from v_cp_h t
where t.f7 is not null;

