create or replace package body dwh_buffer.col_t_bspcn is

FUNCTION FSPEC(IDPCN IN INTEGER) RETURN INTEGER AS
ISPECFL PLS_INTEGER;
BEGIN
SELECT SPECFL INTO ISPECFL FROM col_T_PCN WHERE ID=IDPCN;
RETURN ISPECFL;
END;

begin
  -- Initialization
  null;
end col_t_bspcn;
/

