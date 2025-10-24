CLASS zcl_abap2ui5_utils DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS message_box_query IMPORTING iv_title        TYPE string        OPTIONAL
                                              iv_text         TYPE string
                                              iv_icon         TYPE string        OPTIONAL
                                              iv_type         TYPE string        OPTIONAL
                                              io_client       TYPE REF TO z2ui5_if_client
                                              it_action       TYPE zui5_t_action OPTIONAL
                                    RETURNING VALUE(ro_popup) TYPE REF TO z2ui5_cl_xml_view.
ENDCLASS.


CLASS zcl_abap2ui5_utils IMPLEMENTATION.
  METHOD message_box_query.
    ro_popup = z2ui5_cl_xml_view=>factory_popup( ).

    DATA(lo_dialog) = ro_popup->dialog( title = iv_title
                                        icon  = iv_icon
                                        state = iv_type ).

    lo_dialog->text( text  = iv_text
                     class = 'sapUiSmallMargin' ).

    LOOP AT it_action REFERENCE INTO DATA(lr_actions).

      lo_dialog->buttons(
                  )->button( icon  = lr_actions->icon
                             text  = lr_actions->name
                             press = io_client->_event( lr_actions->event )
                             type  = lr_actions->type ).

    ENDLOOP.
    IF sy-subrc <> 0.

      lo_dialog->buttons(
                   )->button( text  = 'OK'
                              press = io_client->_event_client( io_client->cs_event-popup_close )
                              type  = 'Default' ).

    ENDIF.
  ENDMETHOD.
ENDCLASS.
