create or replace package body dwh_buffer.col_C_pkgString is

  function fToken2(cStr        in varchar2,
                   iNum        in integer,
                   cDelimiters in varchar2 default '.,') return varchar2 as
    type tDelimitersPos is table of pls_integer index by binary_integer;
    dp   tDelimitersPos; -- ������ ������� ������������
    iLen pls_integer := length(cStr);
    i    pls_integer := 1;
  begin
    dp(1) := 0;
    while i <= iLen loop
      if instr(cDelimiters, substr(cStr, i, 1)) > 0 then
        dp(dp.count + 1) := i;
        exit when dp.count > iNum; -- ����� ��� ������� "�����"
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
    iToken      pls_integer; -- ����� ��������� ������ (������� ����������� �������)
    iNext       pls_integer := 1; -- ������ ������ ������
    iFound1     pls_integer;
    iFound2     pls_integer;
    iMax        pls_integer; -- ����� ����������� ������
    bChecked    boolean := false; -- ��������� ��������
    bBetween    boolean := false; -- ������� between
    cToken      varchar2(250); -- ����� ������
    cToken0     varchar2(250); -- ���������� ����� ������
    cDlm        char(1); -- ����� �����������.
    cOrDlm      char(1) := ','; -- ������ ��� ������� or
    cBetweenDlm char(1) := ':'; -- ������ ��� ������� between
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
      -- ���� ������ ��������� ������ ������ (�������) � ������������ � ������
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
        -- ��� ������ ��������� ������������
        iToken := iMax + 1;
        cDlm   := cOrDlm;
      else
        cDlm := substr(cValue, iToken, 1);
      end if;
      cToken := ltrim(rtrim(substr(cValue, iNext, iToken - iNext)));
      if cToken is null and iToken = iMax + 1 then
        null;
        /*C_PkgErr.pRegMsg(1703,
                         Localize('%0=> ������������',
                                  'PKG',
                                  'C_PKGSTRING'),
                         null);*/
      elsif cToken is null and iNext = 1 then
        null;
        /*C_PkgErr.pRegMsg(1703,
                         Localize('%0=> ����������',
                                  'PKG',
                                  'C_PKGSTRING'),
                         null);*/
      elsif cToken is null then
        --C_PkgErr.pRegMsg(1700, null, null);
        null;
      end if;

      -- �������� ����������� �������� �������
      if cDlm = cOrDlm then
        -- �������.
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
        -- ���������
        if bBetween then
          null;
          /*C_PkgErr.pRegMsg(1700,
                           Localize('%0=> "���������"',
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
      exit when iNext > iMax; -- ��� ������ ���������
    end loop;

    return(false);
  end;


begin
  -- Initialization
  null;
end col_C_pkgString;
/

