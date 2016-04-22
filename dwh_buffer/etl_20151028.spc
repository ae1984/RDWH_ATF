create or replace package dwh_buffer.ETL_20151028

is
   procedure Colvir_import;
   procedure run_morning;
   procedure run_monthly;
   procedure ETL_NIGHT;
   procedure ImportToDWH_PRIM(p_tablename in varchar2);
   procedure FINISH_ETL_RUN;
   procedure Dash_Board_Update;
   procedure Fill_Payments_Schedulers;
   function  Get_NBRK_Curr(p_date in date, p_curr_code in varchar2, p_val_id in number ) return number;
   procedure FILL_CLIENT_ALL;
   procedure Fill_Trans_new;
   procedure Fill_W4_Contract;
   procedure Fill_PayRoll_List_New;

   
   procedure FILL_COL_T_DEAPRM;
   procedure FILL_COL_T_DEAPRMDSC_STD;
   procedure FILL_COL_L_DEA;
   procedure FILL_COL_T_DEA;
   procedure FILL_COL_T_ORD;
   procedure FILL_COL_T_VAL_STD;
   procedure FILL_COL_T_PROCMEM;
   procedure FILL_COL_T_PROCESS;
   procedure FILL_COL_T_BOP_STAT_STD;
   procedure FILL_COL_T_DEAPRD_std;
   procedure FILL_COL_T_DEACLS_std;
   procedure FILL_COL_c_dep;
   procedure FILL_COL_Q_DEA;
   procedure FILL_COL_Q_ACC;
   procedure FILL_COL_Q_ENTACC_STD;
   procedure FILL_COL_G_CLIADDATR;
   procedure FILL_COL_T_DEASHDPNT;
   procedure FILL_COL_T_DEAPAY;
   procedure FILL_T_BAL;

   
   
   procedure   imp2prim_dm_cif_addr;
   procedure   imp2prim_DM_DELAY_CURR;
   procedure   imp2prim_ows_contract;
   procedure   imp2prim_DICT_PHONE_TYPES;
   procedure   imp2prim_CLIENT_PHONES;
   procedure   imp2prim_DM_ACC_BASE;
   procedure   imp2prim_dm_dep_base;
   procedure   imp2prim_dm_loan_base;
   procedure   imp2prim_transaction_3;
   procedure   imp2prim_c_dep;
   procedure   imp2prim_client;
   procedure   imp2prim_dm_bal_snap;
   procedure   imp2prim_OWS_CLIENT_BUF;
   procedure   imp2prim_client_map;
   procedure   imp2prim_DM_CIF_BASE;
   procedure   imp2prim_IB_REGCLIENT_FL;
   procedure   imp2prim_calendar;
   procedure   imp2prim_DASH_BOARD;
   procedure   imp2prim_DM_LOAN_PAYM_3;

end ETL_20151028;
/

