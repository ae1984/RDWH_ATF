create or replace force view dwh_buffer.v_xls_h_nbrk_rate as
select
  to_date(t.dt,'yyyy-mm-dd') as dt
  , to_number(aud      )/to_number(aud_quant)   aud
  , to_number(gbp      )/to_number(gbp_quant)   gbp
  , to_number(dkk      )/to_number(dkk_quant)   dkk
  , to_number(aed      )/to_number(aed_quant)   aed
  , to_number(usd      )/to_number(usd_quant)   usd
  , to_number(eur      )/to_number(eur_quant)   eur
  , to_number(cad      )/to_number(cad_quant)   cad
  , to_number(cny      )/to_number(cny_quant)   cny
  , to_number(kwd      )/to_number(kwd_quant)   kwd
  , to_number(kgs      )/to_number(kgs_quant)   kgs
  , to_number(mdl      )/to_number(mdl_quant)   mdl
  , to_number(nok      )/to_number(nok_quant)   nok
  , to_number(sar      )/to_number(sar_quant)   sar
  , to_number(rub      )/to_number(rub_quant)   rub
  , to_number(xdr      )/to_number(xdr_quant)   xdr
  , to_number(sgd      )/to_number(sgd_quant)   sgd
  , to_number(uzs      )/to_number(uzs_quant)   uzs
  , to_number(uah      )/to_number(uah_quant)   uah
  , to_number(sek      )/to_number(sek_quant)   sek
  , to_number(chf      )/to_number(chf_quant)   chf
  , to_number(krw      )/to_number(krw_quant)   krw
  , to_number(jpy      )/to_number(jpy_quant)   jpy
  , to_number(byr      )/to_number(byr_quant)   byr
  , to_number(pln      )/to_number(pln_quant)   pln
  , to_number(zar      )/to_number(zar_quant)   zar
  , to_number(try      )/to_number(try_quant)   try
  , to_number(huf      )/to_number(huf_quant)   huf
  , to_number(czk      )/to_number(czk_quant)   czk
  , to_number(tjs      )/to_number(tjs_quant)   tjs
  , to_number(hkd      )/to_number(hkd_quant)   hkd
  , to_number(brl      )/to_number(brl_quant)   brl
  , to_number(myr      )/to_number(myr_quant)   myr
  , to_number(azn      )/to_number(azn_quant)   azn
  , to_number(inr      )/to_number(inr_quant)   inr
  , to_number(thb      )/to_number(thb_quant)   thb
  , to_number(amd      )/to_number(amd_quant)   amd
  , to_number(gel      )/to_number(gel_quant)   gel
  , to_number(irr      )/to_number(irr_quant)   irr
  , to_number(mxn      )/to_number(mxn_quant)   mxn
from XLS_H_NBRK_RATE t;
grant select on DWH_BUFFER.V_XLS_H_NBRK_RATE to AIBEK_BE;
grant select on DWH_BUFFER.V_XLS_H_NBRK_RATE to DWH_PRIM;
grant select on DWH_BUFFER.V_XLS_H_NBRK_RATE to DWH_RISK;
grant select on DWH_BUFFER.V_XLS_H_NBRK_RATE to DWH_SALES;
grant select on DWH_BUFFER.V_XLS_H_NBRK_RATE to HEAD_DENIS_PL;
grant select on DWH_BUFFER.V_XLS_H_NBRK_RATE to HEAD_EVGENIY_PI;
grant select on DWH_BUFFER.V_XLS_H_NBRK_RATE to KRISTINA_KO;
grant select on DWH_BUFFER.V_XLS_H_NBRK_RATE to PROCESS_RISK;
grant select on DWH_BUFFER.V_XLS_H_NBRK_RATE to PROCESS_SALES;


