create or replace force view dwh_risk.v_gsvp_pars_1 as
select
  case when t.dt - lag(t.dt)over(partition by t.iin, t.bin order by t.dt) > 41 then 1 else 0 end as delay_zp
  ,lag(t.dt)over(partition by t.iin, t.bin order by t.dt) as dt_lag
  ,t.dt - lag(t.dt)over(partition by t.iin, t.bin order by t.dt) as interval_day
  ,t."BIRTHDATE",t."IIN",t."FATHERNAME",t."NAME",t."SURNAME",t."DT",t."COMPANY_NAME",t."BIN",t."AMOUNT",t."TYPE_COMPANY",t."IS_BIN",t."MM"
from V_GSVP_PARS t
order by  t.iin, t.bin, t.dt;

