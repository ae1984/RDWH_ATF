create or replace force view dwh_risk.v_credit_prosrochka_20150715 as
select distinct
   a.REFER_WH
   ,trunc(sysdate)-first_value(doper) over(partition by t.contract_id order by t.doper ) as dni_prosrochki
   ,first_value(doper) over(partition by t.contract_id order by t.doper) as dt_vznosa_plan
   ,first_value(t.stat) over(partition by t.contract_id order by t.doper) as stat
   ,t.contract_id
   ,dcb.cli_code
   ,a.state,a.contract_num,dcb.full_name
   ,a.val_code
   ,a.val_id


   ,case when dcb.vcc in ('107320',
                    '107329',
                    '107330',
                    '107340',
                    '107390',
                    '999992')
                  then '1. Retail'
          when dcb.vcc in (
                    '107310',
                    '107319',
                    '999994')
                  then '2. Private'
             when dcb.vcc in ('104120',
                    '104810',
                    '104815',
                    '104819',
                    '999993')
                  then '3. SME'
              else '4. Corporate'
    end cl_type
   ,case when dcb.vcc in (
                    '107330',
                    '107329',
                    '107320',
                    '107340',
                    '107390',
                    '401730',
                    '999992'
                    )
                  then '1. PI'
          when dcb.vcc in (
                    '104714',
                    '104719',
                    '104710',
                    '104611',
                    '104619',
                    '106612',
                    '201320',
                    '104612',
                    '106714'
                    )
                  then '2. corp'
          when dcb.vcc in (
                    '104819',
                    '104120',
                    '104810',
                    '104815'
                    )
                  then '3. sme'
          when dcb.vcc in (
                    '104715',
                    '104613'
                    )
                  then '4. SNT'
          when dcb.vcc in (
                    '107310',
                    '107319')
                  then '5. Private'
          else '6. '
    end cl_type2,
   dcb.vcc,
   dcb.Filial
   ,case when trunc(sysdate)-first_value(doper) over(partition by t.contract_id order by t.doper) >0 and
              trunc(sysdate)-first_value(doper) over(partition by t.contract_id order by t.doper) <=30 then '1. <31'
         when trunc(sysdate)-first_value(doper) over(partition by t.contract_id order by t.doper) >30 and
              trunc(sysdate)-first_value(doper) over(partition by t.contract_id order by t.doper) <=60 then '2. 31-60'
         when trunc(sysdate)-first_value(doper) over(partition by t.contract_id order by t.doper) >60 and
              trunc(sysdate)-first_value(doper) over(partition by t.contract_id order by t.doper) <=90 then '3. 61-90'
         when trunc(sysdate)-first_value(doper) over(partition by t.contract_id order by t.doper) >90 and
              trunc(sysdate)-first_value(doper) over(partition by t.contract_id order by t.doper) <=120 then '4. 91-120'
         else '5. >120'
    end as period
    --,(select sum(x.amount_val) from DWH_BUFFER.DM_LOAN_PAYM_3 x where x.longname = 'Основной долг'and x.contract_id = t.contract_id) as amount
    ,nvl(b.amt,0) as od --ОД + % по договору
    ,nvl(c.amt,0) as od_prosroch --просроченный ОД
    ,nvl(d.od_paid,0) as od_paid --оплаченный ОД
    ,nvl(b.amt,0) - nvl(d.od_paid,0) - nvl(c.amt,0) as od_ost --ОД остаток
    ,nvl(e.amt,0) as amt_p --вся просрочка
    ,nvl(f.paid,0) as paid --все платежи
    ,nvl(g.amt,0) as amt_plan --к оплате
    ,nvl(h.amt,0) as amt_prc --просроченный %
    ,nvl(j.amt,0) as amt_od_np --ОД не просроченный
    ,nvl(k.amt,0) as amt_prc_np --% не просроченный
   --,t.*
from LOAN_SCHED t
  left join DWH_BUFFER.DM_LOAN_BASE a on a.contract_id = t.contract_id
  --left join DWH_BUFFER.client c on c.cli_id = a.cli_id
  left join DWH_BUFFER.dm_cif_base dcb on dcb.id  = a.cli_id
  left join (
              select tmp1.contract_id, sum(tmp1.amount_val) as amt from V_LOAN_SCHED tmp1
              where tmp1.longname in ('Основной долг','Проценты по кредиту')
              group by  tmp1.contract_id
            ) b on b.contract_id = t.contract_id
  left join (
              select tmp2.contract_id, sum(tmp2.paysdokn) as amt
              from V_LOAN_SCHED tmp2
              where tmp2.doper <= trunc(sysdate)
                   --and tmp2.paysdokn > 0
                   --and tmp2.dclose is null
                   and tmp2.longname = 'Основной долг'
                   and upper(tmp2.stat) in (upper('Просрочен')
                                           ,upper('Ожидание прекращено')
                                           ,upper('Ожидает поступления')
                                           ,upper('Учтено на аналитике')
                                           ,upper('Просрочен (внесистемный)')
                                           --,upper('Списан')
                                            )
                   /*and tmp2.doper >= (select max(z.doper)
                                      from V_LOAN_SCHED z
                                      where z.contract_id=tmp2.contract_id
                                            and z.paysdokn = 0
                                            and z.dclose is not null)*/
              group by tmp2.contract_id
            ) c on c.contract_id = t.contract_id
  left join (
              select tmp3.contract_id, sum(tmp3.sdok) as od_paid from V_LOAN_SCHED tmp3
              where tmp3.longname = 'Основной долг' and tmp3.dclose is not null
              group by tmp3.contract_id
            ) d on d.contract_id = t.contract_id
  left join (
              select tmp4.contract_id, sum(tmp4.paysdokn) as amt
              from V_LOAN_SCHED tmp4
              where tmp4.doper <= trunc(sysdate)
                   and upper(tmp4.stat) in (upper('Просрочен')
                                     --,upper('Просрочен (внесистемный)')
                                    )
                   --and tmp4.paysdokn > 0
                   --and tmp4.dclose is null
                   --and tmp4.doper >= (select max(z.doper) from V_LOAN_SCHED z where z.contract_id=tmp4.contract_id and z.paysdokn = 0 and z.dclose is not null)
              group by tmp4.contract_id
            ) e on e.contract_id = t.contract_id
  left join (
              select tmp5.contract_id, sum(tmp5.sdok) as paid from V_LOAN_SCHED tmp5
              where tmp5.dclose is not null
              group by tmp5.contract_id
            ) f on f.contract_id = t.contract_id
  left join (
              select tmp6.contract_id, sum(tmp6.amount_val) as amt from V_LOAN_SCHED tmp6
              group by  tmp6.contract_id
            ) g on g.contract_id = t.contract_id
  left join (
              select tmp7.contract_id, sum(tmp7.paysdokn) as amt
              from V_LOAN_SCHED tmp7
              where tmp7.doper <= trunc(sysdate)
                   and tmp7.longname = 'Проценты по кредиту'
                   and upper(tmp7.stat) in (upper('Просрочен')
                                           ,upper('Ожидание прекращено')
                                           ,upper('Ожидает поступления')
                                           ,upper('Учтено на аналитике')
                                           ,upper('Просрочен (внесистемный)')
                                           --,upper('Списан')
                                            )
              group by tmp7.contract_id
            ) h on h.contract_id = t.contract_id

  left join (
              select tmp8.contract_id, sum(tmp8.amount_val) as amt from V_LOAN_SCHED tmp8
              where tmp8.longname in ('Основной долг')
                   and upper(tmp8.stat) not in (upper('Просрочен')
                                           ,upper('Ожидание прекращено')
                                           ,upper('Ожидает поступления')
                                           ,upper('Учтено на аналитике')
                                           ,upper('Просрочен (внесистемный)')
                                           --,upper('Списан')
                                            )
              group by  tmp8.contract_id
            ) j on j.contract_id = t.contract_id

  left join (
              select tmp9.contract_id, sum(tmp9.amount_val) as amt from V_LOAN_SCHED tmp9
              where tmp9.longname in ('Проценты по кредиту')
                   and upper(tmp9.stat) not in (upper('Просрочен')
                                           ,upper('Ожидание прекращено')
                                           ,upper('Ожидает поступления')
                                           ,upper('Учтено на аналитике')
                                           ,upper('Просрочен (внесистемный)')
                                           --,upper('Списан')
                                            )
              group by  tmp9.contract_id
            ) k on k.contract_id = t.contract_id

where t.doper < trunc(sysdate)
     --and t.paysdokn > 0
     --and t.dclose is null
     and upper(t.stat) in (upper('Просрочен')
                           ,upper('Ожидание прекращено')
                           ,upper('Ожидает поступления')
                           ,upper('Учтено на аналитике')
                           ,upper('Просрочен (внесистемный)')
                           ,upper('Списан')
                           )
    and dcb.vcc not in ('107329','104819','104719','104619','107319')
    /*
    Это РВО
    Код VCC
    107.329
    104.819
    104.719
    104.619
    107.319

    Остальное не рво, которые нужно отправлять
    */


/*     and t.doper >= (select min(z.doper)
                     from V_LOAN_SCHED z
                     where     z.contract_id=t.contract_id
                           and upper(z.stat) in (upper('Просрочен')
                                                 ,upper('Ожидание прекращено')
                                                 ,upper('Ожидает поступления')
                                                 ,upper('Учтено на аналитике')
                                                 ,upper('Просрочен (внесистемный)')
                                                 ,upper('Списан')
                                                 )
                    )*/
order by t.contract_id--, t.doper
;

