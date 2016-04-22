create or replace function dwh_buffer.col_fRsPeriod(nDepId in int, nId in int, sArea in varchar2, iCode in int default 0)
    return varchar2 as
    cRet varchar2(30);
  begin
    select replace(decode(iCode, 0,G.code,g.longname), sArea || '.', '')
      into cRet
      from col_G_CONSRC co, col_G_CONMEM e, col_G_CON g
     where E.ID_OBJ = CO.ID_OBJ
       and E.CON_ID = CO.CON_ID
       and co.con_id = g.id
       and g.id_hi is not null
       and g.groupfl = 0
       and CODE like sArea || '%'
       and e.id_1 = nDepId
       and e.id_2 = nId;
    return cRet;
  exception
    when others then
      return null;
  end;
/

