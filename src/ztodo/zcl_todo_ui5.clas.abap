CLASS zcl_todo_ui5 DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    INTERFACES z2ui5_if_app.

    DATA mv_title       TYPE string.
    DATA mv_description TYPE string.
    DATA mt_todo        TYPE zui5_t_todo.
    DATA ms_todo_edit   TYPE zui5_s_todo.

ENDCLASS.


CLASS zcl_todo_ui5 IMPLEMENTATION.
  METHOD z2ui5_if_app~main.
    IF client->check_on_init( ).

      mt_todo = NEW zcl_todo_service( )->get_todo( ).

    ENDIF.

    TRY.

        DATA(lo_view) = z2ui5_cl_xml_view=>factory( ).

        " . Title of the App
        lo_view->_z2ui5( )->title( title = 'TODO Application' ).

        DATA(lo_page) = lo_view->shell( )->page( title          = 'TODO App'
                                                 titlealignment = 'Center' ).

        " . custom CSS
        lo_page->_generic( ns   = 'html'
                           name = 'style' )->_cc_plain_xml(
                                      'li[data-todo-item-completed="true"] span { text-decoration: line-through; }' ).

        DATA(lo_panel) = lo_page->VBox( direction      = 'Column'
                                        justifycontent = 'Start'
                                        alignitems     = 'Center'
                                        height         = '100%'
                                        width          = '100%'
                              )->panel( width = '500px'
                                        class = 'sapUiTinyMarginTop' ).

        DATA(lo_vbox_top) = lo_panel->VBox( justifycontent = 'SpaceBetween' ).

        lo_vbox_top->label( text     = 'Title'
                            labelfor = 'title' )->input( id    = 'title'
                                                         value = client->_bind_edit( mv_title )
                                                         width = '100%' ).

        lo_vbox_top->label( text  = 'Description'
                            class = 'sapUiTinyMarginTop' )->text_area( value = client->_bind_edit( mv_description )
                                                                       width = '100%'
                                                                       )->button(
                                                                           text  = 'Create TODO'
                                                                           type  = 'Emphasized'
                                                                           press = client->_event( 'NEW_TODO' ) ).

        DATA(lo_list_item) = lo_panel->list( id         = 'lstTODO'
                                             mode       = 'None'
                                             headertext = 'TODOs'
                                             items      = client->_bind_edit( mt_todo )

                      )->custom_list_item( ).

        DATA(lo_item_hbox) = lo_list_item->hbox( class          = 'sapUiTinyMarginBegin sapUiTinyMarginTopBottom'
                                                 justifycontent = 'SpaceBetween' ).

        " . Check box for setting TODO item DONE or not!
        lo_item_hbox->checkbox( text     = 'Done'
                                selected = '{DONE}'
                                select   = client->_event( val   = 'DONE'
                                                           t_arg = VALUE #( ( `${ID}` ) ) ) ).

        DATA(lo_item_vbox) = lo_item_hbox->vbox( class = 'sapUiSmallMarginBegin'
                                                 width = '90%' ).

        lo_item_vbox->title( '{TITLE}' ).
        lo_item_vbox->text( '{DESCRIPTION}' ).

        lo_item_hbox->button( icon    = 'sap-icon://edit'
                              tooltip = 'edit todo!'
                              type    = 'Transparent'
                              press   = client->_event( val   = 'EDIT'
                                                        t_arg = VALUE #( ( `${ID}` ) ) ) ).

        lo_item_hbox->button( icon    = 'sap-icon://delete'
                              tooltip = 'delte todo!'
                              type    = 'Transparent'
                              press   = client->_event( val   = 'DELETE'
                                                        t_arg = VALUE #( ( `${ID}` ) ) ) ).

        lo_list_item->custom_data( )->core_custom_data( key        = 'todo-item-completed'
                                                        value      = `{= String(${DONE})}`
                                                        writetodom = 'true' ).

        client->view_display( lo_view->stringify( ) ).

        CASE client->get( )-event.
          WHEN 'NEW_TODO'.

            DATA(lo_srv) = NEW zcl_todo_service( ).

            lo_srv->new_todo( iv_title       = mv_title
                              iv_description = mv_description ).

            client->message_toast_display( |TODO: { mv_title } created!| ).

            CLEAR: mv_title,
                   mv_description,
                   mt_todo.

            mt_todo = lo_srv->get_todo( ).

          WHEN 'DELETE'.

            DATA(lv_arg) = client->get_event_arg( ).

            lo_srv = NEW zcl_todo_service( ).

            lo_srv->delete_todo( iv_id = CONV #( lv_arg ) ).

            CLEAR mt_todo.

            mt_todo = lo_srv->get_todo( ).

            client->message_toast_display( |TODO with id { lv_arg } deleted!| ).

          WHEN 'DONE'.

            lv_arg = client->get_event_arg( ).

            lo_srv = NEW zcl_todo_service( ).

            DATA(ls_todo) = mt_todo[ id = CONV #( lv_arg ) ].

            lo_srv->update_todo( ls_todo ).

            " . Refresh data sorting so completed TODOs are shown at the bottom
            CLEAR mt_todo.

            mt_todo = lo_srv->get_todo( ).

            client->message_toast_display( |TODO with id { lv_arg } set to done!| ).
          WHEN 'EDIT'.

            lv_arg = client->get_event_arg( ).

            lo_srv = NEW zcl_todo_service( ).

            DATA(lt_todo_popup) = lo_srv->get_todo( iv_id = CONV #( lv_arg ) ).

            ms_todo_edit = lt_todo_popup[ 1 ].

            DATA(lo_popup) = z2ui5_cl_xml_view=>factory_popup(
              )->dialog( 'Edit TODO'
                  )->vbox( class = 'sapUiSmallMarginBeginEnd sapUiSmallMarginTopBottom' ).

            lo_popup->label( 'Title' )->input( value = client->_bind_edit( ms_todo_edit-title ) ).
            lo_popup->label( text  = 'Description'
                             class = 'sapUiTinyMarginTop' )->text_area(
                                                              value = client->_bind_edit( ms_todo_edit-description )
                                                              width = '100%' ).

            DATA(lo_hbox_popup) = lo_popup->hbox( justifycontent = 'SpaceBetween' ).

            lo_hbox_popup->button( text  = 'Cancel'
                                   press = client->_event( 'POPUP_CANCEL' ) ).

            lo_hbox_popup->button( text  = 'Save'
                                   type  = 'Emphasized'
                                   press = client->_event( val = 'POPUP_SAVE' ) ).

            client->popup_display( lo_popup->stringify( ) ).

          WHEN 'POPUP_SAVE'.

            lo_srv = NEW zcl_todo_service( ).

            lo_srv->update_todo( ms_todo_edit ).

            mt_todo = lo_srv->get_todo( ).

            client->popup_destroy( ).

          WHEN 'POPUP_CANCEL'.

            CLEAR ms_todo_edit.

            client->popup_destroy( ).

        ENDCASE.

      CATCH cx_root INTO DATA(lo_ex).
        client->message_box_display( lo_ex ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
