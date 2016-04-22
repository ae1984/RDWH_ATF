create or replace force view dwh_risk.v_dca_20150918 as
select distinct
   v."FIL_CODE",v."CODE",v."NAME"
   ,t.load_id
   ,t.pd_type
   ,t.month
   ,t.year
   ,t.rpt_date
   ,t.pd
   ,a.vcc
   ,nvl(b.descr,'-') vcc_type
   ,l.contract_num
   ,l.obj_id
   ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 365 and xx.fromdate <= t.rpt_date and rownum = 1) OVRD_MAIN
   ,(select /*+index_desc (xx ix_COL_Q_ROW_3) */ xx.rval from DWH_BUFFER.COL_Q_ROW xx where xx.obj_id = l.OBJ_ID and xx.row_id = 366 and xx.fromdate <= t.rpt_date and rownum = 1) OVRD_PRC
   ,case when a.id is null then 0 else 1       end is_cif_base
   ,case when l.refer_wh is null then 0 else 1 end is_loan_base
from  DWH.DCA_TRGT_PD t
   left join (select max(v.fil_code) fil_code, v.code, v.name from dwh.DCA_SRC_BM1 v group by v.code,v.name) v on v.code=t.code
   left join dwh_buffer.dm_cif_base a on a.cli_code = v.code
   left join XLS_H_VCC_DESCR b on b.vcc = replace(a.vcc,'.','')
   left join dwh_buffer.dm_loan_base l on l.cli_id = a.id and l.state in ('Актуален','Выкуплен КИК-ом','Реструктуризирован','Списан','Списан долг')
where t.pd_type=1 --and v.code = 10
and t.load_id in (1000240) --and OBJ_ID = 2186959
;

