CLASS zcl_todo_service DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS get_todo IMPORTING iv_id          TYPE int8 OPTIONAL
                     RETURNING VALUE(rt_todo) TYPE zui5_t_todo.

    METHODS new_todo IMPORTING iv_title       TYPE string
                               iv_description TYPE string
                     RETURNING VALUE(rs_todo) TYPE zui5_s_todo
                     RAISING   zcx_todo.

    METHODS update_todo IMPORTING is_todo TYPE zui5_s_todo
                        RAISING   zcx_todo.

    METHODS delete_todo IMPORTING iv_id TYPE int8
                        RAISING   zcx_todo.

  PRIVATE SECTION.
    METHODS get_next_id   RETURNING VALUE(rv_id)        TYPE int8.
    METHODS get_timestamp RETURNING VALUE(rv_timestamp) TYPE timestampl.

ENDCLASS.


CLASS zcl_todo_service IMPLEMENTATION.
  METHOD get_todo.
    IF iv_id IS NOT INITIAL.

      SELECT * FROM ztodo
        INTO CORRESPONDING FIELDS OF TABLE rt_todo
        WHERE id = iv_id.

      IF sy-subrc <> 0.
        CLEAR rt_todo.
      ENDIF.

    ELSE.

      SELECT * FROM ztodo INTO CORRESPONDING FIELDS OF TABLE rt_todo.
      IF sy-subrc <> 0.

        CLEAR rt_todo.

      ENDIF.

    ENDIF.

    SORT rt_todo BY done
                    created_at ASCENDING. " . oldest TODOs are at the top
  ENDMETHOD.

  METHOD new_todo.
    DATA ls_todo TYPE ztodo.

    IF iv_title IS INITIAL.
      RAISE EXCEPTION TYPE zcx_todo MESSAGE e003.
    ENDIF.

    rs_todo = VALUE #( id          = get_next_id( )
                       title       = iv_title
                       description = iv_description
                       done        = abap_false
                       created_at  = get_timestamp( ) ).

    MOVE-CORRESPONDING rs_todo TO ls_todo.

    INSERT ztodo FROM ls_todo.

    IF sy-subrc <> 0.

      ROLLBACK WORK.

      CLEAR rs_todo.
      RAISE EXCEPTION TYPE zcx_todo MESSAGE e000.

    ENDIF.

    COMMIT WORK.
  ENDMETHOD.

  METHOD update_todo.
    DATA ls_todo TYPE ztodo.

    CHECK is_todo IS NOT INITIAL.

    MOVE-CORRESPONDING is_todo TO ls_todo.

    UPDATE ztodo FROM ls_todo.
    IF sy-subrc <> 0.

      ROLLBACK WORK.

      RAISE EXCEPTION TYPE zcx_todo MESSAGE e003 WITH is_todo-id.

    ENDIF.

    COMMIT WORK.
  ENDMETHOD.

  METHOD delete_todo.
    CHECK iv_id IS NOT INITIAL.

    DELETE FROM ztodo WHERE id = iv_id.
    IF sy-subrc <> 0.

      ROLLBACK WORK.

      RAISE EXCEPTION TYPE zcx_todo MESSAGE e002 WITH iv_id.

    ENDIF.

    COMMIT WORK.
  ENDMETHOD.

  METHOD get_next_id.
    SELECT MAX( id ) FROM ztodo INTO @DATA(lv_count).

    rv_id = lv_count + 1.
  ENDMETHOD.

  METHOD get_timestamp.
    GET TIME STAMP FIELD rv_timestamp.
  ENDMETHOD.
ENDCLASS.
