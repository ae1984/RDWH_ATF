create or replace force view dwh_risk.v_h_cp_20160130 as
select
  t.report_dt,
  t.F53 REFER,
  t.f9 CONTRACT_NUM
  ,t.F5 CLIENT_NAME
  ,case when t.f77 = 'Private' then 'PB' else t.f77 end SHORT_VCC
  ,t.f79 RWO_short
  ,lag(t.f79,1) over (partition by t.F53 order by t.report_dt) as RWO_short_lag1
  ,lag(t.f79,3) over (partition by t.F53 order by t.report_dt) as RWO_short_lag3
  ,lag(t.f79,6) over (partition by t.F53 order by t.report_dt) as RWO_short_lag6
  ,lag(t.f79,9) over (partition by t.F53 order by t.report_dt) as RWO_short_lag9
  ,case when
     trim(t.f79) = 'RWO'
        and (trim(lag(t.f79,1) over (partition by t.F53 order by t.report_dt))<>'RWO'
             or lag(t.f79,1) over (partition by t.F53 order by t.report_dt) is null)
     then 1 else 0 end as is_RWO_new
  ,case
    when t.f58 like '%Автокредитование%' or  trim(t.f58) = 'Тулпар' then 'Авто'
    when t.f58 like '%Ипотека%' then 'Ипотека'
    when t.f58 like '%Легкий%' or t.f58 like '%Лёгкий%' or lower(t.f58) like('%кредадмин%') then 'Легкий'
    when trim(t.f58) ='Потребительское кредитование' or lower(t.f58) = '%залог%' then 'Под залог'
    when t.f58 like '%Револьверное кредитование%' then 'Револьверное кредитование'
    else t.f58
  end product_group
  ,nvl(to_number(t.f13),0)+ nvl(to_number(t.f14),0) MAIN_EQU
  ,to_number(t.f13) DEBT_DEA_EQU --Остаток задолжености
  ,to_number(t.f14) OVRD_MAIN_EQU --Остаток просроченной задолженности в тенге
  ,nvl(to_number(t.F18),0) prc_dea_equ      --+Начисленные % в тенге --
  ,nvl(to_number(t.F19),0) prc_dea_ovrd_equ --+Начисленные % по просрочке в тенге --
  ,to_number(t.F80) ovrd_main  --№ principal dpd
  ,to_number(t.F81) ovrd_prc --№ interest dpd
  ,to_number(t.F82) ovrd --MAX
  ,case when to_number(t.F82) between 1 and 30    then '1. 1 - 30'
        when to_number(t.F82) between 31 and 60   then '2. 31 - 60'
        when to_number(t.F82) between 61 and 90   then '3. 61 - 90'
        when to_number(t.F82) between 91 and 120  then '4. 91 - 120'
        when to_number(t.F82) between 121 and 150 then '5. 121 - 150'
        when to_number(t.F82) between 151 and 180 then '6. 151 - 180'
        when to_number(t.F82) between 181 and 210 then '7. 181 - 210'
        when to_number(t.F82) between 211 and 240 then '8. 211 - 240'
        when to_number(t.F82) between 241 and 270 then '9. 241 - 270'
        when to_number(t.F82) between 271 and 300 then '10. 271 - 300'
        when to_number(t.F82) between 301 and 330 then '11. 301 - 330'
        when to_number(t.F82) between 331 and 360 then '12. 331 - 360'
        when to_number(t.F82) > 360 then '13. 360+'
   end ovrd_grp
  --,t.*
  ,t.F35 is_restruct
  ,t.F74 IFRS_Industry
  ,t.F76 VCC_name
  --,a.csln_fromdate as fromdate
  ,trunc(to_date(t.f22),'mm') as fromdate
  --,a.dep_id
  --,a.filial
  ,t.F1 MFO
  ,nvl(vo.otr, 'Прочее') otr
  ,t.f26 oked
from XLS_H_CP_HIST t

left join v_oked vo on replace(vo.id_oked,' ','')=nvl(replace (t.f26,' ',''),'999')
--left join V_LOAN_FIL_DT a on a.refer_wh = t.F53
where t.f53 is not null and nvl(trim(t.f1),'-') <> 'МФО' and nvl(upper(trim(t.f2)),'-') <>upper('Лицевой счет')
      and t.report_dt >= add_months(trunc(sysdate,'mm'),-18)
;

