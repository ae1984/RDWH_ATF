CREATE OR REPLACE PROCEDURE DWH_RISK.ClobTableInsert (p_Id NUMBER, p_Name VARCHAR2,
p_Value OUT CLOB)
is
begin
Insert into ClobTable (Id,Name,Value)
values(1, p_Name, EMPTY_CLOB())
RETURNING
Value
INTO
p_Value;
end;
/

