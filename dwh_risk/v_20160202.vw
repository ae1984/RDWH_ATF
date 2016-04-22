create or replace force view dwh_risk.v_20160202 as
select /*+parallel(4)*/
       t.clicode
      ,max(e.full_name) as cliname
      ,max(a.PD)*100 DCA_PD
      ,max(b.f82) DPD_MAX12M
      ,max(c.f82) DPD
      ,(select count(*) as restr_cnt12M from cp_restr_20160202 where f6 = t.clicode and f34 >= add_months(trunc(sysdate,'mm'),-12)) restr_cnt12M
      ,(select count(*) as restr_cnt from cp_restr_20160202 where f6 = t.clicode) restr_cnt
from XLS_CLICODE_20160202 t
left join (select * from dca_max_cli where rpt_date = (select max(rpt_date) from dca_max_cli)) a on a.CODE = t.clicode
left join v_cp_h b on b.f6 = t.clicode and b.report_dt >= add_months(trunc(sysdate,'mm'),-12)
left join (select * from v_cp_h where report_dt = (select max(report_dt) from v_cp_h)) c on c.f6 = t.clicode
left join dwh_buffer.dm_cif_base e on e.cli_code = t.clicode
group by t.clicode;

