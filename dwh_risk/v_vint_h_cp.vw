create or replace force view dwh_risk.v_vint_h_cp as
select
  1 as cnt
  ,t.report_dt
  ,t.F9 as num_dog-- № договора
  ,t.F53 as refer  --Референс
  ,t.F6 as client_code--Код клиента
  ,to_date(trim(t.F22)) as dt_begin --Дата выдачи
  ,TRUNC(to_date(trim(t.F22)), 'month') as dt_begin_month
  --,extract(year from to_date(trim(t.F22))) as dt_begin_year
  --,extract(month from to_date(trim(t.F22))) as dt_begin_month
  ,to_date(trim(t.F23)) as dt_end  --Дата погашения
  --,F69 as filial --Наименование точки продаж
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

  ,t.F57 as product_code--Код продукта АТФ
  ,t.F58 as product_name --Наименование продукта АТФ --sas результат

  ,t.F39 as vcc --Код VCC
  ,t.F10 as  val_code --Валюта
  ,to_number(trim(t.F11)) as amt_val --Сумма выдачи (в валюте займа) --Валюта выдачи"
  ,case --Сумма выдачи в KZT
     when t.F10 = 'KZT' then to_number(trim(t.F11))
     when t.F10 = 'USD' then to_number(trim(t.F11))*r.usd
     when t.F10 = 'GBR' then to_number(trim(t.F11))*r.gbr
     when t.F10 = 'RUB' then to_number(trim(t.F11))*r.rub
     when t.F10 = 'EUR' then to_number(trim(t.F11))*r.eur
   end as AMOUNTLOANKZT_SUM  --amt_kzt
  ,t.F27 as product_type  --Тип продукта
  ,t.F31 as  obj_cred_code --Код объекта кредитования

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
      when (upper(trim(t.F75)) = upper('розница авто')) or
           (upper(trim(t.F58)) in (upper('ФЛ. Потребительские цели. Под залог авто'),
                                  upper('ФЛ. Потребительские цели. Под залог авто. Стандарт'),
                                  upper('ФЛ. Потребительские цели. Под залог авто. Упрощенный'))
           )
      then '003'
      when (upper(trim(t.F75)) = upper('корп')
                                and upper(trim(t.F76)) in (
                                            upper('Mass and Afflnt'),
                                            upper('PI'),
                                            upper('mass and afflnt')))
           or (upper(trim(t.F75)) = upper('розница потреб'))
      then '005'
      when upper(trim(t.F75)) = upper('корп') then '001'
      when upper(trim(t.F75)) = upper('мсб') then '002'
      when upper(trim(t.F75)) = upper('розница ипотека') then '004'
      --when upper(trim(t.F75)) = upper('розница потреб') then '005'
      /*when upper(trim(t.F58)) in (upper('ФЛ. Потребительские цели. Под залог авто'),
                                  upper('ФЛ. Потребительские цели. Под залог авто. Стандарт'),
                                  upper('ФЛ. Потребительские цели. Под залог авто. Упрощенный')) then '003'  */
      --when upper(trim(t.F75)) = upper('') then ''
   end as BUSINESS
  ,case
     when upper(trim(t.F58))in (
         upper('МСБ'),
         upper('МСБ. Бизнес-АВТО'),
         upper('МСБ. Бизнес-ДЕНЬГИ'),
         upper('МСБ. Бизнес-НЕДВИЖИМОСТЬ'),
         upper('МСБ. Бизнес-ПРОСТО'),
         upper('МСБ. Кредит под залог оборудования.'),
         upper('МСБ. Факторинг'),
         upper('МСБ. Возобновляемая кред. линия'),
         upper('МСБ. Невозобновляемая кред.линия'),
         upper('МСБ. Смешанная кредитная линия')
     ) then 'RAZNOE'
     when upper(trim(t.F58))in (
         upper('МСБ. ДАМУ III - Бизнес-Авто'),
         upper('МСБ. ДАМУ III - Бизнес-Недвижимость'),
         upper('МСБ. ДАМУ III - Бизнес-Стандарт'),
         upper('МСБ. Даму МКО-Бизнес-Стандарт'),
         upper('МСБ. ДАМУ-Бизнес-Недвижимость'),
         upper('МСБ. ДАМУ-Бизнес-Стандарт'),
         upper('МСБ, ДАМУ-Бизнес-Стандарт'),
         upper('МСБ. ДАМУ-РЕГИОНЫ Бизнес-Авто'),
         upper('МСБ. ДАМУ-РЕГИОНЫ Бизнес-Недвижимость'),
         upper('МСБ. ДАМУ-РЕГИОНЫ Бизнес-Стандарт'),
         upper('МСБ, ДАМУ-РЕГИОНЫ Бизнес-Стандарт'),
         upper('МСБ. ЕБРР 2010'),
         upper('МСБ. ЕБРР. Экспресс'),
         upper('МСБ. По линии Акимата'),
         upper('МСБ. По линии ЕБРР'),
         upper('МСБ. ЕБРР 21')
     ) then 'DAMU'
     when upper(trim(t.F58))in (
         upper('МСБ. Лимит по овердрафту (краткосрочный займ)'),
         upper('МСБ. Лимит по овердрафту к текущему счету'),
         upper('МСБ. Овердрафт (краткосрочный займ)'),
         upper('МСБ. Лимит по овердрафту'),
         upper('МСБ. Овердрафт')
     ) then 'OVER'
     when upper(trim(t.F58))in (
         upper('МСБ. Бизнес-ДЕНЬ'),
         upper('МСБ. Бизнес-ДЕНЬ 2'),
         upper('МСБ. Ускор. схема под залог НЕДВИЖ.'),
         upper('МСБ.Бизнес-СТАНДАРТ Акция под 8%'),
         upper('МСБ. Ускор. схема под залог АВТО')
     ) then 'SMEUSKOR'
     when upper(trim(t.F58))in (
         upper('МСБ. Бизнес-СТАНДАРТ'),
         upper('МСБ, Бизнес-СТАНДАРТ')
     ) and trim(t.F31) = '10' -- аналог (LOAN_PURPOSE='10')
      then 'WC'
     when upper(trim(t.F58))in (
         upper('МСБ. Бизнес-СТАНДАРТ'),
         upper('МСБ, Бизнес-СТАНДАРТ')
     ) and trim(t.F31)in (
         '11','12','13','14','16','11.1','11.2','11.3','11.4','11.5','13.1','13.2','13.3','14.1','14.2','14.3'
     ) then 'INVEST'
     when upper(trim(t.F58))in (
         upper('МСБ. Бизнес-СТАНДАРТ'),
         upper('МСБ, Бизнес-СТАНДАРТ')
     ) and trim(t.F31) = '15' then 'SMECONS'
     when upper(trim(t.F58))in (
         upper('МСБ. Бизнес-СТАНДАРТ'),
         upper('МСБ, Бизнес-СТАНДАРТ')
     )  and trim(t.F31) = '20' then 'SMEOTHER'
     when upper(trim(t.F75)) = upper('мсб') then 'SME_OTHER'
   end as SMEPRODUCT
  ,case
     when upper(trim(t.F58))in (
         upper('МСБ. Бизнес-СТАНДАРТ'),
         upper('МСБ, Бизнес-СТАНДАРТ')
     ) then 'STANDART'
   end as SMEPRODUCT1
  ,case
      when (
            (upper(trim(t.F75)) = upper('корп')
             and upper(trim(t.F76)) in (upper('Mass and Afflnt'),upper('PI'),upper('mass and afflnt'))
            )
            or (upper(trim(t.F75)) = upper('розница потреб'))
           )
           and (trim(t.F58)='' or t.F58 is null)
      then 'OTHERPO'
     when upper(trim(t.F58))in (
         upper('ФЛ, Потребительские цели, Стандарт'),
         upper('ФЛ. Потребительские цели. Стандарт'),
         upper('ФЛ. Потребительские цели. Ремонт'),
         upper('ФЛ. Сотрудники, на потребительские цели'),
         upper('ФЛ, Потребительские цели, Ускоренная программа'),
         upper('ФЛ. Потребительские цели. Ускоренная программа'),
         upper('ФЛ. Потребительские цели. Акция. Pre approved')
     ) then 'secured'
     when upper(trim(t.F58))in (
         upper('ФЛ. Участники зарплатных проектов'),
         upper('ФЛ. Универсальный (не действительный с 2008 года)'),
         upper('ФЛ. Универсальный (не действительный с 28 года)'),
         upper('ФЛ. Cash&Go. Зарплатный проект. Потребительские цели'),
         upper('ФЛ, Cash&Go, Зарплатный проект, Потребительские цели'),
         upper('ФЛ.Cash&Go.МassMarket'),
         upper('ФЛ.Cash&Go. Рефинансирование'),
         upper('ФЛ.Cash&Go. Рассрочка Партнер'),
         upper('ФЛ. Потребительские цели. Обучение'),
         upper('ФЛ. Cash&Go. Ускоренный'),
         upper('ФЛ. Cash&Go. Рассрочка Филиал'),
         upper('ФЛ. Cash&Go. Нестандартный'),
         upper('ФЛ. Сотрудники, на потребительские цели. Без обеспечения.'),
         upper('ФЛ. Сотрудники, на обучение'),
         upper('ФЛ. Сотрудники. Cash&Go'),
         upper('ФЛ. Сотрудники. Лёгкий'),
         upper('ФЛ.Cash&Go. Metro'),
         upper('ФЛ.Cash&Go. Рассрочка'),
         upper('ФЛ. Лёгкий. Зарплатный проект. Потребительские цели'),
         upper('ФЛ. Лёгкий. Нестандартный'),
         upper('ФЛ. Лёгкий. Ускоренный'),
         upper('ФЛ. Лёгкий. Рассрочка Филиал'),
         upper('ФЛ.Лёгкий. Рассрочка Партнер'),
         upper('ФЛ.Лёгкий. Рефинансирование'),
         upper('ФЛ.Лёгкий.МassMarket')
     ) then 'unsecured'
   end as SECUNSEC
  ,case
     when upper(trim(t.F58))in (
         upper('ФЛ. Участники зарплатных проектов'),
         upper('ФЛ. Универсальный (не действительный с 2008 года)'),
         upper('ФЛ. Универсальный (не действительный с 28 года)'),
         upper('ФЛ. Потребительские цели. Обучение')
     ) then 'POTREB'
     when upper(trim(t.F58))in (
         upper('ФЛ. Потребительские цели. Стандарт'),
         upper('ФЛ, Потребительские цели, Стандарт'),
         upper('ФЛ, Потребительские цели, Ускоренная программа'),
         upper('ФЛ. Потребительские цели. Ускоренная программа'),
         upper('ФЛ. Потребительские цели. Ремонт')
     ) then 'POTREBSEC'
     when upper(trim(t.F58))in (
         upper('ФЛ. Сотрудники, на потребительские цели')
     ) then 'STAFFSEC'
     when upper(trim(t.F58))in (
         upper('ФЛ, Cash&Go, Зарплатный проект, Потребительские цели'),
         upper('ФЛ. Cash&Go. Зарплатный проект. Потребительские цели'),
         upper('ФЛ. Cash&Go. Рассрочка Филиал'),
         upper('ФЛ. Cash&Go. Ускоренный'),
         upper('ФЛ. Сash&Go.Зарплатный проект'),
         upper('ФЛ.Cash&Go. Metro'),
         upper('ФЛ.Cash&Go. Зарплатный проект. Рефинансирование'),
         upper('ФЛ.Cash&Go. Рассрочка'),
         upper('ФЛ.Cash&Go. Рассрочка Партнер'),
         upper('ФЛ.Cash&Go. Рефинансирование'),
         upper('ФЛ.Cash&Go.МassMarket'),
         upper('ФЛ. Лёгкий. Зарплатный проект. Потребительские цели'),
         --upper('ФЛ. Лёгкий. Нестандартный'),
         upper('ФЛ. Лёгкий. Ускоренный'),
         upper('ФЛ. Лёгкий. Рассрочка Филиал'),
         upper('ФЛ.Лёгкий. Рассрочка Партнер'),
         upper('ФЛ.Лёгкий. Рефинансирование'),
         upper('ФЛ.Лёгкий.МassMarket')
     ) then 'CASHGO'
     when upper(trim(t.F58))in (
         upper('ФЛ. Cash&Go. Нестандартный'),
         upper('ФЛ. Лёгкий. Нестандартный')
     ) then 'CGNEST'
     when upper(trim(t.F58))in (
         upper('ФЛ. Сотрудники. Cash&Go'),
         upper('ФЛ. Сотрудники, на обучение'),
         upper('ФЛ. Сотрудники, на потребительские цели. Без обеспечения.'),
         upper('ФЛ. Сотрудники. Лёгкий')
     ) then 'STAFF'
     when trim(t.F39) in ('106.580','107.310','107.319') then 'VIP'
     when ((upper(trim(t.F75)) = upper('розница авто')) or
           (upper(trim(t.F58)) in (upper('ФЛ. Потребительские цели. Под залог авто'),
                                  upper('ФЛ. Потребительские цели. Под залог авто. Стандарт'),
                                  upper('ФЛ. Потребительские цели. Под залог авто. Упрощенный'))
           ))
           and (trim(t.F58)='' or t.F58 is null)
     then 'AUTOOTHER'
     when upper(trim(t.F58))in (
         upper('ФЛ. Автокредиты. Новые. Автосалон. Стандарт'),
         upper('ФЛ. Автокредиты. Новые. Автосалон. Ускоренная программа'),
         upper('ФЛ. Автокредиты. Новые. Стандарт'),
         upper('ФЛ. Автокредиты. Новые. Ускоренная программа')
     ) then 'AUTONEW'
     when upper(trim(t.F58))in (
         upper('ФЛ. Автокредиты. Подержанные.')
     ) then 'AUTOUSED'
     when upper(trim(t.F58))in (
         upper('ФЛ. Потребительские цели. Под залог авто'),
         upper('ФЛ. Потребительские цели. Под залог авто. Стандарт'),
         upper('ФЛ. Потребительские цели. Под залог авто. Упрощенный')
     ) then 'AUTOCONS'
     when upper(trim(t.F58))in (
         upper('ФЛ. Сотрудники, на приобретение авто')
     ) then 'AUTOSTAFF'
     when upper(trim(t.F75)) = upper('розница ипотека') and (trim(t.F58)='' or t.F58 is null) then 'IPOTOTHER'
     when upper(trim(t.F58))in (
         upper('ФЛ, Ипотека-вторичный рынок'),
         upper('ФЛ. Ипотека-вторичный рынок'),
         upper('ФЛ, Ипотека-долевое участие'),
         upper('ФЛ. Ипотека-долевое участие'),
         upper('ФЛ. Ипотека-БУМ'),
         upper('ФЛ. Ипотека-Выбор (ПВ 20%)'),
         upper('ФЛ. Ипотека-Выбор (ПВ 30%)'),
         upper('ФЛ. Ипотека-Выбор (ПВ 40%)'),
         upper('ФЛ. Ипотека-Выбор (ПВ 50%)'),
         upper('ФЛ. Ипотека. КИК. Вторичный рынок'),
         upper('ФЛ. Ипотека. КИК. Первичный рынок'),
         upper('ФЛ. Самрук-Казына Ипотека-Свободная цена')
     ) then 'IPOT'
     when upper(trim(t.F58))in (
         upper('ФЛ. Ипотека-ремонт'),
         upper('ФЛ. Ипотека-строительство'),
         upper('ФЛ. Ипотека. КИК. Ремонт'),
         upper('ФЛ. Ипотека. КИК. Строительство'),
         upper('ФЛ. Ипотека-земельный участок')
     ) then 'IPOTREMSTR'
     when upper(trim(t.F58))in (
         upper('ФЛ. Ипотека-Рефинансирование. Рядовые кредиты'),
         upper('ФЛ. Ипотека-Рефинансирование. Социальные кредиты'),
         upper('ФЛ. Ипотека-рефинансирование')
     ) then 'IPOTREF'
     when upper(trim(t.F58))in (
         upper('ФЛ. Сотрудники, на приобретение недвижимости')
     ) then 'IPOTSTAFF'
   end as SECTYPE
  ,case
     when upper(trim(t.F58))in (
         upper('ФЛ.Cash&Go.МassMarket'),
         upper('ФЛ. Сash&Go.Зарплатный проект'),
         upper('ФЛ. Cash&Go. Зарплатный проект. Потребительские цели'),
         upper('ФЛ, Cash&Go, Зарплатный проект, Потребительские цели'),
         upper('ФЛ. Лёгкий. Зарплатный проект. Потребительские цели'),
         upper('ФЛ.Лёгкий.МassMarket')
     ) then 'CGM'
     when upper(trim(t.F58))in (
         upper('ФЛ. Cash&Go. Ускоренный'),
         upper('ФЛ. Лёгкий. Ускоренный')
     ) then 'CGUSK'
     when upper(trim(t.F58))in (
         upper('ФЛ.Cash&Go. Рефинансирование'),
         upper('ФЛ.Cash&Go. Зарплатный проект. Рефинансирование'),
         upper('ФЛ.Лёгкий. Рефинансирование')
     ) then 'CGREF'
     when upper(trim(t.F58))in (
         upper('ФЛ.Cash&Go. Рассрочка'),
         upper('ФЛ.Cash&Go. Рассрочка Партнер'),
         upper('ФЛ.Cash&Go. Metro'),
         upper('ФЛ. Cash&Go. Рассрочка Филиал'),
         upper('ФЛ. Лёгкий. Рассрочка Филиал'),
         upper('ФЛ.Лёгкий. Рассрочка Партнер')
     ) then 'CGRAS'
   end as CASH
  ,case
     when upper(trim(t.F58))in (
         upper('ФЛ.Cash&Go.МassMarket'),
         upper('ФЛ.Лёгкий.МassMarket')
     ) then 'CGMM'
     when upper(trim(t.F58))in (
         upper('ФЛ. Сash&Go.Зарплатный проект'),
         upper('ФЛ. Cash&Go. Зарплатный проект. Потребительские цели'),
         upper('ФЛ, Cash&Go, Зарплатный проект, Потребительские цели'),
         upper('ФЛ. Лёгкий. Зарплатный проект. Потребительские цели')
     ) then 'CGSAL'
     when upper(trim(t.F58))in (
         upper('ФЛ.Cash&Go. Рассрочка'),
         upper('ФЛ. Cash&Go. Рассрочка Филиал'),
         upper('ФЛ. Лёгкий. Рассрочка Филиал')
     ) then 'CGRASFIL'
     when upper(trim(t.F58))in (
         upper('ФЛ.Cash&Go. Metro'),
         upper('ФЛ.Cash&Go. Рассрочка Партнер'),
         upper('ФЛ.Лёгкий. Рассрочка Партнер')
     ) then 'CGRASPAR'
   end as CASH_PRODUCT
  ----------------- плавающая часть
  ,case when t.f35 is null or trim(upper(t.f35)) in('','N') then 0 else 1 end  as flag_restruct   --Признак реструктуризации (текущий)   N, " ", NULL - не реструкт
  ,case when x.report_dt is null then 0 else 1 end as flag_out_balance    --Признак списания за баланс (должен быть установлен для данных, загруженных из файла 7130)

  ,to_number(trim(t.F17)) as prc_amt_val --Начисленные % в валюте
  ,to_number(trim(t.F18)) as prc_amt_kzt --Начисленные % в тенге
  /*,case
      when x.report_dt is null then to_number(trim(nvl(t.F13,'0')))
      else to_number(trim(nvl(x1.F14,'0')))
   end as LOANREST  --ost_od --Остаток задолжености*/
  ,to_number(trim(nvl(t.F13,'0'))) as LOANREST  --ost_od --Остаток задолжености*/
  ,sum(to_number(trim(t.F13))) over(partition by t.report_dt) as LOANREST_ALL_MONTH


  ,to_number(trim(t.F30)) as penalty  --Штрафы и пени
  ,to_number(trim(t.F28)) as discount  --Дисконт по займу

  ,to_number(trim(t.F80)) as od_day_def--№ principal dpd
  ,to_number(trim(t.F81)) as prc_day_def  --№ interest dpd
  ,z.F15 as def_days_od--Количество дней просрочки ОД
  ,z.F21 as def_days_prc--Количество дней просрочки %
  ,z.f12 as def_amt_od --Размер просроченного ОД (экв. в KZT и в валюте займа)
  ,GREATEST(to_number(z.F15),to_number(z.F21)) as def_days
  ,case
     when t.F10 = 'KZT' then to_number(trim(z.f12))
     when t.F10 = 'USD' then to_number(trim(z.F12))/r.usd
     when t.F10 = 'GBR' then to_number(trim(z.F12))/r.gbr
     when t.F10 = 'RUB' then to_number(trim(z.F12))/r.rub
     when t.F10 = 'EUR' then to_number(trim(z.F12))/r.eur
   end as def_amt_od_val
  ,z.f18 as def_amt_prc --Размер просроченного % (экв. в KZT и в валюте займа)
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
   and trim(t.f1) <> 'МФО' and trim(t.f1) <> 'F1' and t.f1 is not null
   --t.f58 = 'ФЛ. Автокредиты. Новые. Автосалон. Стандарт'
   --t.f6 = '828357'
   --t.F10 = 'USD'
          --'821207'
         --'1609128'
order by t.report_dt
;

