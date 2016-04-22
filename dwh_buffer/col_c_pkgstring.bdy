create or replace package body dwh_buffer.col_C_pkgString is

  function fToken2(cStr        in varchar2,
                   iNum        in integer,
                   cDelimiters in varchar2 default '.,') return varchar2 as
    type tDelimitersPos is table of pls_integer index by binary_integer;
    dp   tDelimitersPos; -- список позиций разделителей
    iLen pls_integer := length(cStr);
    i    pls_integer := 1;
  begin
    dp(1) := 0;
    while i <= iLen loop
      if instr(cDelimiters, substr(cStr, i, 1)) > 0 then
        dp(dp.count + 1) := i;
        exit when dp.count > iNum; -- нашли обе границы "слова"
      end if;
      i := i + 1;
    end loop;
    if iNum < dp.count then
      i := dp(iNum);
      return substr(cStr, i + 1, dp(iNum + 1) - i - 1);
    elsif iNum = dp.count then
      return substr(cStr, dp(iNum) + 1);
    else
      return null;
    end if;
  end;
 

 function fChkCond(cAttr in varchar2, cValue in varchar2) return boolean is
    iToken      pls_integer; -- конец вхождения токена (позиция разделителя токенов)
    iNext       pls_integer := 1; -- первый символ токена
    iFound1     pls_integer;
    iFound2     pls_integer;
    iMax        pls_integer; -- длина разбираемой строки
    bChecked    boolean := false; -- состояние проверки
    bBetween    boolean := false; -- условие between
    cToken      varchar2(250); -- текст токена
    cToken0     varchar2(250); -- предыдущий текст токена
    cDlm        char(1); -- текст разделителя.
    cOrDlm      char(1) := ','; -- символ для условия or
    cBetweenDlm char(1) := ':'; -- символ для условия between
    cTyp        char(1) := 'S';

  begin
    iMax := length(cValue);
    if iMax=0 then
      --C_PkgErr.pRegMsg(1702,null,null);
      null;
    end if;
    if substr(cValue, 1, 2) = '$N' then
      cTyp  := 'N';
      iNext := 3;
    elsif substr(cValue, 1, 2) = '$D' then
      cTyp  := 'D';
      iNext := 3;
    end if;

    loop
      -- цикл поиска вхождения ключей поиска (токенов) и разделителей в строке
      iFound1 := instr(cValue, cOrDlm, iNext);
      iFound2 := instr(cValue, cBetweenDlm, iNext);
      if iFound1 = 0 then
        iToken := iFound2;
      elsif iFound2 = 0 then
        iToken := iFound1;
      else
        iToken := least(iFound1, iFound2);
      end if;
      if iToken = 0 then
        -- нет больше вхождений разделителей
        iToken := iMax + 1;
        cDlm   := cOrDlm;
      else
        cDlm := substr(cValue, iToken, 1);
      end if;
      cToken := ltrim(rtrim(substr(cValue, iNext, iToken - iNext)));
      if cToken is null and iToken = iMax + 1 then
        null;
        /*C_PkgErr.pRegMsg(1703,
                         Localize('%0=> оканчивается',
                                  'PKG',
                                  'C_PKGSTRING'),
                         null);*/
      elsif cToken is null and iNext = 1 then
        null;
        /*C_PkgErr.pRegMsg(1703,
                         Localize('%0=> начинается',
                                  'PKG',
                                  'C_PKGSTRING'),
                         null);*/
      elsif cToken is null then
        --C_PkgErr.pRegMsg(1700, null, null);
        null;
      end if;

      -- контроль соотвествия значения условию
      if cDlm = cOrDlm then
        -- запятая.
        if bBetween then
          if cTyp = 'S' then
            bChecked := cAttr >= cToken0 and cAttr <= cToken;
          elsif cTyp = 'N' then
            bChecked := to_number(cAttr) >= to_number(cToken0) and
                        to_number(cAttr) <= to_number(cToken);
          else
            bChecked := to_date(cAttr) >= to_date(cToken0) and
                        to_date(cAttr) <= to_date(cToken);
          end if;
          bBetween := false;
          cToken0  := null;
        else
          if cTyp in ('S', 'D') then
            bChecked := cAttr like cToken;
          else
            bChecked := to_number(cAttr) = to_number(cToken);
          end if;
        end if;
      else
        -- двоеточие
        if bBetween then
          null;
          /*C_PkgErr.pRegMsg(1700,
                           Localize('%0=> "двоеточие"',
                                    'PKG',
                                    'C_PKGSTRING'),
                           null);*/
        else
          cToken0  := cToken;
          bBetween := true;
        end if;
      end if;
      if bChecked then
        return(true);
      end if;
      iNext := iToken + 1;
      exit when iNext > iMax; -- нет больше вхождений
    end loop;

    return(false);
  end;


begin
  -- Initialization
  null;
end col_C_pkgString;
/

