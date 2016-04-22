create or replace force view dwh_risk.v_oked as
select to_char(t.id_oked,'00') id_oked, t.otr from

(

select 1 id_oked, 'Сельское хозяйство, охота и лесное хозяйство' otr from dual union all
select 2 id, 'Сельское хозяйство, охота и лесное хозяйство' otr from dual union all
select 3 id, 'Прочее' otr from dual union all
select 4 id, 'Прочее' otr from dual union all
select 5 id, 'Рыболовство, рыбоводство  ' otr from dual union all
select 6 id, 'Прочее' otr from dual union all
select 7 id, 'Прочее' otr from dual union all
select 8 id, 'Прочее' otr from dual union all
select 9 id, 'Прочее' otr from dual union all
select 10 id, 'Добыча топливно - энергетических полезных ископаемых ' otr from dual union all
select 11 id, 'Добыча топливно - энергетических полезных ископаемых ' otr from dual union all
select 12 id, 'Добыча топливно - энергетических полезных ископаемых ' otr from dual union all
select 13 id, 'Горнодобывающая  промышленность' otr from dual union all
select 14 id, 'Горнодобывающая  промышленность' otr from dual union all
select 15 id, 'Производство пищевых продуктов' otr from dual union all
select 16 id, 'Производство пищевых продуктов' otr from dual union all
select 17 id, 'Текстильная и швейная промышленность  ' otr from dual union all
select 18 id, 'Текстильная и швейная промышленность  ' otr from dual union all
select 19 id, 'Производство кожи, изделий из кожи и производство обуви  ' otr from dual union all
select 20 id, 'Обработка древесины и производство изделий из дерева ' otr from dual union all
select 21 id, 'Целлюлозно-бумажная промышленность; издательское дело ' otr from dual union all
select 22 id, 'Целлюлозно-бумажная промышленность; издательское дело ' otr from dual union all
select 23 id, 'Производство кокса, нефтепродуктов и ядерных материалов ' otr from dual union all
select 24 id, 'Химическая промышленность ' otr from dual union all
select 25 id, 'Производство резиновых и пластмассовых изделий' otr from dual union all
select 26 id, 'Производство прочих неметаллических минеральных продуктов' otr from dual union all
select 27 id, 'Металлургическая промышленность и производство готовых металлических изделий' otr from dual union all
select 28 id, 'Металлургическая промышленность и производство готовых металлических изделий' otr from dual union all
select 29 id, 'Производство машин и оборудования' otr from dual union all
select 30 id, 'Производство электрооборудования, электронного и оптического оборудования ' otr from dual union all
select 31 id, 'Производство электрооборудования, электронного и оптического оборудования ' otr from dual union all
select 32 id, 'Производство электрооборудования, электронного и оптического оборудования ' otr from dual union all
select 33 id, 'Производство электрооборудования, электронного и оптического оборудования ' otr from dual union all
select 34 id, 'Производство транспортных средств и оборудования  ' otr from dual union all
select 35 id, 'Производство транспортных средств и оборудования  ' otr from dual union all
select 36 id, 'Прочие отрасли промышленности' otr from dual union all
select 37 id, 'Прочие отрасли промышленности' otr from dual union all
select 40 id, 'Производство и распределение электроэнергии, газа и воды ' otr from dual union all
select 41 id, 'Производство и распределение электроэнергии, газа и воды ' otr from dual union all
select 42 id, 'Прочее' otr from dual union all
select 43 id, 'Прочее' otr from dual union all
select 44 id, 'Прочее' otr from dual union all
select 45 id, 'Строительство ' otr from dual union all
select 50 id, 'Торговля; ремонт автомобилей, бытовых изделий и предметов личного пользования' otr from dual union all
select 51 id, 'Торговля; ремонт автомобилей, бытовых изделий и предметов личного пользования' otr from dual union all
select 52 id, 'Торговля; ремонт автомобилей, бытовых изделий и предметов личного пользования' otr from dual union all
select 53 id, 'Прочее' otr from dual union all
select 54 id, 'Прочее' otr from dual union all
select 55 id, 'Гостиницы и рестораны   ' otr from dual union all
select 56 id, 'Прочее' otr from dual union all
select 57 id, 'Прочее' otr from dual union all
select 58 id, 'Прочее' otr from dual union all
select 59 id, 'Прочее' otr from dual union all
select 60 id, 'Транспорт и связь   ' otr from dual union all
select 61 id, 'Транспорт и связь   ' otr from dual union all
select 62 id, 'Транспорт и связь   ' otr from dual union all
select 63 id, 'Транспорт и связь   ' otr from dual union all
select 64 id, 'Транспорт и связь   ' otr from dual union all
select 65 id, 'Финансовая деятельность    ' otr from dual union all
select 66 id, 'Финансовая деятельность    ' otr from dual union all
select 67 id, 'Финансовая деятельность    ' otr from dual union all
select 68 id, 'Прочее' otr from dual union all
select 69 id, 'Прочее' otr from dual union all
select 70 id, 'Операции с недвижимым имуществом, аренда и предоставление услуг' otr from dual union all
select 71 id, 'Операции с недвижимым имуществом, аренда и предоставление услуг' otr from dual union all
select 72 id, 'Операции с недвижимым имуществом, аренда и предоставление услуг' otr from dual union all
select 73 id, 'Операции с недвижимым имуществом, аренда и предоставление услуг' otr from dual union all
select 74 id, 'Операции с недвижимым имуществом, аренда и предоставление услуг' otr from dual union all
select 75 id, 'Государственное управление ' otr from dual union all
select 76 id, 'Прочее' otr from dual union all
select 77 id, 'Прочее' otr from dual union all
select 78 id, 'Прочее' otr from dual union all
select 79 id, 'Прочее' otr from dual union all
select 80 id, 'Образование ' otr from dual union all
select 81 id, 'Прочее' otr from dual union all
select 82 id, 'Прочее' otr from dual union all
select 83 id, 'Прочее' otr from dual union all
select 84 id, 'Прочее' otr from dual union all
select 85 id, 'Здравоохранение и предоставление социальных услуг' otr from dual union all
select 86 id, 'Прочее' otr from dual union all
select 87 id, 'Прочее' otr from dual union all
select 88 id, 'Прочее' otr from dual union all
select 89 id, 'Прочее' otr from dual union all
select 90 id, 'Предоставление коммунальных, социальных и персональных услуг' otr from dual union all
select 91 id, 'Предоставление коммунальных, социальных и персональных услуг' otr from dual union all
select 92 id, 'Предоставление коммунальных, социальных и персональных услуг' otr from dual union all
select 93 id, 'Предоставление коммунальных, социальных и персональных услуг' otr from dual union all
select 94 id, 'Прочее' otr from dual union all
select 95 id, 'Предоставление услуг по ведению домашнего хозяйства' otr from dual union all
select 96 id, 'Прочее' otr from dual union all
select 97 id, 'Прочее' otr from dual union all
select 98 id, 'Прочее' otr from dual union all
select 99 id, 'Деятельность экстерриториальных организаций' otr from dual
) t;

