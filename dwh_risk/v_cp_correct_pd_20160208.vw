create or replace force view dwh_risk.v_cp_correct_pd_20160208 as
select
      t.f9 contract_num,
      t.report_dt
      ,t.f53
      ,t.f6 clicode
      ,t.f5 cliname
      ,t.f82 max -- сделать флажок на поле просрочка>90 дней
      ,case when t.f82>90 then 1 else 0 end is_dpd_90
      ,t.f96 ISL
      ,t.f49 PSC
      ,t.f95 CLASS
      ,t.f77 VCC
      ,t.f88 PD_CP
      ,t.f73 Outstanding
      ,t.f87 LGD
      ,t.f89 LDP
      ,t.f90 LLP
      ,t.f92 LLP_total
      ,a.pd
      ,a.pd_clear
      ,a.pd20
,(0.00205*ln(a.pd)+0.02625) pd_corrected
,(0.00205*ln(a.pd_clear)+0.02625) pd_clear_corrected
,(0.00205*ln(a.pd20)+0.02625) pd20_corr
/*
      ,0.197628*a.PD+0.006079 pd_corrected
      ,0.197628*a.pd_clear+0.006079 pd_clear_corrected
      ,0.197628*a.pd20+0.006079 pd20_corr*/

      ,case when t.f73<0 then 1 else 0 end is_negative_Outstanding -- не перепровизованный
      /*,case when t.f82 > 90 then 1 -- просрочка>90 дней
            when t.f96 <> 'Pool' then 1 -- не индивидуально значимый
            when t.f49 = '702' then 1 -- workout
            when t.f95 not in ('PL') then 1 --классификаторы
            when t.f77 in ('SNT','corp','sme') and a.pd is not null then 0.197628*a.PD+0.006079
            when t.f77 not in ('SNT','corp') and a.pd is null then to_number(t.f88)
            when t.f77 in ('SNT','corp') and a.pd is null then 0.07
            else null
       end as PD_corrected*/
/*      ,case when t.f82 > 90 then 1
            when t.f96 <> 'Pool' then 1
            when t.f49 = '702' then 1
            when t.f95 not in ('PL') then 1
            when t.f77 in ('SNT','corp','sme') and a.pd is not null then 0.197628*a.PD+0.006079
            when t.f77 not in ('SNT','corp') and a.pd is null then to_number(t.f88)
            when t.f77 in ('SNT','corp') and a.pd is null then 0.07
            else null
       end * (case when t.f73<0 then 0 else t.f73 end) * t.f87 * t.f89   as LLP_corrected
      ,
      case when t.f82 > 90 then 1
            when t.f96 <> 'Pool' then 1
            when t.f49 = '702' then 1
            when t.f95 not in ('PL') then 1
            when t.f77 in ('SNT','corp','sme') and a.pd20 is not null then 0.197628*a.PD20+0.006079
            when t.f77 not in ('SNT','corp') and a.pd20 is null then to_number(t.f88)
            when t.f77 in ('SNT','corp') and a.pd20 is null then 0.07
            else null
       end * (case when t.f73<0 then 0 else t.f73 end) * t.f87 * t.f89   as LLP_corrected20

      ,
      case when t.f82 > 90 then 1
            when t.f96 <> 'Pool' then 1
            when t.f49 = '702' then 1
            when t.f95 not in ('PL') then 1
            when t.f77 in ('SNT','corp','sme') and a.pd_clear is not null then 0.197628*a.pd_clear+0.006079
            when t.f77 not in ('SNT','corp') and a.pd_clear is null then to_number(t.f88)
            when t.f77 in ('SNT','corp') and a.pd_clear is null then 0.07
            else null
       end * (case when t.f73<0 then 0 else t.f73 end) * t.f87 * t.f89   as LLP_corrected_clear
*/

,pd_clear* (case when t.f73<0 then 0 else t.f73 end) * t.f87 * t.f89   as LLP_DCA_clear
      ,(0.00205*ln(a.pd)+0.02625) * (case when t.f73<0 then 0 else t.f73 end) * t.f87 * t.f89   as LLP_corrected_2
      ,(0.00205*ln(a.pd20)+0.02625) * (case when t.f73<0 then 0 else t.f73 end) * t.f87 * t.f89   as LLP_corrected20_2
      ,(0.00205*ln(a.pd_clear)+0.02625) * (case when t.f73<0 then 0 else t.f73 end) * t.f87 * t.f89   as LLP_corrected_clear_2


from v_cp_h t
  left join (select rpt_date ,code
                    ,case when pd > 0.1 then 0.1 else pd end pd
                    ,pd pd_clear
                    ,case when pd > 0.2 then 0.2 else pd end pd20
             from dca_max_cli) a on a.code = t.f6 and trunc(a.rpt_date,'mm')=trunc(t.report_dt,'mm')
  --left join XLS_PD_20160208 b on b.code = t.f6
where t.report_dt >= to_date('01.06.2015')

and t.f73>=0 -- позитивный аутстендинг
and t.f82<=90 -- просрочка меньше 90 дней
and upper(t.f77) in ('CORP','SME')
and upper(t.f96)='POOL'
and to_number(nvl(t.f49,'999999'))<>702
and upper(t.f95)= 'PL'
--where a.pd is not null
--select * from XLS_PD_20160208 t

/*
LPP
PD*LGD*LDP*Outstanding
Поле PD – то значение, которые ты рассчитаешь, остальные поля из КП
Значение PD и Outstanding должны быть одного и того же месяца

PDcorrected=0,197628*PDDCA+0,006079
*/
;

