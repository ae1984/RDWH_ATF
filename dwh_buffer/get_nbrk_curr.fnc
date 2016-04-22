create or replace function dwh_buffer.Get_NBRK_Curr(p_date in date, p_curr_code in varchar2, p_val_id in number ) return number  is
  v_rate number;
begin
  if p_val_id <> 0 then begin
      if p_val_id = 1 then
        v_rate := 1;
      else begin
        select c.rate into v_rate from
          (select * from dwh_buffer.NBRK_CURRENCY_RATE t
           where t.dt<=p_date and (t.alph_code = upper(p_curr_code) or t.val_id = p_val_id)
           order by t.dt desc) c
        where rownum < 2;
      end;
      end if;
  end;
  else
  begin
      if upper(p_curr_code) in ('KZT','398','') then
        v_rate := 1;
      else begin
        select c.rate into v_rate from
          (select * from dwh_buffer.NBRK_CURRENCY_RATE t
           where t.dt<=p_date and (t.alph_code = upper(p_curr_code) or t.num_code = upper(p_curr_code))
           order by t.dt desc) c
        where rownum < 2;
      end;
      end if;
  end;
  end if;



  return(v_rate);
end Get_NBRK_Curr;
/

