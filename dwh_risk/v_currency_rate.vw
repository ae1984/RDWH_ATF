create or replace force view dwh_risk.v_currency_rate as
select
    to_char(t.dt,'d') week_day
   ,t.dt
   ,get_nbrk_curr(t.dt,'USD',0) usd
   ,get_nbrk_curr(t.dt,'EUR',0) EUR
   ,get_nbrk_curr(t.dt,'RUB',0) rub
from DM_DATE t
where dt between to_date('01.12.2014') and sysdate
order by t.dt;

