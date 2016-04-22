create or replace force view dwh_risk.v_cp_correct_pd_20160210_top10 as
select "CLICODE","CLINAME","REPORT_DT","PD_CLEAR","PG_LAG","PG_DIFF","NN"
from
(select  z.*
       ,row_number() over (partition by z.report_dt order by pg_diff desc) nn
from (
select distinct t.clicode, t.cliname, t.report_dt, t.pd_clear
       ,lag(pd_clear) over (partition by t.f53 order by t.report_dt) pg_lag
       ,abs(lag(pd_clear) over (partition by t.f53 order by t.report_dt) - pd_clear) pg_diff
from V_CP_CORRECT_PD_20160208 t
where VCC = 'corp' and ISL = 'Pool' and IS_NEGATIVE_OUTSTANDING =	0 and PSC	<> '702' and CLASS = 'PL'
) z where z.pg_diff is not null
) where nn <=10;

