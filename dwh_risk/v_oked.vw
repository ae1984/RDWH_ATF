create or replace force view dwh_risk.v_oked as
select to_char(t.id_oked,'00') id_oked, t.otr from

(

select 1 id_oked, '�������� ���������, ����� � ������ ���������' otr from dual union all
select 2 id, '�������� ���������, ����� � ������ ���������' otr from dual union all
select 3 id, '������' otr from dual union all
select 4 id, '������' otr from dual union all
select 5 id, '�����������, �����������  ' otr from dual union all
select 6 id, '������' otr from dual union all
select 7 id, '������' otr from dual union all
select 8 id, '������' otr from dual union all
select 9 id, '������' otr from dual union all
select 10 id, '������ �������� - �������������� �������� ���������� ' otr from dual union all
select 11 id, '������ �������� - �������������� �������� ���������� ' otr from dual union all
select 12 id, '������ �������� - �������������� �������� ���������� ' otr from dual union all
select 13 id, '���������������  ��������������' otr from dual union all
select 14 id, '���������������  ��������������' otr from dual union all
select 15 id, '������������ ������� ���������' otr from dual union all
select 16 id, '������������ ������� ���������' otr from dual union all
select 17 id, '����������� � ������� ��������������  ' otr from dual union all
select 18 id, '����������� � ������� ��������������  ' otr from dual union all
select 19 id, '������������ ����, ������� �� ���� � ������������ �����  ' otr from dual union all
select 20 id, '��������� ��������� � ������������ ������� �� ������ ' otr from dual union all
select 21 id, '����������-�������� ��������������; ������������ ���� ' otr from dual union all
select 22 id, '����������-�������� ��������������; ������������ ���� ' otr from dual union all
select 23 id, '������������ �����, �������������� � ������� ���������� ' otr from dual union all
select 24 id, '���������� �������������� ' otr from dual union all
select 25 id, '������������ ��������� � ������������� �������' otr from dual union all
select 26 id, '������������ ������ ��������������� ����������� ���������' otr from dual union all
select 27 id, '���������������� �������������� � ������������ ������� ������������� �������' otr from dual union all
select 28 id, '���������������� �������������� � ������������ ������� ������������� �������' otr from dual union all
select 29 id, '������������ ����� � ������������' otr from dual union all
select 30 id, '������������ �������������������, ������������ � ����������� ������������ ' otr from dual union all
select 31 id, '������������ �������������������, ������������ � ����������� ������������ ' otr from dual union all
select 32 id, '������������ �������������������, ������������ � ����������� ������������ ' otr from dual union all
select 33 id, '������������ �������������������, ������������ � ����������� ������������ ' otr from dual union all
select 34 id, '������������ ������������ ������� � ������������  ' otr from dual union all
select 35 id, '������������ ������������ ������� � ������������  ' otr from dual union all
select 36 id, '������ ������� ��������������' otr from dual union all
select 37 id, '������ ������� ��������������' otr from dual union all
select 40 id, '������������ � ������������� ��������������, ���� � ���� ' otr from dual union all
select 41 id, '������������ � ������������� ��������������, ���� � ���� ' otr from dual union all
select 42 id, '������' otr from dual union all
select 43 id, '������' otr from dual union all
select 44 id, '������' otr from dual union all
select 45 id, '������������� ' otr from dual union all
select 50 id, '��������; ������ �����������, ������� ������� � ��������� ������� �����������' otr from dual union all
select 51 id, '��������; ������ �����������, ������� ������� � ��������� ������� �����������' otr from dual union all
select 52 id, '��������; ������ �����������, ������� ������� � ��������� ������� �����������' otr from dual union all
select 53 id, '������' otr from dual union all
select 54 id, '������' otr from dual union all
select 55 id, '��������� � ���������   ' otr from dual union all
select 56 id, '������' otr from dual union all
select 57 id, '������' otr from dual union all
select 58 id, '������' otr from dual union all
select 59 id, '������' otr from dual union all
select 60 id, '��������� � �����   ' otr from dual union all
select 61 id, '��������� � �����   ' otr from dual union all
select 62 id, '��������� � �����   ' otr from dual union all
select 63 id, '��������� � �����   ' otr from dual union all
select 64 id, '��������� � �����   ' otr from dual union all
select 65 id, '���������� ������������    ' otr from dual union all
select 66 id, '���������� ������������    ' otr from dual union all
select 67 id, '���������� ������������    ' otr from dual union all
select 68 id, '������' otr from dual union all
select 69 id, '������' otr from dual union all
select 70 id, '�������� � ���������� ����������, ������ � �������������� �����' otr from dual union all
select 71 id, '�������� � ���������� ����������, ������ � �������������� �����' otr from dual union all
select 72 id, '�������� � ���������� ����������, ������ � �������������� �����' otr from dual union all
select 73 id, '�������� � ���������� ����������, ������ � �������������� �����' otr from dual union all
select 74 id, '�������� � ���������� ����������, ������ � �������������� �����' otr from dual union all
select 75 id, '��������������� ���������� ' otr from dual union all
select 76 id, '������' otr from dual union all
select 77 id, '������' otr from dual union all
select 78 id, '������' otr from dual union all
select 79 id, '������' otr from dual union all
select 80 id, '����������� ' otr from dual union all
select 81 id, '������' otr from dual union all
select 82 id, '������' otr from dual union all
select 83 id, '������' otr from dual union all
select 84 id, '������' otr from dual union all
select 85 id, '��������������� � �������������� ���������� �����' otr from dual union all
select 86 id, '������' otr from dual union all
select 87 id, '������' otr from dual union all
select 88 id, '������' otr from dual union all
select 89 id, '������' otr from dual union all
select 90 id, '�������������� ������������, ���������� � ������������ �����' otr from dual union all
select 91 id, '�������������� ������������, ���������� � ������������ �����' otr from dual union all
select 92 id, '�������������� ������������, ���������� � ������������ �����' otr from dual union all
select 93 id, '�������������� ������������, ���������� � ������������ �����' otr from dual union all
select 94 id, '������' otr from dual union all
select 95 id, '�������������� ����� �� ������� ��������� ���������' otr from dual union all
select 96 id, '������' otr from dual union all
select 97 id, '������' otr from dual union all
select 98 id, '������' otr from dual union all
select 99 id, '������������ ������������������ �����������' otr from dual
) t;

