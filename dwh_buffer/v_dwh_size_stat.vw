create or replace force view dwh_buffer.v_dwh_size_stat as
select t."SCHEM",t."SDT",t."GB" from
(select 'DWH_BUFFER' as schem,t.sdt sdt, round(sum(mb)/1024/1024/1024,2) as gb from DWH_SIZE_STAT t
where t.sdt>= to_date('20.10.2015')
group by t.sdt
union all
select 'DWH_RISK' as schem,t.sdt sdt, round(sum(mb)/1024/1024/1024,2) as gb from dwh_risk.DWH_SIZE_STAT t
where t.sdt>= to_date('20.05.2015')
group by t.sdt
union all
select 'DWH_PRIM' as schem,t.sdt sdt, round(sum(mb)/1024/1024/1024,2) as gb from DWH_PRIM.DWH_SIZE_STAT t
where t.sdt>= to_date('20.05.2015')
group by t.sdt) t
order by t.schem, t.sdt;

