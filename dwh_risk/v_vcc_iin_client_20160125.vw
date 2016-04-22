create or replace force view dwh_risk.v_vcc_iin_client_20160125 as
select
   tt.iin,
   max(tt.cli_code) cli_code,
   max(tt.cli_name) cli_name,
   --max(tt.vcc) vcc,
   max(a.vcc) vcc,
   count(*) as cnt
from (
   select distinct t.iin, t.cli_code, t.id, t.cli_name, t.vcc
   from dwh_buffer.dm_cif_base t
   where t.iin is not null
) tt
--left join (select distinct code, name, vcc from dwh.DCA_SRC_BM1) a on a.code = tt.cli_code
left join dwh_buffer.ETL_CS_CLI_RM_VCC_20160125 a on a.id = tt.id
group by tt.iin
;

