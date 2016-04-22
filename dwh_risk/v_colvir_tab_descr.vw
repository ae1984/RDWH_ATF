create or replace force view dwh_risk.v_colvir_tab_descr as
select "OWNER","TABLE_NAME","TABLE_TYPE","COMMENTS" from all_tab_comments@REPS t
where t.owner = 'COLVIR';

