create or replace force view dwh_risk.v_vint_h_cp as
select
  1 as cnt
  ,t.report_dt
  ,t.F9 as num_dog-- � ��������
  ,t.F53 as refer  --��������
  ,t.F6 as client_code--��� �������
  ,to_date(trim(t.F22)) as dt_begin --���� ������
  ,TRUNC(to_date(trim(t.F22)), 'month') as dt_begin_month
  --,extract(year from to_date(trim(t.F22))) as dt_begin_year
  --,extract(month from to_date(trim(t.F22))) as dt_begin_month
  ,to_date(trim(t.F23)) as dt_end  --���� ���������
  --,F69 as filial --������������ ����� ������
  ,trim(substr(t.F1,7,3)) as MFO
  ,case
    when trim(substr(t.F1,7,3)) = '722' then '17'
    when trim(substr(t.F1,7,3)) in ('471','992') then '05'
    when trim(substr(t.F1,7,3)) in ('605','483') then '02'
    when trim(substr(t.F1,7,3)) = '645' then '15'
    when trim(substr(t.F1,7,3)) = '682' then '16'
    when trim(substr(t.F1,7,3)) = '689' then '12'
    when trim(substr(t.F1,7,3)) in ('691','767') then '09'
    when trim(substr(t.F1,7,3)) = '730' then '03'
    when trim(substr(t.F1,7,3)) = '731' then '13'
    when trim(substr(t.F1,7,3)) = '736' then '14'
    when trim(substr(t.F1,7,3)) = '764' then '11'
    when trim(substr(t.F1,7,3)) = '780' then '10'
    when trim(substr(t.F1,7,3)) = '783' then '06'
    when trim(substr(t.F1,7,3)) = '826' then '01'
    when trim(substr(t.F1,7,3)) = '832' then '04'
    when trim(substr(t.F1,7,3)) = '944' then '08'
    when trim(substr(t.F1,7,3)) = '956' then '01'
    when trim(substr(t.F1,7,3)) = '966' then '07'
    else trim(substr(t.F1,7,3))
   end as  FILIAL


  ,t.F75 as Type_of_business  --Type of business

  ,t.F57 as product_code--��� �������� ���
  ,t.F58 as product_name --������������ �������� ��� --sas ���������

  ,t.F39 as vcc --��� VCC
  ,t.F10 as  val_code --������
  ,to_number(trim(t.F11)) as amt_val --����� ������ (� ������ �����) --������ ������"
  ,case --����� ������ � KZT
     when t.F10 = 'KZT' then to_number(trim(t.F11))
     when t.F10 = 'USD' then to_number(trim(t.F11))*r.usd
     when t.F10 = 'GBR' then to_number(trim(t.F11))*r.gbr
     when t.F10 = 'RUB' then to_number(trim(t.F11))*r.rub
     when t.F10 = 'EUR' then to_number(trim(t.F11))*r.eur
   end as AMOUNTLOANKZT_SUM  --amt_kzt
  ,t.F27 as product_type  --��� ��������
  ,t.F31 as  obj_cred_code --��� ������� ������������

  , nvl(to_char(to_date(trim(t.F22)),'YYYY')||to_char(to_date(trim(t.F22)),'MM'),'.') as REPORT_S
  --, to_char((t.report_dt +10),'YYYY')||to_char((t.report_dt +10),'MM') as REPORT_S

  -------------------------------------
  /*, case
      when upper(trim(t.f77)) <> 'SNT' then '00'
      when upper(trim(t.f77)) = 'SNT' then '01'
      when upper(trim(t.f76)) = upper('large corps') then '03'
      when upper(trim(t.f76)) = upper('mid corps') then '04'
      else ''
    end as SPU*/

    ,case
      when upper(trim(t.f77)) = upper('Non-SPU') then '00'
      when upper(trim(t.f77)) in (
          upper('SPU')
          ,upper('SNT')
          ,upper('SPU/new')
          ,upper('SPU_new')
      ) then '01'
      when upper(trim(t.f76)) = upper('large corps') then '03'
      when upper(trim(t.f76)) = upper('mid corps') then '04'
      else '00'
    end as SPU

  ,'ALL' as INDICATOR
  /*,case
    when trim(t.F39) in ('106.580','107.310','107.319') then 'VIP'
   end as NAME_ATF_PRODUCT */
  ,case
      when (upper(trim(t.F75)) = upper('������� ����')) or
           (upper(trim(t.F58)) in (upper('��. ��������������� ����. ��� ����� ����'),
                                  upper('��. ��������������� ����. ��� ����� ����. ��������'),
                                  upper('��. ��������������� ����. ��� ����� ����. ����������'))
           )
      then '003'
      when (upper(trim(t.F75)) = upper('����')
                                and upper(trim(t.F76)) in (
                                            upper('Mass and Afflnt'),
                                            upper('PI'),
                                            upper('mass and afflnt')))
           or (upper(trim(t.F75)) = upper('������� ������'))
      then '005'
      when upper(trim(t.F75)) = upper('����') then '001'
      when upper(trim(t.F75)) = upper('���') then '002'
      when upper(trim(t.F75)) = upper('������� �������') then '004'
      --when upper(trim(t.F75)) = upper('������� ������') then '005'
      /*when upper(trim(t.F58)) in (upper('��. ��������������� ����. ��� ����� ����'),
                                  upper('��. ��������������� ����. ��� ����� ����. ��������'),
                                  upper('��. ��������������� ����. ��� ����� ����. ����������')) then '003'  */
      --when upper(trim(t.F75)) = upper('') then ''
   end as BUSINESS
  ,case
     when upper(trim(t.F58))in (
         upper('���'),
         upper('���. ������-����'),
         upper('���. ������-������'),
         upper('���. ������-������������'),
         upper('���. ������-������'),
         upper('���. ������ ��� ����� ������������.'),
         upper('���. ���������'),
         upper('���. �������������� ����. �����'),
         upper('���. ���������������� ����.�����'),
         upper('���. ��������� ��������� �����')
     ) then 'RAZNOE'
     when upper(trim(t.F58))in (
         upper('���. ���� III - ������-����'),
         upper('���. ���� III - ������-������������'),
         upper('���. ���� III - ������-��������'),
         upper('���. ���� ���-������-��������'),
         upper('���. ����-������-������������'),
         upper('���. ����-������-��������'),
         upper('���, ����-������-��������'),
         upper('���. ����-������� ������-����'),
         upper('���. ����-������� ������-������������'),
         upper('���. ����-������� ������-��������'),
         upper('���, ����-������� ������-��������'),
         upper('���. ���� 2010'),
         upper('���. ����. ��������'),
         upper('���. �� ����� �������'),
         upper('���. �� ����� ����'),
         upper('���. ���� 21')
     ) then 'DAMU'
     when upper(trim(t.F58))in (
         upper('���. ����� �� ���������� (������������� ����)'),
         upper('���. ����� �� ���������� � �������� �����'),
         upper('���. ��������� (������������� ����)'),
         upper('���. ����� �� ����������'),
         upper('���. ���������')
     ) then 'OVER'
     when upper(trim(t.F58))in (
         upper('���. ������-����'),
         upper('���. ������-���� 2'),
         upper('���. �����. ����� ��� ����� ������.'),
         upper('���.������-�������� ����� ��� 8%'),
         upper('���. �����. ����� ��� ����� ����')
     ) then 'SMEUSKOR'
     when upper(trim(t.F58))in (
         upper('���. ������-��������'),
         upper('���, ������-��������')
     ) and trim(t.F31) = '10' -- ������ (LOAN_PURPOSE='10')
      then 'WC'
     when upper(trim(t.F58))in (
         upper('���. ������-��������'),
         upper('���, ������-��������')
     ) and trim(t.F31)in (
         '11','12','13','14','16','11.1','11.2','11.3','11.4','11.5','13.1','13.2','13.3','14.1','14.2','14.3'
     ) then 'INVEST'
     when upper(trim(t.F58))in (
         upper('���. ������-��������'),
         upper('���, ������-��������')
     ) and trim(t.F31) = '15' then 'SMECONS'
     when upper(trim(t.F58))in (
         upper('���. ������-��������'),
         upper('���, ������-��������')
     )  and trim(t.F31) = '20' then 'SMEOTHER'
     when upper(trim(t.F75)) = upper('���') then 'SME_OTHER'
   end as SMEPRODUCT
  ,case
     when upper(trim(t.F58))in (
         upper('���. ������-��������'),
         upper('���, ������-��������')
     ) then 'STANDART'
   end as SMEPRODUCT1
  ,case
      when (
            (upper(trim(t.F75)) = upper('����')
             and upper(trim(t.F76)) in (upper('Mass and Afflnt'),upper('PI'),upper('mass and afflnt'))
            )
            or (upper(trim(t.F75)) = upper('������� ������'))
           )
           and (trim(t.F58)='' or t.F58 is null)
      then 'OTHERPO'
     when upper(trim(t.F58))in (
         upper('��, ��������������� ����, ��������'),
         upper('��. ��������������� ����. ��������'),
         upper('��. ��������������� ����. ������'),
         upper('��. ����������, �� ��������������� ����'),
         upper('��, ��������������� ����, ���������� ���������'),
         upper('��. ��������������� ����. ���������� ���������'),
         upper('��. ��������������� ����. �����. Pre approved')
     ) then 'secured'
     when upper(trim(t.F58))in (
         upper('��. ��������� ���������� ��������'),
         upper('��. ������������� (�� �������������� � 2008 ����)'),
         upper('��. ������������� (�� �������������� � 28 ����)'),
         upper('��. Cash&Go. ���������� ������. ��������������� ����'),
         upper('��, Cash&Go, ���������� ������, ��������������� ����'),
         upper('��.Cash&Go.�assMarket'),
         upper('��.Cash&Go. ����������������'),
         upper('��.Cash&Go. ��������� �������'),
         upper('��. ��������������� ����. ��������'),
         upper('��. Cash&Go. ����������'),
         upper('��. Cash&Go. ��������� ������'),
         upper('��. Cash&Go. �������������'),
         upper('��. ����������, �� ��������������� ����. ��� �����������.'),
         upper('��. ����������, �� ��������'),
         upper('��. ����������. Cash&Go'),
         upper('��. ����������. ˸����'),
         upper('��.Cash&Go. Metro'),
         upper('��.Cash&Go. ���������'),
         upper('��. ˸����. ���������� ������. ��������������� ����'),
         upper('��. ˸����. �������������'),
         upper('��. ˸����. ����������'),
         upper('��. ˸����. ��������� ������'),
         upper('��.˸����. ��������� �������'),
         upper('��.˸����. ����������������'),
         upper('��.˸����.�assMarket')
     ) then 'unsecured'
   end as SECUNSEC
  ,case
     when upper(trim(t.F58))in (
         upper('��. ��������� ���������� ��������'),
         upper('��. ������������� (�� �������������� � 2008 ����)'),
         upper('��. ������������� (�� �������������� � 28 ����)'),
         upper('��. ��������������� ����. ��������')
     ) then 'POTREB'
     when upper(trim(t.F58))in (
         upper('��. ��������������� ����. ��������'),
         upper('��, ��������������� ����, ��������'),
         upper('��, ��������������� ����, ���������� ���������'),
         upper('��. ��������������� ����. ���������� ���������'),
         upper('��. ��������������� ����. ������')
     ) then 'POTREBSEC'
     when upper(trim(t.F58))in (
         upper('��. ����������, �� ��������������� ����')
     ) then 'STAFFSEC'
     when upper(trim(t.F58))in (
         upper('��, Cash&Go, ���������� ������, ��������������� ����'),
         upper('��. Cash&Go. ���������� ������. ��������������� ����'),
         upper('��. Cash&Go. ��������� ������'),
         upper('��. Cash&Go. ����������'),
         upper('��. �ash&Go.���������� ������'),
         upper('��.Cash&Go. Metro'),
         upper('��.Cash&Go. ���������� ������. ����������������'),
         upper('��.Cash&Go. ���������'),
         upper('��.Cash&Go. ��������� �������'),
         upper('��.Cash&Go. ����������������'),
         upper('��.Cash&Go.�assMarket'),
         upper('��. ˸����. ���������� ������. ��������������� ����'),
         --upper('��. ˸����. �������������'),
         upper('��. ˸����. ����������'),
         upper('��. ˸����. ��������� ������'),
         upper('��.˸����. ��������� �������'),
         upper('��.˸����. ����������������'),
         upper('��.˸����.�assMarket')
     ) then 'CASHGO'
     when upper(trim(t.F58))in (
         upper('��. Cash&Go. �������������'),
         upper('��. ˸����. �������������')
     ) then 'CGNEST'
     when upper(trim(t.F58))in (
         upper('��. ����������. Cash&Go'),
         upper('��. ����������, �� ��������'),
         upper('��. ����������, �� ��������������� ����. ��� �����������.'),
         upper('��. ����������. ˸����')
     ) then 'STAFF'
     when trim(t.F39) in ('106.580','107.310','107.319') then 'VIP'
     when ((upper(trim(t.F75)) = upper('������� ����')) or
           (upper(trim(t.F58)) in (upper('��. ��������������� ����. ��� ����� ����'),
                                  upper('��. ��������������� ����. ��� ����� ����. ��������'),
                                  upper('��. ��������������� ����. ��� ����� ����. ����������'))
           ))
           and (trim(t.F58)='' or t.F58 is null)
     then 'AUTOOTHER'
     when upper(trim(t.F58))in (
         upper('��. �����������. �����. ���������. ��������'),
         upper('��. �����������. �����. ���������. ���������� ���������'),
         upper('��. �����������. �����. ��������'),
         upper('��. �����������. �����. ���������� ���������')
     ) then 'AUTONEW'
     when upper(trim(t.F58))in (
         upper('��. �����������. �����������.')
     ) then 'AUTOUSED'
     when upper(trim(t.F58))in (
         upper('��. ��������������� ����. ��� ����� ����'),
         upper('��. ��������������� ����. ��� ����� ����. ��������'),
         upper('��. ��������������� ����. ��� ����� ����. ����������')
     ) then 'AUTOCONS'
     when upper(trim(t.F58))in (
         upper('��. ����������, �� ������������ ����')
     ) then 'AUTOSTAFF'
     when upper(trim(t.F75)) = upper('������� �������') and (trim(t.F58)='' or t.F58 is null) then 'IPOTOTHER'
     when upper(trim(t.F58))in (
         upper('��, �������-��������� �����'),
         upper('��. �������-��������� �����'),
         upper('��, �������-������� �������'),
         upper('��. �������-������� �������'),
         upper('��. �������-���'),
         upper('��. �������-����� (�� 20%)'),
         upper('��. �������-����� (�� 30%)'),
         upper('��. �������-����� (�� 40%)'),
         upper('��. �������-����� (�� 50%)'),
         upper('��. �������. ���. ��������� �����'),
         upper('��. �������. ���. ��������� �����'),
         upper('��. ������-������ �������-��������� ����')
     ) then 'IPOT'
     when upper(trim(t.F58))in (
         upper('��. �������-������'),
         upper('��. �������-�������������'),
         upper('��. �������. ���. ������'),
         upper('��. �������. ���. �������������'),
         upper('��. �������-��������� �������')
     ) then 'IPOTREMSTR'
     when upper(trim(t.F58))in (
         upper('��. �������-����������������. ������� �������'),
         upper('��. �������-����������������. ���������� �������'),
         upper('��. �������-����������������')
     ) then 'IPOTREF'
     when upper(trim(t.F58))in (
         upper('��. ����������, �� ������������ ������������')
     ) then 'IPOTSTAFF'
   end as SECTYPE
  ,case
     when upper(trim(t.F58))in (
         upper('��.Cash&Go.�assMarket'),
         upper('��. �ash&Go.���������� ������'),
         upper('��. Cash&Go. ���������� ������. ��������������� ����'),
         upper('��, Cash&Go, ���������� ������, ��������������� ����'),
         upper('��. ˸����. ���������� ������. ��������������� ����'),
         upper('��.˸����.�assMarket')
     ) then 'CGM'
     when upper(trim(t.F58))in (
         upper('��. Cash&Go. ����������'),
         upper('��. ˸����. ����������')
     ) then 'CGUSK'
     when upper(trim(t.F58))in (
         upper('��.Cash&Go. ����������������'),
         upper('��.Cash&Go. ���������� ������. ����������������'),
         upper('��.˸����. ����������������')
     ) then 'CGREF'
     when upper(trim(t.F58))in (
         upper('��.Cash&Go. ���������'),
         upper('��.Cash&Go. ��������� �������'),
         upper('��.Cash&Go. Metro'),
         upper('��. Cash&Go. ��������� ������'),
         upper('��. ˸����. ��������� ������'),
         upper('��.˸����. ��������� �������')
     ) then 'CGRAS'
   end as CASH
  ,case
     when upper(trim(t.F58))in (
         upper('��.Cash&Go.�assMarket'),
         upper('��.˸����.�assMarket')
     ) then 'CGMM'
     when upper(trim(t.F58))in (
         upper('��. �ash&Go.���������� ������'),
         upper('��. Cash&Go. ���������� ������. ��������������� ����'),
         upper('��, Cash&Go, ���������� ������, ��������������� ����'),
         upper('��. ˸����. ���������� ������. ��������������� ����')
     ) then 'CGSAL'
     when upper(trim(t.F58))in (
         upper('��.Cash&Go. ���������'),
         upper('��. Cash&Go. ��������� ������'),
         upper('��. ˸����. ��������� ������')
     ) then 'CGRASFIL'
     when upper(trim(t.F58))in (
         upper('��.Cash&Go. Metro'),
         upper('��.Cash&Go. ��������� �������'),
         upper('��.˸����. ��������� �������')
     ) then 'CGRASPAR'
   end as CASH_PRODUCT
  ----------------- ��������� �����
  ,case when t.f35 is null or trim(upper(t.f35)) in('','N') then 0 else 1 end  as flag_restruct   --������� ���������������� (�������)   N, " ", NULL - �� ��������
  ,case when x.report_dt is null then 0 else 1 end as flag_out_balance    --������� �������� �� ������ (������ ���� ���������� ��� ������, ����������� �� ����� 7130)

  ,to_number(trim(t.F17)) as prc_amt_val --����������� % � ������
  ,to_number(trim(t.F18)) as prc_amt_kzt --����������� % � �����
  /*,case
      when x.report_dt is null then to_number(trim(nvl(t.F13,'0')))
      else to_number(trim(nvl(x1.F14,'0')))
   end as LOANREST  --ost_od --������� ������������*/
  ,to_number(trim(nvl(t.F13,'0'))) as LOANREST  --ost_od --������� ������������*/
  ,sum(to_number(trim(t.F13))) over(partition by t.report_dt) as LOANREST_ALL_MONTH


  ,to_number(trim(t.F30)) as penalty  --������ � ����
  ,to_number(trim(t.F28)) as discount  --������� �� �����

  ,to_number(trim(t.F80)) as od_day_def--� principal dpd
  ,to_number(trim(t.F81)) as prc_day_def  --� interest dpd
  ,z.F15 as def_days_od--���������� ���� ��������� ��
  ,z.F21 as def_days_prc--���������� ���� ��������� %
  ,z.f12 as def_amt_od --������ ������������� �� (���. � KZT � � ������ �����)
  ,GREATEST(to_number(z.F15),to_number(z.F21)) as def_days
  ,case
     when t.F10 = 'KZT' then to_number(trim(z.f12))
     when t.F10 = 'USD' then to_number(trim(z.F12))/r.usd
     when t.F10 = 'GBR' then to_number(trim(z.F12))/r.gbr
     when t.F10 = 'RUB' then to_number(trim(z.F12))/r.rub
     when t.F10 = 'EUR' then to_number(trim(z.F12))/r.eur
   end as def_amt_od_val
  ,z.f18 as def_amt_prc --������ ������������� % (���. � KZT � � ������ �����)
  ,case
     when t.F10 = 'KZT' then to_number(trim(z.f18))
     when t.F10 = 'USD' then to_number(trim(z.F18))/r.usd
     when t.F10 = 'GBR' then to_number(trim(z.F18))/r.gbr
     when t.F10 = 'RUB' then to_number(trim(z.F18))/r.rub
     when t.F10 = 'EUR' then to_number(trim(z.F18))/r.eur
   end as def_amt_prc_val
   , 1 as COUNT_OF_CREDIT
   ,trunc(MONTHS_BETWEEN(trunc(sysdate), trunc(to_date(trim(t.F22))))) as MOB
   ,case when to_date(trim(t.F23)) > trunc(sysdate) then 1 else 0 end "COUNT"
   --,(trunc(sysdate)- trunc(to_date(trim(t.F22)))) as d
   ,case when GREATEST(nvl(to_number(z.F15),0),nvl(to_number(z.F21),0)) >=1 then 1 else 0 end as    COUNT_OF_1P
   ,case when GREATEST(nvl(to_number(z.F15),0),nvl(to_number(z.F21),0)) >=30 then 1 else 0 end as   COUNT_OF_30P
   ,case when GREATEST(nvl(to_number(z.F15),0),nvl(to_number(z.F21),0)) >=60 then 1 else 0 end as   COUNT_OF_60P
   ,case when GREATEST(nvl(to_number(z.F15),0),nvl(to_number(z.F21),0)) >=90 then 1 else 0 end as   COUNT_OF_90P
   ,case when GREATEST(nvl(to_number(z.F15),0),nvl(to_number(z.F21),0)) >=180 then 1 else 0 end as  COUNT_OF_180P

   ,case when GREATEST(nvl(to_number(z.F15),0),nvl(to_number(z.F21),0)) >=1 then to_number(trim(t.F13)) else 0 end as COUNT_OF_1P_SUM
   ,case when GREATEST(nvl(to_number(z.F15),0),nvl(to_number(z.F21),0)) >=30 then to_number(trim(t.F13)) else 0 end as COUNT_OF_30P_SUM
   ,case when GREATEST(nvl(to_number(z.F15),0),nvl(to_number(z.F21),0)) >=60 then to_number(trim(t.F13)) else 0 end as COUNT_OF_60P_SUM
   ,case when GREATEST(nvl(to_number(z.F15),0),nvl(to_number(z.F21),0)) >=90 then to_number(trim(t.F13)) else 0 end as COUNT_OF_90P_SUM
   ,case when GREATEST(nvl(to_number(z.F15),0),nvl(to_number(z.F21),0)) >=180 then to_number(trim(t.F13)) else 0 end as COUNT_OF_180P_SUM
   ,case
      when GREATEST(nvl(to_number(z.F15),0),nvl(to_number(z.F21),0)) between 1 and 29 then 'DEL_01P'
      when GREATEST(nvl(to_number(z.F15),0),nvl(to_number(z.F21),0)) between 30 and 59 then 'DEL_030P'
      when GREATEST(nvl(to_number(z.F15),0),nvl(to_number(z.F21),0)) between 60 and 89 then 'DEL_060P'
      when GREATEST(nvl(to_number(z.F15),0),nvl(to_number(z.F21),0)) between 90 and 179 then 'DEL_090P'
      when GREATEST(nvl(to_number(z.F15),0),nvl(to_number(z.F21),0)) >=180 then 'DEL_0180P'
      else ''
    end as "_NAME_"




   -----------------------------------------------
   ,r.usd
   ,r.gbr
   ,r.rub
   ,r.eur
   --,t.*
   ,t.f76,t.f77,t.f75
from XLS_H_CP_HIST t
  left join XLS_H_PROSR_CRED_HIST z on  trim(z.f3) = trim(t.F6)
             and trim(z.f7) = trim(t.F9)
             and extract(year from z.report_dt)=extract(year from t.report_dt)
             and extract(month from z.report_dt)=extract(month from t.report_dt)
  left join (select distinct
                f7,f9,report_dt
             from XLS_H_7130_HIST) x on  trim(x.f7) = trim(t.F6)
             and trim(x.f9) = trim(t.F9)
             and extract(year from x.report_dt)=extract(year from t.report_dt)
             and extract(month from x.report_dt)=extract(month from t.report_dt)
  left join (select distinct
                f7,f9,report_dt, last_value(f14) over (partition by f7,f9,report_dt order by report_dt, sdt ) as F14
             from XLS_H_7130_HIST
             where F16 is null and F14 is not null
             ) x1 on  trim(x1.f7) = trim(t.F6)
             and trim(x1.f9) = trim(t.F9)
             and extract(year from x1.report_dt)=extract(year from t.report_dt)
             and extract(month from x1.report_dt)=extract(month from t.report_dt)

  left join DWH_BUFFER.V_XLS_H_NBRK_CURR_RATE r on r.dt = t.report_dt

where 1=1
   and trim(t.f1) <> '���' and trim(t.f1) <> 'F1' and t.f1 is not null
   --t.f58 = '��. �����������. �����. ���������. ��������'
   --t.f6 = '828357'
   --t.F10 = 'USD'
          --'821207'
         --'1609128'
order by t.report_dt
;

