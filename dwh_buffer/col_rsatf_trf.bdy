create or replace package body dwh_buffer.col_rsatf_trf is
  type TTbl is record(
    area   varchar2(30),
    code   varchar2(30),
    CValue varchar2(250));
  type TTblLst is table of TTbl index by binary_integer;
  glValue TTblLst;
  
  function fGetGl(sArea in varchar2, sCode in varchar2) return varchar2 as
  begin
    for i in 1 .. glValue.count loop
      if glValue(i).area = sArea and glValue(i).code = sCode then
        return glValue(i) .CValue;
      end if;
    end loop;
    return null;
  exception
    when NO_DATA_FOUND then
      /*t_log.WRITEL(1,
                   '«начение дл€ атрибута ' || sArea || ':' || sCode ||
                   ' не может быть рассчитано');*/
      return null;
  end;


begin
  -- Initialization
  null;
end col_rsatf_trf;
/

