create or replace force view dwh_risk.uwi_proc_stages as
select 'E3349D02-06F8-4805-A1B9-468299EAFC6B��������� - ����������� �������' status,'�����' stage,0 staff_process,
0 wrong_client_data,0 stopped_before_scoring,0 stopped_after_scoring,1 is_application,0 approved_scoring,
0 approved_verification,0 credit_admins_passed,0 client_got_money, 1 ready_for_scoring,0 ready_for_verif  from dual union all

select 'HR: ���������' status,'�����' stage,1 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select '�����������' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select '������������' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select '����� ������������' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select '�������������� ������������ ������� � ��������' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select '����� ���������� ������������' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,1 p8,0 p9,1 p10,1 p11  from dual union all
select '����� ���������� �� ����' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,1 p9,1 p10,1 p11  from dual union all
select '��������' status,'��������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,1 p9,1 p10,1 p11  from dual union all
select '����������������' status,'��������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,1 p9,1 p10,1 p11  from dual union all
select '���������' status,'��������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,1 p9,1 p10,1 p11  from dual union all
select '����������������� �������� �����' status,'��������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,1 p9,1 p10,1 p11  from dual union all
select '���������� �2' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select '������ �� �������� ������ �������' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,1 p9,1 p10,1 p11  from dual union all
select '������ �� �������� ������ ��� ����' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,1 p9,1 p10,1 p11  from dual union all
select '������ �� �������� ������ ��� �������� ������� �����' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select '������ �� �������� ������ ������� - DSA' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select '������ ������������� ���������' status,'�����' stage,0 p1,0 p2,0 p3,0 p4,1 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select '�����������' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select '����������� �� ������������ �����������' status,'� ������' stage,1 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select '�� ��������� � �����������' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select '�� ����������� ����� ���' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,0 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select '�������� �����������' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select '����� ������� � �������������� ��������' status,'������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select '��������� - ����������� �������' status,'�����' stage,0 p1,0 p2,0 p3,0 p4,1 p5,0 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select '���������-�������� ������� �����' status,'��������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,0 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select '�������� �������� �����' status,'��������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,0 p9,1 p10,1 p11  from dual union all
select '�������' status,'������' stage,0 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select '��������' status,'������' stage,0 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select '��������  - �� �����������' status,'������' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select '��������  - �� ����������� - DSA' status,'������' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select '��������  - �� ������������ � �������������' status,'������' stage,0 p1,0 p2,1 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select '��������  ��������' status,'������' stage,0 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select '��������  �������� - �� �����������' status,'������' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select '��������  �������� - �� ����������� - DSA' status,'������' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select '��������  �������� -��' status,'������' stage,0 p1,0 p2,1 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select '�������� - ������������' status,'������' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select '�������� - �������� ������� �����' status,'������' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,1 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select '�������� � �����������' status,'������' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select '�������� � �����������. ���� ������������' status,'������' stage,0 p1,1 p2,0 p3,1 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select '�������� � �����������. ������ �� �������� � ������������� ���������' status,'������' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select '�������� � �����������. ��������� �� ���������������� ����� �� ������������� �������� �� ������� � ������� �������������' status,'������' stage,0 p1,1 p2,0 p3,1 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select '�������� � �����������. ���������� ���� �������� ������' status,'������' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select '�������� � �� ���������� �������� ����� �������' status,'������' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,1 p7,1 p8,0 p9,1 p10,1 p11  from dual union all
select '�������� � �������� �������� �����' status,'������' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,1 p7,1 p8,0 p9,1 p10,1 p11  from dual union all
select '�������� � ���������� � ������' status,'������' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,1 p7,1 p8,0 p9,1 p10,1 p11  from dual union all
select '�������� � ����� �1' status,'������' stage,0 p1,0 p2,1 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select '�������� � ����� �2' status,'������' stage,0 p1,0 p2,1 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select '�������� �������� - �� �����������' status,'������' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select '�������� �������������, ��������������� �������� ��� �� �������� � ��������� ����' status,'������' stage,0 p1,1 p2,1 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select '�������� ��' status,'������' stage,0 p1,0 p2,1 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select '�������� �� ����� �������� ������' status,'������' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,1 p7,1 p8,0 p9,1 p10,1 p11  from dual union all
select '�������� ��������, ��������������� �������� ��� �� �������� � ��������� ����' status,'������' stage,0 p1,1 p2,1 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select '�������� ����� � ����' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,1 p9,1 p10,1 p11  from dual union all
select '�������� ����� ����' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,1 p9,1 p10,1 p11  from dual union all
select '�������� ����� � �����' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,1 p9,1 p10,1 p11  from dual union all
select '������������� ��������� ����� ����' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,1 p9,1 p10,1 p11  from dual union all
select '�������������� �������������� ����������' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select '������������ ����������' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select '�������� HR' status,'� ������' stage,1 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select '�������� ������ ��������' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,0 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select '�������� ���' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select '�������� ������� �����' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select '�����������' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select '��������������� ���� �� ������' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select '���� �������� � ���������� � ������' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,0 p9,1 p10,1 p11  from dual union all
select '������������ ����������' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select '������������ ������������' status,'� ������' stage,1 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select '������������ ������� � ��������' status,'� ������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select '���� �������� �2 �����' status,'������' stage,0 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select '���� ������������ ������� �����(1)' status,'������' stage,0 p1,0 p2,0 p3,0 p4,1 p5,0 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual;

