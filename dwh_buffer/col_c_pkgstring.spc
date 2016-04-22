create or replace package dwh_buffer.col_C_pkgString is

  -- Author  : ALEXEY-YE
  -- Created : 28.10.2015 12:34:49
  -- Purpose : 
  
  -- Возвращает слово из строки cStr (iNum от начала), разделители слов передаются в cDelimiters
  -- два подряд разделителя считаются словом null
  -- Если слова не можен быть выделено, то возвращается null.
  function fToken2(cStr        in varchar2,
                   iNum        in integer,
                   cDelimiters in varchar2 default '.,') return varchar2;
                   
  /* Проверяет, подходит ли строка cAttr под условие cValue, где последнее
   задано в виде строки формата VAL10,VAL30:VAL50,VAL70,VAL9%,VAL_8.
    Правила разбора соответствуют правилам, по которым работает fTrnStrToWhere,
    только длина значения в условии не ограничивается 30-ю символами.
  В первых двух символах cValue можно задать директиву, чтобы обрабатывать строку как число $N или как дату $D.
  Тогда при сравнении строка и токены условия будут преобразовываться в числа или в строки */
  function fChkCond(cAttr in varchar2, cValue in varchar2) return boolean;                   

end col_C_pkgString;
/

