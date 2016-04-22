create or replace force view dwh_risk.v_salary_dca as
select
   t."MM",t."BIN",t."AMOUNT",t."PD"
   ,lag(t.amount) over (partition by t.bin order by t.mm) amount_lag
   ,lag(t.pd ignore nulls) over (partition by t.bin order by t.mm) as pd_lag
   ,case when nvl(lag(t.amount) over (partition by t.bin order by t.mm),0)>0 then 1 else 0 end as is_amount_lag
   ,case when t.pd > 0.1 then 1 else 0 end as is_more_10prc
   ,case when (t.pd/lag(t.pd ignore nulls) over (partition by t.bin order by t.mm)) >=2 then 1 else 0 end as is_2times
from (
    select
       add_months(b.mm,0) mm
       --,b.contract_name
       ,a.iin bin
       ,max(b.sum_trans_amount) as amount
       ,max(t.PD) as PD
    from DCA_MAX_CLI t --DCA_TRGT_PD t
    left join dwh_buffer.dm_cif_base a on a.cli_code = t.code
    join (
        select t.bin,
               t.mm,
               sum(t.trans_amount) as sum_trans_amount
        from V_SALARY t
        where t.bin is not null
        group by  t.bin,  t.mm
    ) b on b.BIN = a.iin and b.MM = trunc(t.rpt_date,'MM')
    group by b.mm, a.iin
) t
;

