create or replace force view dwh_risk.v_salary as
select
   t.contract_name
   ,nvl(t.bin,'-') as bin
   ,case when substr(t.bin,5,1) in ('4','5') then 'ﬁÀ'
         else '»œ'
    end type_company
   ,case when substr(t.bin,5,1) not in ('0','1','2','3') then '¡»Õ'
         else '»»Õ'
    end is_bin
   ,trunc(t.posting_date,'MM') as mm
   ,trunc(t.posting_date) as dt
   ,t.iin_cl
   ,t.trans_amount
   ,case when trunc(t.posting_date) between trunc(t.posting_date,'MM') and trunc(t.posting_date,'MM')+15 then '1-15'
         when trunc(t.posting_date) between trunc(t.posting_date,'MM')+16 and trunc(LAST_DAY(sysdate)) then '16-31'
    end as dt_grp
   ,1 as cnt
   ,case when t.bin is null then 0 else 1 end is_have_bin
   ,t.trans_amount/get_nbrk_curr(trunc(t.posting_date),'USD',0) as trans_amount_usd
from dwh_buffer.SAL_TRANS t;

