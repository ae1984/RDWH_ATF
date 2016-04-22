create or replace force view dwh_risk.v_cp_restr_20160202 as
select  distinct
         f6
        ,f34
        ,f35
        --,case when upper(nvl(f35,'-')) not in ('N','-') then 1 else 0 end as is_restr
           from v_cp_h
          where upper(nvl(f35,'-')) not in ('N','-')
           --where f6 = '1402675' --and report_dt >= add_months(trunc(sysdate,'mm'),-12)
                   -- and trunc(f34,'mm') = trunc(report_dt,'mm')
;

