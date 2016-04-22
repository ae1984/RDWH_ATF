create or replace package dwh_buffer.col_T_PkgPcnClc is

  -- Author  : ALEXEY-YE
  -- Created : 28.10.2015 11:46:43
  -- Purpose : 
-- ��������� �������� %-� ������ � ������ ������
function fPrcWithCapAndFloorRate(
        fPercent   in float
      , dfromdate in col_t_pcnhst.fromdate%type
      , fcaprate   in col_t_pcnhst.caprate%type
      , ffloorrate in col_t_pcnhst.floorrate%type
      , dcapdate   in col_t_pcnhst.capdate%type default null
      , dfloordate in col_t_pcnhst.floordate%type default null
) return float;
  

function GetPercentValueEx(
         iid         in col_t_pcnhst.id%type
       , inver       in col_t_pcnhst.nver%type
       , dfromdate   in col_t_pcnhst.fromdate%type
       , rUP         in col_C_PkgSbjUtl.rUsedProcess
       , fcaprate    out col_t_pcnhst.caprate%type
       , dcapdate    out col_t_pcnhst.capdate%type
       , ffloorrate  out col_t_pcnhst.floorrate%type
       , dfloordate  out col_t_pcnhst.floordate%type
) return float;
procedure GetPercentValueEx(
          iId      in col_t_pcn.id%type,
          dDate    in date default p_operday,
          rUP      in col_C_PkgSbjUtl.rUsedProcess,
          fPercent out float,
          fcaprate    out col_t_pcnhst.caprate%type,
          dcapdate    out col_t_pcnhst.capdate%type,
          ffloorrate  out col_t_pcnhst.floorrate%type,
          dfloordate  out col_t_pcnhst.floordate%type
);

--������ �������� ���������� ������
procedure GetPercentValue(
iid         in col_t_pcn.id%type,
ddate       in date default p_operday,
rUP         in col_C_PkgSbjUtl.rUsedProcess,
fPercent    out float
);

function GetPercentValue(
iid         in col_t_pcnhst.id%type,        --id ������
inver       in col_t_pcnhst.nver%type,      --����� ������
dfromdate   in col_t_pcnhst.fromdate%type,  --���� ������ �������� �������� ������
rUP         in col_C_PkgSbjUtl.rUsedProcess,--
nBaseSum    in number,                  --���� �������
isbj_id     in int                      --��� ���������� ����� �������
)return float;

procedure GetPercentValue(
iid         in col_t_pcn.id%type,
ddate       in date default p_operday,
rUP         in col_C_PkgSbjUtl.rUsedProcess,
nBaseSum    in number,
isbj_id     in int,                      --��� ���������� ����� �������
fPercent    out float
);

function GetPercentValue(
iid         in col_t_pcnhst.id%type,
inver       in col_t_pcnhst.nver%type,
dfromdate   in col_t_pcnhst.fromdate%type,
rUP         in col_C_PkgSbjUtl.rUsedProcess
)return float;

function GetPercentValue(
         iid         in col_t_pcnhst.id%type        --id ������
       , inver       in col_t_pcnhst.nver%type      --����� ������
       , dfromdate   in col_t_pcnhst.fromdate%type default p_operday  --���� ������ �������� �������� ������
)return float;


end col_T_PkgPcnClc;
/

