create or replace force view dwh_risk.uwi_proc_stages as
select 'E3349D02-06F8-4805-A1B9-468299EAFC6BОтклонена - Скоринговое решение' status,'Отказ' stage,0 staff_process,
0 wrong_client_data,0 stopped_before_scoring,0 stopped_after_scoring,1 is_application,0 approved_scoring,
0 approved_verification,0 credit_admins_passed,0 client_got_money, 1 ready_for_scoring,0 ready_for_verif  from dual union all

select 'HR: Отклонена' status,'Отказ' stage,1 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select 'Верификация' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select 'Веррификация' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select 'Выбор Руководителя' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select 'Дополнительное согласование условий с клиентом' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select 'Досье возвращено консультанту' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,1 p8,0 p9,1 p10,1 p11  from dual union all
select 'Досье возвращено на ПКАФ' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,1 p9,1 p10,1 p11  from dual union all
select 'Завершен' status,'Одобрено' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,1 p9,1 p10,1 p11  from dual union all
select 'ЗавершенЗавершен' status,'Одобрено' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,1 p9,1 p10,1 p11  from dual union all
select 'Завершено' status,'Одобрено' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,1 p9,1 p10,1 p11  from dual union all
select 'ЗавершеноОткрытие текущего счета' status,'Одобрено' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,1 p9,1 p10,1 p11  from dual union all
select 'Заполнение Ф2' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select 'Запрос на принятие заявки Архивом' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,1 p9,1 p10,1 p11  from dual union all
select 'Запрос на принятие заявки для ПКАФ' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,1 p9,1 p10,1 p11  from dual union all
select 'Запрос на принятие заявки для проверки полноты досье' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select 'Запрос на принятие заявки Клиента - DSA' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select 'Заявка автоматически отклонена' status,'Отказ' stage,0 p1,0 p2,0 p3,0 p4,1 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select 'Консультант' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select 'Консультант по кредитованию сотрудников' status,'В работе' stage,1 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select 'На доработке – Верификатор' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select 'Не обновленный отчет ПКБ' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,0 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select 'Ожидание верификации' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select 'Отказ клиента – Дополнительные телефоны' status,'Отмена' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select 'Отклонена - Скоринговое решение' status,'Отказ' stage,0 p1,0 p2,0 p3,0 p4,1 p5,0 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select 'Отклонена-Проверка полноты досье' status,'Одобрено' stage,0 p1,0 p2,0 p3,0 p4,1 p5,0 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select 'Открытие текущего счета' status,'Одобрено' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,0 p9,1 p10,1 p11  from dual union all
select 'Отменен' status,'Отмена' stage,0 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select 'Отменена' status,'Отмена' stage,0 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select 'Отменена  - До верификации' status,'Отмена' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select 'Отменена  - До верификации - DSA' status,'Отмена' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select 'Отменена  - до согласования с Руководителем' status,'Отмена' stage,0 p1,0 p2,1 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select 'Отменена  Клиентом' status,'Отмена' stage,0 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select 'Отменена  Клиентом - До верификации' status,'Отмена' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select 'Отменена  Клиентом - До верификации - DSA' status,'Отмена' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select 'Отменена  Клиентом -КЦ' status,'Отмена' stage,0 p1,0 p2,1 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select 'Отменена - Верификатора' status,'Отмена' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select 'Отменена - Проверка полнаты досье' status,'Отмена' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,1 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select 'Отменена – Верификация' status,'Отмена' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select 'Отменена – Верификация. Вина консультанта' status,'Отмена' stage,0 p1,1 p2,0 p3,1 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select 'Отменена – Верификация. Клиент не согласен с предложенными условиями' status,'Отмена' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select 'Отменена – Верификация. Указанный ОД рефинансируемого займа не соответствует значению из справки о ссудной задолженности' status,'Отмена' stage,0 p1,1 p2,0 p3,1 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select 'Отменена – Верификация. Установлен срок действия отказа' status,'Отмена' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select 'Отменена – До подписания договора купли продажи' status,'Отмена' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,1 p7,1 p8,0 p9,1 p10,1 p11  from dual union all
select 'Отменена – Открытие текущего счета' status,'Отмена' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,1 p7,1 p8,0 p9,1 p10,1 p11  from dual union all
select 'Отменена – Подготовка к выдаче' status,'Отмена' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,1 p7,1 p8,0 p9,1 p10,1 p11  from dual union all
select 'Отменена – после Ф1' status,'Отмена' stage,0 p1,0 p2,1 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select 'Отменена – после Ф2' status,'Отмена' stage,0 p1,0 p2,1 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select 'Отменена Клиентом - До верификации' status,'Отмена' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select 'Отменена консультантом, предоставленный клиентом ИИН не числится в регистрах ГЦВП' status,'Отмена' stage,0 p1,1 p2,1 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select 'Отменена КЦ' status,'Отмена' stage,0 p1,0 p2,1 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select 'Отменена на этапе открытия счетов' status,'Отмена' stage,0 p1,0 p2,0 p3,1 p4,1 p5,1 p6,1 p7,1 p8,0 p9,1 p10,1 p11  from dual union all
select 'Отменена системой, предоставленный клиентом ФИО не числится в регистрах ГЦВП' status,'Отмена' stage,0 p1,1 p2,1 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select 'Отправка досье в ПКАФ' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,1 p9,1 p10,1 p11  from dual union all
select 'Отправка досье ПКАФ' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,1 p9,1 p10,1 p11  from dual union all
select 'Передача досье в Архив' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,1 p9,1 p10,1 p11  from dual union all
select 'Подтверждение получения досье ПКАФ' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,1 p9,1 p10,1 p11  from dual union all
select 'Предоставление дополнительной информации' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select 'Прикрепление документов' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select 'Проверка HR' status,'В работе' stage,1 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select 'Проверка вызова скоринга' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,0 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select 'Проверка ИИН' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select 'Проверка полноты досье' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,0 p8,0 p9,1 p10,1 p11  from dual union all
select 'Регистрация' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select 'Рефинансируемый заем не выбран' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select 'Сбор подписей и подготовка к выдаче' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,1 p7,1 p8,0 p9,1 p10,1 p11  from dual union all
select 'Сканирование документов' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select 'Согласование Руководителя' status,'В работе' stage,1 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select 'Согласование условий с клиентом' status,'В работе' stage,0 p1,0 p2,0 p3,0 p4,1 p5,1 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual union all
select 'Срок действия Ф2 истек' status,'Отмена' stage,0 p1,0 p2,0 p3,0 p4,0 p5,0 p6,0 p7,0 p8,0 p9,0 p10,0 p11  from dual union all
select 'Срок скорингового решения истек(1)' status,'Отмена' stage,0 p1,0 p2,0 p3,0 p4,1 p5,0 p6,0 p7,0 p8,0 p9,1 p10,0 p11  from dual;

