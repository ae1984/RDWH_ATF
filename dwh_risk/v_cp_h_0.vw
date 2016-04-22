create or replace force view dwh_risk.v_cp_h_0 as
select
    --t.SDT        --системная дата добавления записи
    t.REPORT_DT --дата отчета из имени файла
    ,EXTRACT(year FROM t.report_dt)*100+EXTRACT(month FROM t.report_dt) as report_ymd
    ,t.F1  --МФО--
    ,t.F2  --Лицевой счет--
    ,t.F3  --НПС--
    ,t.F4  --Лицевой счет просроченной задолженности--
    ,t.F5  --Наименование  заемщика--
    ,t.F6  --Код клиента--
    ,t.F7  --ИИН--
    ,t.F8  -- № кредитной линии--
    ,t.F9  -- № договора --
    ,t.F10 --Валюта --
    ,nvl(to_number(t.F11),0) F11 --+Валюта выдачи--
    ,nvl(to_number(t.F12),0) F12 --+Эквивалент в тенге--
    ,nvl(to_number(t.F13),0) F13 --+Остаток задолжености--
    ,nvl(to_number(t.F14),0) F14 --+Остаток просроченной задолженности в тенге--
    ,to_number(t.F15) F15 --+Начальная процентная ставка--
    ,to_number(replace(t.F16,'.',',')) F16 --+Процентная ставка--
    ,nvl(to_number(t.F17),0) F17 --+Начисленные % в валюте--
    ,nvl(to_number(t.F18),0) F18 --+Начисленные % в тенге --
    ,nvl(to_number(t.F19),0) F19 --+Начисленные % по просрочке в тенге --
    ,nvl(to_number(t.F20),0) F20 --+Сумма начисленных комиссий--
    ,nvl(to_number(t.F21),0) F21 --+Сумма просроченнх комиссий--
    --,to_date(t.F22) F22 --*Дата выдачи--
    ,t.F22
    ,nvl(EXTRACT(year FROM to_date(t.F22))*100+EXTRACT(month FROM to_date(t.F22)),0) as loan_issue_ym
    ,t.F23
    --,to_date(t.F23) F23 --*Дата погашения--
    ,to_number(t.F24) F24 --+% провизии--
    ,nvl(to_number(t.F25),0) F25 --+Сумма провизии--
    ,t.F26 --Отрасль заемщика--
    ,t.F27 --Тип продукта--
    ,nvl(to_number(t.F28),0) F28 --+Дисконт по займу--
    ,nvl(to_number(t.F29),0) F29 --+IFRS interest--
    ,nvl(to_number(t.F30),0) F30 --+Штрафы и пени--
    ,t.F31 --Код объекта кредитования--
    ,t.F32 --Связанная сторона с банком да/нет--
    ,t.F33 --Вид портфеля--
    ,to_date(t.F34) F34 --+Дата проставления признака (текущий)--
    ,t.F35 --Признак реструктуризации (текущий)--
    --,to_date(t.F36) F36 --Дата проставления признака (предыдущий)--
    ,t.F36
    ,t.F37 --Признак реструктуризации (предыдущий)--
    ,t.F38 --Дата последней реструктуризации--
    ,t.F39 --Код VCC--
    ,to_number(t.F40) F40 --+Эффективная процентная ставка--
    ,t.F41 --Код NACE--
    ,t.F42 --Код OLAV--
    ,t.F43 --Финансовый рейтинг--
    ,t.F44 --Утвержденный рейтинг--
    ,t.F45 --BLANA--
    --,to_date(t.F46) F46 --*Дата утверждения рейтинга--
    ,t.F46
    ,to_date(t.F47) F47 --+Дата финансовой отчетности--
    ,to_date(t.F48) F48 --+Дата следующего пересмотра рейтинга--
    ,t.F49 --Код PSC--
    ,nvl(to_number(t.F50),0) F50 --+Сумма договора в старой системе--
    ,t.F51 --Признак подразделения--
    ,t.F52 --Цель использования--
    ,t.F53 --Референс--
    ,t.F54 --Референс кредитной линии--
    ,t.F55 --Вид индикатора--
    ,t.F56 --Вид ставки вознаграждения--
    ,t.F57 --Код продукта АТФ--
    ,t.F58 --Наименование продукта АТФ--
    ,t.F59 --Подсектор экономики--
    ,t.F60 --ID транша в системе--
    ,nvl(to_number(t.F61),0) F61 --+МСФО провизии на основной долг--
    ,nvl(to_number(t.F62),0) F62 --+МСФО провизии на %--
    ,t.F63 --РНН--
    ,t.F64 --Риск-менеджер--
    ,t.F65 --Кредитный менеджер--
    ,nvl(to_number(t.F66),0) F66 --+МСФО провизии ОД--
    ,nvl(to_number(t.F67),0) F67 --+МСФО провизии %--
    ,t.F68 --Код точки продаж--
    ,t.F69 --Наименование точки продаж--
    ,t.F70 --Группа РМ--
    ,t.F71 --Юл - Фл--
    ,t.F72 --резидентство--
    ,nvl(to_number(t.F73),0) F73  --+ Outstanding --
    ,t.F74 --IFRS Industry--
    ,t.F75 --Type of business--
    ,t.F76 --VCC name--
    --,t.F77 --SHORT VCC--
    ,case when t.f77 = 'Private' then 'PB' else t.f77 end F77
    ,t.F78 --RWO--
    ,t.F79 --RWO_short--
    ,nvl(to_number(t.F80),0) F80 --+№ principal dpd--
    ,nvl(to_number(t.F81),0) F81 --+№ interest dpd--
    ,nvl(to_number(t.F82),0) F82 --+MAX--
    ,nvl(to_number(t.F83),0) F83 --+ COLLATERAL --
    ,nvl(to_number(t.F84),0) F84 --+ Adjusted COLLATERAL --
    ,t.F85 --ДИАПАЗОН MIGRATION--
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
    ,t.F104  --откорректированные договора--
    ,t.F105  --Код/Догов--
    ,a.f4 as oked
    --,t.TMP
from XLS_H_CP_HIST t
left join (
    select  distinct t.f2, trim(first_value(t.f4) over(partition by t.f2 order by t.f1))f4  from XLS_H_OKED_20160201 t
    where length(regexp_replace(t.f2, '[^0-9]', '')) > 0
) a on a.f2 = trim(t.f26)
where t.f53 is not null and nvl(trim(t.f1),'-') <> 'МФО' and nvl(upper(trim(t.f2)),'-') <>upper('Лицевой счет')
     -- and t.REPORT_DT >= add_months(trunc(sysdate,'MM'),-6)
;

