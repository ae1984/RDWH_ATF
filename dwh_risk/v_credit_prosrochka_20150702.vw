create or replace force view dwh_risk.v_credit_prosrochka_20150702 as
select distinct
   trunc(sysdate)-first_value(doper) over(partition by t.contract_id order by t.doper ) as dni_prosrochki
   ,first_value(doper) over(partition by t.contract_id order by t.doper) as dt_vznosa_plan
   ,t.contract_id
   ,dcb.cli_code
   ,a.state,a.contract_num,dcb.full_name
   ,case when dcb.vcc in ('107320',
                    '107329',
                    '107330',
                    '107340',
                    '107390',
                    '999992',
                    '107310',
                    '107319',
                    '999994')
                  then '1. Retail+Private'
             when dcb.vcc in ('104120',
                    '104810',
                    '104815',
                    '104819',
                    '999993')
                  then '2. SME'
              else '3. Corporate'
    end cl_type
   ,case when trunc(sysdate)-first_value(doper) over(partition by t.contract_id order by t.doper) >0 and
              trunc(sysdate)-first_value(doper) over(partition by t.contract_id order by t.doper) <=30 then '1. <31'
         when trunc(sysdate)-first_value(doper) over(partition by t.contract_id order by t.doper) >30 and
              trunc(sysdate)-first_value(doper) over(partition by t.contract_id order by t.doper) <=60 then '2. 31-60'
         when trunc(sysdate)-first_value(doper) over(partition by t.contract_id order by t.doper) >60 and
              trunc(sysdate)-first_value(doper) over(partition by t.contract_id order by t.doper) <=90 then '3. 61-90'
         else '4. >90'
    end as period
    --,(select sum(x.amount_val) from DWH_BUFFER.DM_LOAN_PAYM_3 x where x.longname = 'Основной долг'and x.contract_id = t.contract_id) as amount
    ,nvl(b.amt,0) as od --ОД по договору
    ,nvl(c.amt,0) as od_prosroch --просроченный ОД
    ,nvl(d.od_paid,0) as od_paid --оплаченный ОД
    ,nvl(b.amt,0) - nvl(d.od_paid,0) - nvl(c.amt,0) as od_ost --ОД остаток
    ,nvl(e.amt,0) as amt_p --вся просрочка
    ,nvl(f.paid,0) as paid --все платежи
    ,nvl(g.amt,0) as amt_plan --к оплате
   --,t.*
from (select * from DWH_BUFFER.DM_LOAN_PAYM_3 where amount_val > 0) t
  --left join loan_sched_1 lsc on lsc.contract_id = t.contract_id and lsc.id = t.id
  left join DWH_BUFFER.DM_LOAN_BASE a on a.contract_id = t.contract_id
  --left join DWH_BUFFER.client c on c.cli_id = a.cli_id
  left join DWH_BUFFER.dm_cif_base dcb on dcb.id  = a.cli_id
  left join (
              select tmp1.contract_id, sum(tmp1.amount_val) as amt from DWH_BUFFER.DM_LOAN_PAYM_3 tmp1
              where tmp1.longname = 'Основной долг'
              group by  tmp1.contract_id
            ) b on b.contract_id = t.contract_id
  left join (
              select tmp2.contract_id, sum(tmp2.paysdokn) as amt
              from DWH_BUFFER.DM_LOAN_PAYM_3 tmp2
              where tmp2.doper <= trunc(sysdate)
                   and tmp2.paysdokn > 0
                   and tmp2.dclose is null
                   and tmp2.longname = 'Основной долг'
                   and tmp2.doper >= (select max(z.doper) from DWH_BUFFER.DM_LOAN_PAYM_3 z where z.contract_id=tmp2.contract_id and z.paysdokn = 0 and z.dclose is not null)
              group by tmp2.contract_id
            ) c on c.contract_id = t.contract_id
  left join (
              select tmp3.contract_id, sum(tmp3.sdok) as od_paid from DWH_BUFFER.DM_LOAN_PAYM_3 tmp3
              where tmp3.longname = 'Основной долг' and tmp3.dclose is not null
              group by tmp3.contract_id
            ) d on d.contract_id = t.contract_id
  left join (
              select tmp4.contract_id, sum(tmp4.paysdokn) as amt
              from DWH_BUFFER.DM_LOAN_PAYM_3 tmp4
              where tmp4.doper <= trunc(sysdate)
                   and tmp4.paysdokn > 0
                   and tmp4.dclose is null
                   and tmp4.doper >= (select max(z.doper) from DWH_BUFFER.DM_LOAN_PAYM_3 z where z.contract_id=tmp4.contract_id and z.paysdokn = 0 and z.dclose is not null)
              group by tmp4.contract_id
            ) e on e.contract_id = t.contract_id
  left join (
              select tmp5.contract_id, sum(tmp5.sdok) as paid from DWH_BUFFER.DM_LOAN_PAYM_3 tmp5
              where tmp5.dclose is not null
              group by tmp5.contract_id
            ) f on f.contract_id = t.contract_id
  left join (
              select tmp6.contract_id, sum(tmp6.amount_val) as amt from DWH_BUFFER.DM_LOAN_PAYM_3 tmp6
              group by  tmp6.contract_id
            ) g on g.contract_id = t.contract_id

where t.doper < trunc(sysdate)
     and t.paysdokn > 0
     and t.dclose is null
--     and t.doper >= (select max(z.doper) from DWH_BUFFER.DM_LOAN_PAYM_3 z where z.contract_id=t.contract_id and z.paysdokn = 0 and z.dclose is not null)
     and t.doper >= (select min(z.doper) from DWH_BUFFER.DM_LOAN_PAYM_3 z where z.contract_id=t.contract_id and z.amount_val>0 and z.paysdokn <> 0 and z.dclose is null --and z.longname = 'Основной долг'
                    )
order by t.contract_id--, t.doper
;

