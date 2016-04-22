create or replace force view dwh_risk.v_cp_h_0 as
select
    --t.SDT        --��������� ���� ���������� ������
    t.REPORT_DT --���� ������ �� ����� �����
    ,EXTRACT(year FROM t.report_dt)*100+EXTRACT(month FROM t.report_dt) as report_ymd
    ,t.F1  --���--
    ,t.F2  --������� ����--
    ,t.F3  --���--
    ,t.F4  --������� ���� ������������ �������������--
    ,t.F5  --������������  ��������--
    ,t.F6  --��� �������--
    ,t.F7  --���--
    ,t.F8  -- � ��������� �����--
    ,t.F9  -- � �������� --
    ,t.F10 --������ --
    ,nvl(to_number(t.F11),0) F11 --+������ ������--
    ,nvl(to_number(t.F12),0) F12 --+���������� � �����--
    ,nvl(to_number(t.F13),0) F13 --+������� ������������--
    ,nvl(to_number(t.F14),0) F14 --+������� ������������ ������������� � �����--
    ,to_number(t.F15) F15 --+��������� ���������� ������--
    ,to_number(replace(t.F16,'.',',')) F16 --+���������� ������--
    ,nvl(to_number(t.F17),0) F17 --+����������� % � ������--
    ,nvl(to_number(t.F18),0) F18 --+����������� % � ����� --
    ,nvl(to_number(t.F19),0) F19 --+����������� % �� ��������� � ����� --
    ,nvl(to_number(t.F20),0) F20 --+����� ����������� ��������--
    ,nvl(to_number(t.F21),0) F21 --+����� ����������� ��������--
    --,to_date(t.F22) F22 --*���� ������--
    ,t.F22
    ,nvl(EXTRACT(year FROM to_date(t.F22))*100+EXTRACT(month FROM to_date(t.F22)),0) as loan_issue_ym
    ,t.F23
    --,to_date(t.F23) F23 --*���� ���������--
    ,to_number(t.F24) F24 --+% ��������--
    ,nvl(to_number(t.F25),0) F25 --+����� ��������--
    ,t.F26 --������� ��������--
    ,t.F27 --��� ��������--
    ,nvl(to_number(t.F28),0) F28 --+������� �� �����--
    ,nvl(to_number(t.F29),0) F29 --+IFRS interest--
    ,nvl(to_number(t.F30),0) F30 --+������ � ����--
    ,t.F31 --��� ������� ������������--
    ,t.F32 --��������� ������� � ������ ��/���--
    ,t.F33 --��� ��������--
    ,to_date(t.F34) F34 --+���� ������������ �������� (�������)--
    ,t.F35 --������� ���������������� (�������)--
    --,to_date(t.F36) F36 --���� ������������ �������� (����������)--
    ,t.F36
    ,t.F37 --������� ���������������� (����������)--
    ,t.F38 --���� ��������� ����������������--
    ,t.F39 --��� VCC--
    ,to_number(t.F40) F40 --+����������� ���������� ������--
    ,t.F41 --��� NACE--
    ,t.F42 --��� OLAV--
    ,t.F43 --���������� �������--
    ,t.F44 --������������ �������--
    ,t.F45 --BLANA--
    --,to_date(t.F46) F46 --*���� ����������� ��������--
    ,t.F46
    ,to_date(t.F47) F47 --+���� ���������� ����������--
    ,to_date(t.F48) F48 --+���� ���������� ���������� ��������--
    ,t.F49 --��� PSC--
    ,nvl(to_number(t.F50),0) F50 --+����� �������� � ������ �������--
    ,t.F51 --������� �������������--
    ,t.F52 --���� �������������--
    ,t.F53 --��������--
    ,t.F54 --�������� ��������� �����--
    ,t.F55 --��� ����������--
    ,t.F56 --��� ������ ��������������--
    ,t.F57 --��� �������� ���--
    ,t.F58 --������������ �������� ���--
    ,t.F59 --��������� ���������--
    ,t.F60 --ID ������ � �������--
    ,nvl(to_number(t.F61),0) F61 --+���� �������� �� �������� ����--
    ,nvl(to_number(t.F62),0) F62 --+���� �������� �� %--
    ,t.F63 --���--
    ,t.F64 --����-��������--
    ,t.F65 --��������� ��������--
    ,nvl(to_number(t.F66),0) F66 --+���� �������� ��--
    ,nvl(to_number(t.F67),0) F67 --+���� �������� %--
    ,t.F68 --��� ����� ������--
    ,t.F69 --������������ ����� ������--
    ,t.F70 --������ ��--
    ,t.F71 --�� - ��--
    ,t.F72 --������������--
    ,nvl(to_number(t.F73),0) F73  --+ Outstanding --
    ,t.F74 --IFRS Industry--
    ,t.F75 --Type of business--
    ,t.F76 --VCC name--
    --,t.F77 --SHORT VCC--
    ,case when t.f77 = 'Private' then 'PB' else t.f77 end F77
    ,t.F78 --RWO--
    ,t.F79 --RWO_short--
    ,nvl(to_number(t.F80),0) F80 --+� principal dpd--
    ,nvl(to_number(t.F81),0) F81 --+� interest dpd--
    ,nvl(to_number(t.F82),0) F82 --+MAX--
    ,nvl(to_number(t.F83),0) F83 --+ COLLATERAL --
    ,nvl(to_number(t.F84),0) F84 --+ Adjusted COLLATERAL --
    ,t.F85 --�������� MIGRATION--
    ,nvl(to_number(t.F86),0) F86 --+Overdue PROVISIONING--
    ,nvl(replace(t.F87,'.',','),0) F87 --+LGD --
    ,nvl(replace(t.F88,'.',','),0) F88 --+PD--
    ,nvl(replace(t.F89,'.',','),0) F89 --+LDP--
    ,nvl(to_number(t.F90),0) F90 --+ LLP --
    ,nvl(to_number(t.F91),0) F91 --+ IFRS interest LLP --
    ,nvl(to_number(t.F92),0) F92 --+ LLP total --
    ,nvl(replace(t.F93,'.',','),0) F93 --+ LLP % --
    ,nvl(to_number(t.F94),0) F94 --+ Current coverage --
    ,t.F95 --CLASS--
    ,t.F96 --ISL--
    ,nvl(to_number(t.F97),0) F97 --+ LLP OD --
    ,nvl(to_number(t.F98),0) F98 --+ LLP %% --
    ,t.F99 --SPU interest LLP
    ,t.F100  --acc
    ,t.F101  --acc
    ,t.F102  --acc1
    ,t.F103  --Overdue AFN
    ,t.F104  --������������������ ��������--
    ,t.F105  --���/�����--
    ,a.f4 as oked
    --,t.TMP
from XLS_H_CP_HIST t
left join (
    select  distinct t.f2, trim(first_value(t.f4) over(partition by t.f2 order by t.f1))f4  from XLS_H_OKED_20160201 t
    where length(regexp_replace(t.f2, '[^0-9]', '')) > 0
) a on a.f2 = trim(t.f26)
where t.f53 is not null and nvl(trim(t.f1),'-') <> '���' and nvl(upper(trim(t.f2)),'-') <>upper('������� ����')
     -- and t.REPORT_DT >= add_months(trunc(sysdate,'MM'),-6)
;

