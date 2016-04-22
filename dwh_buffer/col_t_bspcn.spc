create or replace package dwh_buffer.col_t_bspcn is

  -- Author  : ALEXEY-YE
  -- Created : 28.10.2015 16:53:54
  -- Purpose : 
  NEWVERTYPE VARCHAR2(10) := 'NEW';
  ACTVERTYPE VARCHAR2(10) := 'ACT';
  
  FUNCTION FSPEC(IDPCN IN INTEGER) RETURN INTEGER;
  
end col_t_bspcn;
/

