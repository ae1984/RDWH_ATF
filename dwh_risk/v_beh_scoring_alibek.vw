create or replace force view dwh_risk.v_beh_scoring_alibek as
select t."ID_COLVIR",t."CONTRACT_NUM",t.good_bad,t."TRANS_DIR_TYPE",t."POSTING_DATE",t."TARGET_NUMBER",t."OWS_CLIENT_ID",t."SETTL_AMOUNT",t."SETTL_CURR",t."SETTL_CURR_C",t."SOURCE_CHANNEL",t."SOURCE_NUMBER",t."TARGET_CHANNEL",t.trans_amount1,t."TRANS_CITY",t."TRANS_COUNTRY",t."TRANS_CURR",t."TRANS_CURR_C",t."TRANS_DATE",t."DIR",t."OP_TYPE_CODE",t."OP_TYPE_NAME",t."SERVICE_CLASS",t."SIC_MCC",t."AMND_DATE",t."ID_D",t."TRANS_DETAILS",t.M_trans_amount,t."S_AMOUNT",t."S_FEE_AMOUNT",t."T_AMOUNT",t."T_FEE_AMOUNT",
--t.id_colvir,t.contract_num,t.default_90,
case when upper(t.op_type_name) like upper('%Payment Salary%') then t.trans_amount1 else 0 end salary,
case when t.sic_mcc=5310 then t.trans_amount1 else 0 end cheap_shop,
case when t.sic_mcc in (5399,5331) then t.trans_amount1 else 0 end universal_cheap_shop,
case when (t.sic_mcc>=3000 and t.sic_mcc<=3299) or t.sic_mcc in (4511,4582) then t.trans_amount1 else 0 end avia,
case when (t.sic_mcc>=3501 and t.sic_mcc<=3799) or t.sic_mcc in (5309)  then t.trans_amount1 else 0 end hotels_airports,
case when t.sic_mcc in (4722,4411) then t.trans_amount1 else 0 end tour_agencies,
case when t.sic_mcc=4789 then t.trans_amount1 else 0 end transport,
case when t.sic_mcc=4812 then t.trans_amount1 else 0 end white_technic,
case when t.sic_mcc in (4816,5734) then t.trans_amount1 else 0 end computer_soft,
case when t.sic_mcc=4829 then t.trans_amount1 else 0 end send_money,
case when t.sic_mcc=4899 then t.trans_amount1 else 0 end tv,
case when t.sic_mcc=4900 then t.trans_amount1 else 0 end utilities,
case when (t.sic_mcc>=5013 and t.sic_mcc<=5199) or t.sic_mcc in (5300) then t.trans_amount1 else 0 end wholesale,
case when t.sic_mcc=5200 then t.trans_amount1 else 0 end  Homeware,
case when (t.sic_mcc>=5211 and t.sic_mcc<=5271)then t.trans_amount1 else 0 end  constructions,
case when  t.sic_mcc in (5411,5422,5441,5462,5499) then t.trans_amount1 else 0 end  food,
case when  t.sic_mcc in (5511,5521,5531,5532,5533,5541,5542,5561,5599,5571,7531,7538,7549 ) then t.trans_amount1 else 0 end  car,
case when  t.sic_mcc in (5611,5621,5631,5651,5661,5681,5691,5697) then t.trans_amount1 else 0 end clothes,
case when  t.sic_mcc in (5641,5651) then t.trans_amount1 else 0 end child_family_clothes,
case when  t.sic_mcc in (5655,5940,5941) then t.trans_amount1 else 0 end sport_clothes,
case when  t.sic_mcc in (5699,5681) then t.trans_amount1 else 0 end vip_clothes,
case when  t.sic_mcc in (5712,5713,5714,5718,5719,5722,5732) then t.trans_amount1 else 0 end furniture,
case when  t.sic_mcc in (5733, 5735) then t.trans_amount1 else 0 end music,
case when  t.sic_mcc in (5812,5814) then t.trans_amount1 else 0 end restaurant,
case when  t.sic_mcc in (5813) then t.trans_amount1 else 0 end disco,
case when  t.sic_mcc in (5912) then t.trans_amount1 else 0 end pharmacy,
case when  t.sic_mcc in (5921) then t.trans_amount1 else 0 end alcohol,
case when  t.sic_mcc in (5931) then t.trans_amount1 else 0 end second_hand,
case when  t.sic_mcc in (5932, 5944, 7631) then t.trans_amount1 else 0 end antiques_jewelry,
case when  t.sic_mcc in (5933) then t.trans_amount1 else 0 end  pawnshop,
case when  t.sic_mcc in (5943) then t.trans_amount1 else 0 end  school_goods,
case when  t.sic_mcc in (5945) then t.trans_amount1 else 0 end  toys,
case when  t.sic_mcc in (5946) then t.trans_amount1 else 0 end  photo,
case when  t.sic_mcc in (5964,5965,5966,5967,5968, 5969) then t.trans_amount1 else 0 end  web_shop,
case when  t.sic_mcc in (5973,8661) then t.trans_amount1 else 0 end  religion,
case when  t.sic_mcc in (6211) then t.trans_amount1 else 0 end  exchange_,
case when  t.sic_mcc in (6300) then t.trans_amount1 else 0 end  insurance,
case when  t.sic_mcc in (7311, 7333, 7338, 7349, 7372, 7392, 7393, 7395, 7399) then t.trans_amount1 else 0 end  outsource,
case when  t.sic_mcc in (7832,7841) then t.trans_amount1 else 0 end  cinema,
case when  t.sic_mcc in (7911,7922, 7929) then t.trans_amount1 else 0 end  theatre,
case when  t.sic_mcc in (7932,7933) then t.trans_amount1 else 0 end  bowling,
case when  t.sic_mcc in (7941) then t.trans_amount1 else 0 end  sport_club,
case when  t.sic_mcc in (7995) or upper(t.op_type_name) like upper('%unique%') then t.trans_amount1 else 0 end  casino,
case when  t.sic_mcc in (8011,8021,8031,8042,8049,8062,8071,8099) then t.trans_amount1 else 0 end  hospital,
case when  t.sic_mcc in (8211,8220,8241,8249) then t.trans_amount1 else 0 end  lawyer,
case when  t.sic_mcc in (8111,8299) then t.trans_amount1 else 0 end  school_college, /*aaoe*/
case when  t.sic_mcc in (8241, 8244, 8249) then t.trans_amount1 else 0 end  education,  /*naiiia?aciaaiea*/
case when  t.sic_mcc in (8398) then t.trans_amount1 else 0 end  charity,
case when  t.sic_mcc in (9222) then t.trans_amount1 else 0 end  fees,
case when  upper(t.op_type_name) like upper('%ATM%') then t.trans_amount1 else 0 end cash,
case when t.dir=-1 then t.trans_amount1 else 0 end outcome,
case when t.dir=1 then t.trans_amount1 else 0 end income,
case when t.dir=-1 and
  t.trans_date-trunc(t.trans_date)>5/24 and  t.trans_date-trunc(t.trans_date)<=11/24 then t.trans_amount1 else 0 end
   morning_outcome,
case when t.dir=-1 and
  t.trans_date-trunc(t.trans_date)>11/24 and  t.trans_date-trunc(t.trans_date)<=17/24 then t.trans_amount1 else 0 end afternoon_outcome,
case when t.dir=-1 and
  t.trans_date-trunc(t.trans_date)>17/24 and  t.trans_date-trunc(t.trans_date)<=23/24 then t.trans_amount1 else 0 end evening_outcome,
case when t.dir=-1 and
  (t.trans_date-trunc(t.trans_date)<=5/24 or  t.trans_date-trunc(t.trans_date)>23/24) then t.trans_amount1 else 0 end night_outcome,
case when  upper(t.op_type_name) like upper('%cash%') then t.trans_amount1 else 0 end kassa,
--case when t.dir=1 and not(upper(t.op_type_name) like upper('%Payment Salary%')) then t.trans_amount1 else 0 end cash_in_no_salary, /*Caeiiaioe?iaae Aieeaeia E.E.29.05.20152015*/
case when t.dir=1 and not(upper(t.op_type_name) like upper('%Payment Salary%')) then t.trans_amount else 0 end cash_in_no_salary,
case when (upper(t.op_type_name) like upper('%retail%')) then t.trans_amount1 else 0 end retail  ,
case when t.SETTL_CURR_C<>398 then t.trans_amount1 else 0 end foreign_cur,
case when upper(t.trans_country)<>'KAZ' and t.dir=-1 then t.trans_amount1 else 0 end foreign_cash_out,
--case when t.dir=1 and upper(t.op_type_name) like upper('%CH_PAYMENT%') then t.trans_amount1 else 0 end cash_in_no_salry/*Caeiiaioe?iaae Aieeaeia E.E.29.05.2015*/
case when t.dir=1 and upper(t.op_type_name) like upper('%CH_PAYMENT%') then t.trans_amount else 0 end cash_in_no_salry
from --TRANSACTION_3 t --where upper(t.op_type_name) like upper('%Payment Salary%')
trans_before_loan_alibek t
;

