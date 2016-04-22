create or replace force view dwh_risk.v_cp_h_2 as
select
  t."REPORT_DT",t."REPORT_YMD",t."F1",t."F2",t."F3",t."F4",t."F5",t."F6",t."F7",t."F8",t."F9",t."F10",t."F11",t."F12",t."F13",t."F14",t."F15",t."F16",t."F17",t."F18",t."F19",t."F20",t."F21",t."F22",t."LOAN_ISSUE_YM",t."F23",t."F24",t."F25",t."F26",t."F27",t."F28",t."F29",t."F30",t."F31",t."F32",t."F33",t."F34",t."F35",t."F36",t."F37",t."F38",t."F39",t."F40",t."F41",t."F42",t."F43",t."F44",t."F45",t."F46",t."F47",t."F48",t."F49",t."F50",t."F51",t."F52",t."F53",t."F54",t."F55",t."F56",t."F57",t."F58",t."F59",t."F60",t."F61",t."F62",t."F63",t."F64",t."F65",t."F66",t."F67",t."F68",t."F69",t."F70",t."F71",t."F72",t."F73",t."F74",t."F75",t."F76",t."F77",t."F78",t."F79",t."F80",t."F81",t."F82",t."F83",t."F84",t."F85",t."F86",t."F87",t."F88",t."F89",t."F90",t."F91",t."F92",t."F93",t."F94",t."F95",t."F96",t."F97",t."F98",t."F99",t."F100",t."F101",t."F102",t."F103",t."F104",t."F105"
  ,substr(t.f9, 1 , min(length(t.f9)) over (partition by t.f6)) as f9_1
  ,case when upper(nvl(t.f35,'-')) not in ('N','-',
  'T',
'T2',
'T6',
'N',
'WL',
'WLD'

  ) then 1 else 0 end as f35_1
  ,case when upper(nvl(t.f35,'-')) not in ('N','-',
  'T',
'T2',
'T6',
'N',
'WL',
'WLD') then t.f34 else null end as f34_1
  ,case when length(t.f22)=10 then to_date(t.f22) else null end as f22_1
  ,nvl(t.f11*get_nbrk_curr(case when length(t.f22)=10 then to_date(t.f22) else null end, t.f10,0),0) as issue_kzt
  ,nvl(sum(t.f11*get_nbrk_curr(case when length(t.f22)=10 then to_date(t.f22) else null end, t.f10,0))over (partition by t.f6,t.report_dt ),0) as issue_kzt_sum_repdt
  ,max(t.f82) over (partition by t.f6) as dpd_max
from V_CP_H t;

