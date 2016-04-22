CREATE OR REPLACE FUNCTION DWH_BUFFER.FN_WHO_AM_I ( p_lvl  NUMBER DEFAULT 0) RETURN VARCHAR2
IS
/***********************************************************************************************
FN_WHO_AM_I returns the full ORACLE name of your object including schema and package names
--
FN_WHO_AM_I(0) - returns the name of your object
FN_WHO_AM_I(1) - returns the name of calling object
FN_WHO_AM_I(2) - returns the name of object, who called calling object
etc., etc., etc.... Up to to he highest level
-------------------------------------------------------------------------------------------------
Copyrigth GARBUYA 2010
*************************************************************************************************/
TYPE str_varr_t   IS VARRAY(2) OF CHAR(1);
TYPE str_table_t  IS TABLE OF VARCHAR2(256);
TYPE num_table_t  IS TABLE OF NUMBER;
v_stack           VARCHAR2(2048) DEFAULT UPPER(dbms_utility.format_call_stack);
v_tmp_1           VARCHAR2(1024);
v_tmp_2           VARCHAR2(1024);
v_pkg_name        VARCHAR2(32);
v_obj_type        VARCHAR2(32);
v_owner           VARCHAR2(32);
v_idx             NUMBER := 0;
v_pos1            NUMBER := 0;
v_pos2            NUMBER := 0;
v_line_nbr        NUMBER := 0;
v_blk_cnt         NUMBER := 0;
v_str_len         NUMBER := 0;
v_bgn_cnt         NUMBER := 0;
v_end_cnt         NUMBER := 0;
it_is_comment     BOOLEAN := FALSE;
it_is_literal     BOOLEAN := FALSE;
v_literal_arr     str_varr_t := str_varr_t ('''', '"');
v_blk_bgn_tbl     str_table_t := str_table_t (' IF '   , ' LOOP '   , ' CASE ', ' BEGIN ');
v_tbl             str_table_t := str_table_t();
v_blk_bgn_len_tbl num_table_t := num_table_t();


BEGIN

   v_stack := SUBSTR(v_stack,INSTR(v_stack,CHR(10),INSTR(v_stack,'FN_WHO_AM_I'))+1)||'ORACLE'; -- skip myself

   FOR v_pos2 in 1 .. p_lvl LOOP  -- advance to the input level
      v_pos1 := INSTR(v_stack, CHR(10));
      v_stack := SUBSTR(v_stack, INSTR(v_stack, CHR(10)) + 1);
   END LOOP;

   v_pos1 := INSTR(v_stack, CHR(10));
   IF v_pos1 = 0 THEN
      RETURN (v_stack);
   END IF;

   v_stack := SUBSTR(v_stack, 1, v_pos1 - 1);  -- get only current level
   v_stack := TRIM(SUBSTR(v_stack, instr(v_stack, ' ')));  -- cut object handle
   v_line_nbr := TO_NUMBER(SUBSTR(v_stack, 1, instr(v_stack, ' ') - 1));  -- get line number
   v_stack := TRIM(SUBSTR(v_stack, instr(v_stack, ' ')));  -- cut line number
   v_pos1 := INSTR(v_stack, ' BODY');
   IF v_pos1  = 0 THEN
      RETURN (v_stack);
   END IF;

   v_pos1 := INSTR(v_stack, ' ', v_pos1 + 2);  -- find end of object type
   v_obj_type := SUBSTR(v_stack, 1, v_pos1 - 1);  -- get object type
   v_stack := TRIM(SUBSTR(v_stack, v_pos1 + 1));  -- get package name
   v_pos1 := INSTR(v_stack, '.');
   v_owner := SUBSTR(v_stack, 1, v_pos1 - 1);  -- get owner
   v_pkg_name  := SUBSTR(v_stack, v_pos1 + 1);  -- get package name
   v_blk_cnt := 0;
   it_is_literal := FALSE;
   --
   FOR v_idx in v_blk_bgn_tbl.FIRST .. v_blk_bgn_tbl.LAST
   LOOP
      v_blk_bgn_len_tbl.EXTEND(1);
      v_blk_bgn_len_tbl (v_blk_bgn_len_tbl.last) := LENGTH(v_blk_bgn_tbl(v_idx));
   END LOOP;
   --
   FOR src
   IN ( SELECT ' '||REPLACE(TRANSLATE(UPPER(text), ';('||CHR(10), '   '),'''''',' ') ||' ' text
        FROM all_source
        where owner = v_owner
        and name    = v_pkg_name
        and type    = v_obj_type
        and line    < v_line_nbr
        ORDER  BY line
      )
   LOOP
      v_stack := src.text;
      IF it_is_comment THEN
         v_pos1 :=  INSTR (v_stack, '*/');
         IF v_pos1 > 0 THEN
            v_stack := SUBSTR (v_stack, v_pos1 + 2);
            it_is_comment := FALSE;
         ELSE
            v_stack := ' ';
         END IF;
      END IF;
      --
      IF v_stack != ' ' THEN
      --
         v_pos1 := INSTR (v_stack, '/*');
         WHILE v_pos1 > 0 LOOP
            v_tmp_1 := SUBSTR (v_stack, 1, v_pos1 - 1);
            v_pos2 := INSTR (v_stack, '*/');
            IF v_pos2 > 0 THEN
               v_tmp_2 := SUBSTR (v_stack, v_pos2 + 2);
               v_stack := v_tmp_1||v_tmp_2;
            ELSE
               v_stack := v_tmp_1;
               it_is_comment := TRUE;
            END IF;
            v_pos1 := INSTR (v_stack, '/*');
         END LOOP;
         --
         IF v_stack != ' ' THEN
            v_pos1 := INSTR (v_stack, '--');
            IF v_pos1 > 0 THEN
               v_stack := SUBSTR (v_stack, 1, v_pos1 - 1);
            END IF;
            --
            IF v_stack != ' ' THEN
               FOR v_idx in v_literal_arr.FIRST .. v_literal_arr.LAST
               LOOP
                  v_pos1 := INSTR (v_stack, v_literal_arr (v_idx) );
                  WHILE v_pos1 > 0  LOOP
                     v_pos2 := INSTR (v_stack, v_literal_arr (v_idx), v_pos1 + 1);
                     IF v_pos2 > 0 THEN
                        v_tmp_1 := SUBSTR (v_stack, 1, v_pos1 - 1);
                        v_tmp_2 := SUBSTR (v_stack, v_pos2 + 1);
                        v_stack := v_tmp_1||v_tmp_2;
                     ELSE
                        IF it_is_literal THEN
                           v_stack := SUBSTR (v_stack, v_pos1 + 1);
                           it_is_literal := FALSE;
                        ELSE
                           v_stack := SUBSTR (v_stack, 1, v_pos1 - 1);
                           it_is_literal := TRUE;
                        END IF;
                     END IF;
                     v_pos1 := INSTR (v_stack, v_literal_arr (v_idx) );
                  END LOOP;
               END LOOP;
               --
               IF v_stack != ' ' THEN
                  WHILE INSTR (v_stack, '  ') > 0
                  LOOP
                     v_stack := REPLACE(v_stack, '  ', ' ');
                  END LOOP;
                  v_stack := REPLACE(v_stack, ' END IF ', ' END ');
                  v_stack := REPLACE(v_stack, ' END LOOP ', ' END ');
                  --
                  IF v_stack != ' ' THEN
                     v_stack := ' '||v_stack;
                     v_pos1 := INSTR(v_stack, ' FUNCTION ') + INSTR(v_stack, ' PROCEDURE ');
                     IF v_pos1 > 0 THEN
                        v_obj_type := TRIM(SUBSTR(v_stack, v_pos1 + 1, 9));  -- get object type
                        v_stack := TRIM(SUBSTR(v_stack, v_pos1 + 10))||'  ';  -- cut object type
                        v_stack := SUBSTR(v_stack, 1,  INSTR(v_stack, ' ') - 1 );  -- get object name
                        v_tbl.EXTEND(1);
                        v_tbl (v_tbl.last) := v_obj_type||' '||v_owner||'.'||v_pkg_name||'.'||v_stack;
                     END IF;
                  --
                     v_pos1 := 0;
                     v_pos2 := 0;
                     v_tmp_1 := v_stack;
                     v_tmp_2 := v_stack;
                     FOR v_idx in v_blk_bgn_tbl.FIRST .. v_blk_bgn_tbl.LAST
                     LOOP
                        v_str_len := NVL(LENGTH(v_tmp_1),0);
                        v_tmp_1 := REPLACE(v_tmp_1,v_blk_bgn_tbl(v_idx), NULL);
                        v_bgn_cnt := NVL(LENGTH(v_tmp_1), 0);
                        v_pos1 := v_pos1 + (v_str_len - v_bgn_cnt)/v_blk_bgn_len_tbl(v_idx);
                        v_str_len := NVL(LENGTH(v_tmp_2),0);
                        v_tmp_2 := REPLACE(v_tmp_2,' END ', NULL);
                        v_end_cnt := NVL(LENGTH(v_tmp_2), 0);
                        v_pos2 := v_pos2 + (v_str_len - v_end_cnt)/5; --- 5 is the length(' END ')
                     END LOOP;
                     IF v_pos1 > v_pos2 THEN
                        v_blk_cnt := v_blk_cnt + 1;
                     ELSIF v_pos1 < v_pos2 THEN
                        v_blk_cnt := v_blk_cnt - 1;
                        IF v_blk_cnt = 0 AND v_tbl.COUNT > 0 THEN
                           v_tbl.DELETE(v_tbl.last);
                        END IF;
                     END IF;
                  END IF;
               END IF;
            END IF;
         END IF;
      END IF;
   END LOOP;

   RETURN CASE v_tbl.COUNT WHEN 0 THEN 'UNKNOWN' ELSE v_tbl(v_tbl.LAST) END;

END;
/

