create or replace package dwh_buffer.col_T_PkgDeaPrm is

  -- Author  : ALEXEY-YE
  -- Created : 28.10.2015 10:21:54
  -- Purpose : 
  /*  ѕолучение значени€ параметра сделки */
  function fPar (idDea in int, depDea in int, idPar in int) return varchar2;
    
  function fParByCode (idDea in int, depDea in int, par_code in varchar2) return varchar2;
  
  /*  ѕолучение значени€ параметра договора, если не находит, то в шаблон не смотрит */
  function fDeaParByCode (idDea in int, depDea in int, par_code in varchar2) return varchar2;
  function fDeaParByCode (rDea in col_GL_ANL.rAnlKey, par_code in varchar2) return varchar2;
 
 /*  ѕолучение значени€ параметра продукта */
  function fClsPar(idDcl in integer, idPar in integer, sDefValue in varchar2 default null) return varchar2;  
end col_T_PkgDeaPrm;
/

