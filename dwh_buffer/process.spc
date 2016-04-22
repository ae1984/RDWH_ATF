create or replace package dwh_buffer.PROCESS is

  -- Author  : ALEXEY-YE
  -- Created : 03.09.2015 15:52:55
  -- Purpose : 
  
  procedure table_refresh(src varchar2, dest varchar2);
  procedure get_colvir_t_bal(v_dt date);
  procedure colvir_synh;

  procedure colvir_synh_00;
  procedure colvir_synh_0;
  procedure colvir_synh_1;
  procedure colvir_synh_2;
  
end PROCESS;
/

