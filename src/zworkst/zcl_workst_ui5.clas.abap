CLASS zcl_workst_ui5 DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF mst_f4_sel,
        selkz TYPE abap_bool,
        value TYPE string,
        descr TYPE string,
      END OF mst_f4_sel.
    TYPES mtt_f4_sel TYPE TABLE OF mst_f4_sel.

    TYPES:
      BEGIN OF mst_serial_entered,
        selkz  TYPE abap_bool,
        serial TYPE char30,
      END OF mst_serial_entered.

    DATA ms_data            TYPE zui5_s_workst_model.
    DATA mv_step            TYPE string VALUE 'SCREEN100' ##NO_TEXT.
    DATA mt_lgnum_sel       TYPE mtt_f4_sel.
    DATA mt_workst_sel      TYPE mtt_f4_sel.
    DATA mt_serials_entered TYPE TABLE OF mst_serial_entered.
    DATA mv_focus_id        TYPE string.
    DATA mv_show_message    TYPE abap_bool.
    DATA mv_message_text    TYPE string.
    DATA mv_message_type    TYPE string.

  PRIVATE SECTION.
    METHODS init.

    METHODS build_screen_100
      IMPORTING io_client        TYPE REF TO z2ui5_if_client
      RETURNING VALUE(ro_screen) TYPE REF TO z2ui5_cl_xml_view.

    METHODS build_screen_200
      IMPORTING io_client        TYPE REF TO z2ui5_if_client
      RETURNING VALUE(ro_screen) TYPE REF TO z2ui5_cl_xml_view.

    METHODS build_screen_300
      IMPORTING io_client       TYPE REF TO z2ui5_if_client
      RETURNING VALUE(ro_popup) TYPE REF TO z2ui5_cl_xml_view. " . serial number view as PopUp

    METHODS build_screen_yesno
      IMPORTING io_client       TYPE REF TO z2ui5_if_client
      RETURNING VALUE(ro_popup) TYPE REF TO z2ui5_cl_xml_view. " . Yes/No for finish delivery

    METHODS build_error_screen
      IMPORTING io_client        TYPE REF TO z2ui5_if_client
      RETURNING VALUE(ro_screen) TYPE REF TO z2ui5_cl_xml_view.

    METHODS hndl_event_100
      IMPORTING io_client TYPE REF TO z2ui5_if_client.

    METHODS hndl_event_200
      IMPORTING io_client TYPE REF TO z2ui5_if_client.

    METHODS hndl_event_300
      IMPORTING io_client TYPE REF TO z2ui5_if_client.

    METHODS f4_lgnum_popup
      IMPORTING io_client TYPE REF TO z2ui5_if_client.

    METHODS f4_workst_popup
      IMPORTING io_client TYPE REF TO z2ui5_if_client.

    METHODS change_lgnum.
    METHODS change_workst.
    METHODS validate_input_screen100 RETURNING VALUE(rv_okey) TYPE abap_bool.

    METHODS show_message_strip IMPORTING iv_text TYPE string
                                         iv_type TYPE string.

    METHODS compact_by_product CHANGING ct_item TYPE zui5_t_workst_item_overview.

    METHODS init_200.

ENDCLASS.


CLASS zcl_workst_ui5 IMPLEMENTATION.
  METHOD z2ui5_if_app~main.
    TRY.

        IF client->check_on_init( ).
          init( ).
        ENDIF.

        hndl_event_100( client ).

        hndl_event_200( client ).

        hndl_event_300( client ).

        IF mv_step = 'SCREEN100'.

          DATA(lo_screen) = build_screen_100( client ).

        ELSEIF mv_step = 'SCREEN200'.

          lo_screen = build_screen_200( client ).

        ELSEIF mv_step = 'SCREEN300'.

          lo_screen = build_screen_200( client ).
          DATA(lo_popup) = build_screen_300( client ).

        ELSEIF mv_step = 'FINDLV'.

          lo_screen = build_screen_200( client ).
          lo_popup = build_screen_yesno( client ).

        ELSE.

          lo_screen = build_error_screen( client ).

        ENDIF.

        client->view_display( lo_screen->stringify( ) ).

        IF lo_popup IS NOT INITIAL.
          client->popup_display( lo_popup->stringify( ) ).
        ENDIF.

      CATCH cx_root INTO DATA(lo_ex).
        client->message_box_display( lo_ex ).
    ENDTRY.
  ENDMETHOD.

  METHOD init.
    " . Not used for now, runs only once at the beginning
  ENDMETHOD.

  METHOD build_screen_100.
    ro_screen = z2ui5_cl_xml_view=>factory( ).

    ro_screen->_z2ui5( )->title( title = 'Workstation'(001) ).

    DATA(lo_page) = ro_screen->shell( )->page(
                        title          = 'Workstation'(001)
                        navbuttonpress = io_client->_event( 'BACK' )
                        shownavbutton  = xsdbool( io_client->get( )-s_draft-id_prev_app_stack IS NOT INITIAL ) ).

    DATA(lo_form) = lo_page->vbox( width          = '100%'
                                   height         = '100%'
                                   alignitems     = 'Center'
                                   justifycontent = 'Center' )->simple_form( title    = 'Login to Workstation'(002)
                                                                             width    = '400px'
                                                                             editable = abap_true )->content( 'form' ).

    " . set initial focus
    IF mv_focus_id IS INITIAL.
      mv_focus_id = 'idLgnum'.
    ENDIF.

    lo_form->_z2ui5( )->focus( focusid = io_client->_bind_edit( mv_focus_id ) ).

    lo_form->label( 'Warehouse Number'(003) ).
    lo_form->input( id               = 'idLgnum'
                    value            = io_client->_bind_edit( ms_data-lgnum )
                    valuestate       = ms_data-lgnum_valuestate
                    valuestatetext   = ms_data-lgnum_valuestatetext
                    placeholder      = 'e.g. 3000'
                    showclearicon    = abap_true
                    required         = abap_true
                    showvaluehelp    = abap_true
                    submit           = io_client->_event( 'CHANGE_LGNUM' )
                    valuehelprequest = io_client->_event( 'F4_LGNUM' ) ).
    lo_form->label( 'Workstation'(001) ).
    lo_form->input( id               = 'idWorkst'
                    value            = io_client->_bind_edit( ms_data-workstation )
                    valuestate       = ms_data-workst_valuestate
                    valuestatetext   = ms_data-workst_valuestatetext
                    placeholder      = 'e.g. WS01'
                    showclearicon    = abap_true
                    required         = abap_true
                    showvaluehelp    = abap_true
                    submit           = io_client->_event( 'CHANGE_WORKST' )
                    valuehelprequest = io_client->_event( 'F4_WORKST' ) ).
    lo_form->button( id    = 'idLogin'
                     text  = 'Login'(004)
                     type  = 'Emphasized'
                     width = '45%'
                     class = 'sapUiSmallMarginTop'
                     press = io_client->_event( 'GO_200' ) ).
  ENDMETHOD.

  METHOD build_screen_200.
    DATA lv_workst_text TYPE string.

    ro_screen = z2ui5_cl_xml_view=>factory( ).

    lv_workst_text = 'Workstation'(001).

    DATA(lo_page) = ro_screen->shell( )->page(
                        title          = |{ lv_workst_text } { ms_data-workstation } - { ms_data-workst_description }|
                        navbuttonpress = io_client->_event( 'GO_100' )
                        shownavbutton  = abap_true ).

    " . Set initial focus
    IF mv_focus_id IS INITIAL.
      mv_focus_id = 'idInpDlv'.
    ENDIF.

    lo_page->_z2ui5( )->focus( focusid = io_client->_bind_edit( mv_focus_id ) ).

    " ---------------------------------------------------------------------
    " . Delivery/HU Bar
    " ---------------------------------------------------------------------

    DATA(lo_top_bar) = lo_page->grid( default_span = 'XL12 L12 M12 S12'
                                      class        = 'sapUiTinyMarginTop'
                                      vspacing     = '0'  ).

    DATA(lo_tb_vbox1) = lo_top_bar->vbox( ).

    lo_tb_vbox1->layout_data( )->grid_data( span = 'XL4 L4 M4 S12' ).

    lo_tb_vbox1->label( text     = 'Delivery'(005)
                        labelfor = 'idInpDlv' )->input( id             = 'idInpDlv'
                                                        value          = io_client->_bind_edit( ms_data-input_dlv )
                                                        submit         = io_client->_event( 'SEL_DLV' )
                                                        valuestate     = ms_data-input_dlv_valuestate
                                                        valuestatetext = ms_data-input_dlv_valuestatetext
                                                        placeholder    = 'e.g. 0815'
                                                        showclearicon  = abap_true  ).

    DATA(lo_tb_vbox2) = lo_top_bar->vbox( ).

    lo_tb_vbox2->layout_data( )->grid_data( span = 'XL4 L4 M4 S12' ).

    lo_tb_vbox2->label( text     = 'HU'
                        labelfor = 'idInpHU' )->input( id             = 'idInpHU'
                                                       value          = io_client->_bind_edit( ms_data-input_hu )
                                                       submit         = io_client->_event( 'SEL_DLV' )
                                                       valuestate     = ms_data-input_hu_valuestate
                                                       valuestatetext = ms_data-input_hu_valuestatetext
                                                       placeholder    = 'e.g. 5000001'
                                                       showclearicon  = abap_true  ).

    DATA(lo_tb_fb) = lo_top_bar->flex_box( alignitems     = 'End'
                                           justifycontent = 'Start'
                                           height         = '50px' ). " . How to do this?

    lo_tb_fb->button( text  = 'Start DLV'
                      type  = 'Emphasized'
                      width = '90%'
                      press = io_client->_event( 'SEL_DLV' ) ).

    lo_tb_fb->get_child( 1 )->layout_data( )->flex_item_data( growfactor = '1' ).

    lo_tb_fb->button( text  = 'Finish DLV'
                      type  = 'Emphasized'
                      width = '90%'
                      press = io_client->_event( 'FIN_DLV' ) ).

    lo_tb_fb->get_child( 2 )->layout_data( )->flex_item_data( growfactor = '1' ).

    lo_tb_fb->layout_data( )->grid_data( span = 'XL4 L4 M4 S12' ).

    DATA(lo_grid) = lo_page->grid( default_span = 'XL6 L6 M6 S12'
                                   class        = 'sapUiTinyMarginTop' ).

    " ---------------------------------------------------------------------
    " . Items to Pick
    " ---------------------------------------------------------------------
    DATA(lo_panel_pick_items_dlv) = lo_grid->panel( headertext   = 'Picking Items'
                                                    height       = '300px'
                                                    stickyheader = abap_true ).

    DATA(lo_pick_item_table) = lo_panel_pick_items_dlv->scroll_container( width      = '100%'
                                                                          height     = '85%'
                                                                          vertical   = abap_true
                                                                          horizontal = abap_true

             )->table( items              = io_client->_bind_edit( ms_data-t_pick_hu_item )
                       sticky             = 'ColumnHeaders'
                       showseparators     = 'All'
                       alternaterowcolors = abap_true
                       mode               = 'MultiSelect' ).
    lo_pick_item_table->columns(
        )->column( )->text( 'Product' )->get_parent(
        )->column( )->text( 'Description' )->get_parent(
        )->column( )->text( 'Quantity' )->get_parent(
        )->column( )->text( 'Unit' ).
    lo_pick_item_table->items( )->column_list_item( selected = '{SELECTED}' )->cells(
            )->text( '{PRODUCTNO}'
            )->text( '{PRODUCTDESCR}'
            )->text( '{QUANTITY}'
            )->text( '{UNIT}' ).

    DATA(lo_toolbar) = lo_panel_pick_items_dlv->overflow_toolbar( style  = 'Clear'
                                                                  design = 'Transparent' ).

    lo_toolbar->toolbar_spacer( ).
    lo_toolbar->button( text    = '>>>'
                        tooltip = 'Move all items to shipping HU'
                        press   = io_client->_event( 'MOVE_PICK_ALL' ) ).
    lo_toolbar->toolbar_spacer( ).
    lo_toolbar->button( text    = '>>'
                        tooltip = 'Move selected items to shipping HU'
                        press   = io_client->_event( 'MOVE_PICK_SEL' ) ).
    lo_toolbar->toolbar_spacer( ).
    lo_toolbar->button( text    = '>'
                        tooltip = 'Pick with quantity adjustment'
                        press   = io_client->_event( 'PICK_SINGLE' ) ).
    lo_toolbar->toolbar_spacer( ).

    " ---------------------------------------------------------------------
    " . Shipping HU items
    " ---------------------------------------------------------------------
    DATA(lo_panel_ship_hu_dlv) = lo_grid->panel( height       = '300px'
                                                 stickyheader = abap_true ).

    DATA(lo_header_toolbar) = lo_panel_ship_hu_dlv->header_toolbar( )->overflow_toolbar( ).

    lo_header_toolbar->title( 'Shipping HU' ).
    lo_header_toolbar->toolbar_spacer( ).
    lo_header_toolbar->input( value   = io_client->_bind_edit( ms_data-ship_huident )
                              enabled = abap_false
                              width   = '100px' ).
    lo_header_toolbar->button( text  = 'Create HU'
                               press = io_client->_event( 'CREATE_SHIP_HU' ) ).
    lo_header_toolbar->button( text  = 'Close HU'
                               press = io_client->_event( 'CLOSE_SHIP_HU' ) ).

    DATA(lo_ship_item_table) = lo_panel_ship_hu_dlv->scroll_container( width      = '100%'
                                                                       height     = '85%'
                                                                       vertical   = abap_true
                                                                       horizontal = abap_true

             )->table( items              = io_client->_bind_edit( ms_data-t_ship_hu_item )
                       sticky             = 'ColumnHeaders'
                       showseparators     = 'All'
                       alternaterowcolors = abap_true
                       mode               = 'MultiSelect'  ).

    lo_ship_item_table->columns(
        )->column( )->text( 'Product' )->get_parent(
        )->column( )->text( 'Description' )->get_parent(
        )->column( )->text( 'Quantity' )->get_parent(
        )->column( )->text( 'Unit' ).
    lo_ship_item_table->items( )->column_list_item( selected = '{SELECTED}' )->cells(
            )->text( '{PRODUCTNO}'
            )->text( '{PRODUCTDESCR}'
            )->text( '{QUANTITY}'
            )->text( '{UNIT}' ).

    lo_toolbar = lo_panel_ship_hu_dlv->overflow_toolbar( style  = 'Clear'
                                                         design = 'Transparent' ).

    lo_toolbar->toolbar_spacer( ).
    lo_toolbar->button( text    = '<<'
                        tooltip = 'Move selected items back to Picking HU'
                        press   = io_client->_event( 'MOVE_SHIP_SEL' )  ).
    lo_toolbar->toolbar_spacer( ).
    lo_toolbar->button( text    = '<<<'
                        tooltip = 'Empty Shipping HU'
                        press   = io_client->_event( 'MOVE_SHIP_ALL' ) ).
    lo_toolbar->toolbar_spacer( ).

    " ---------------------------------------------------------------------
    " . All Picking HUs of the delivery
    " ---------------------------------------------------------------------
    DATA(lo_panel_pick_hu_all_dlv) = lo_grid->panel( headertext   = 'All Picking HUs'
                                                     height       = '250px'
                                                     stickyheader = abap_true ).

    DATA(lo_pick_hu_table) = lo_panel_pick_hu_all_dlv->scroll_container( width      = '100%'
                                                                         height     = '95%'
                                                                         vertical   = abap_true
                                                                         horizontal = abap_true

                 )->table( items              = io_client->_bind( ms_data-t_pick_hu_all )
                           sticky             = 'ColumnHeaders'
                           showseparators     = 'All'
                           alternaterowcolors = abap_true ).
    lo_pick_hu_table->columns(
        )->column( )->text( 'HU' )->get_parent(
        )->column( )->text( 'Storage Bin' ).
    lo_pick_hu_table->items( )->column_list_item( )->cells(
            )->text( '{HUIDENT}'
            )->text( '{LGPLA}' ).

    " ---------------------------------------------------------------------
    " . All Shipping HUs of the delivery
    " ---------------------------------------------------------------------
    DATA(lo_panel_ship_hu_all_dlv) = lo_grid->panel( headertext   = 'All Shipping HUs'
                                                     height       = '250px'
                                                     stickyheader = abap_true ).

    DATA(lo_ship_hu_table) = lo_panel_ship_hu_all_dlv->scroll_container( width      = '100%'
                                                                         height     = '95%'
                                                                         vertical   = abap_true
                                                                         horizontal = abap_true

                 )->table( items              = io_client->_bind( ms_data-t_ship_hu_all )
                           sticky             = 'ColumnHeaders'
                           showseparators     = 'All'
                           alternaterowcolors = abap_true ).
    lo_ship_hu_table->columns(
        )->column( )->text( 'HU' )->get_parent(
        )->column( )->text( 'Storage Bin' ).
    lo_ship_hu_table->items( )->column_list_item( )->cells(
            )->text( '{HUIDENT}'
            )->text( '{LGPLA}' ).

    " ---------------------------------------------------------------------
    " . Bottom Grid
    " ---------------------------------------------------------------------
    DATA(lo_bottom_bar) = lo_page->grid( default_span = 'XL12 L12 M12 S12'
                                         vspacing     = '0' ).

    DATA(lo_bb_vb1) = lo_bottom_bar->vbox( ).

    lo_bb_vb1->label( text     = 'Product'
                      class    = 'sapUiTinyMarginEnd'
                      labelfor = 'idInpProduct' )->input(
                                                    id             = 'idInpProduct'
                                                    value          = io_client->_bind_edit( ms_data-input_product )
                                                    valuestate     = ms_data-input_product_valuestate
                                                    valuestatetext = ms_data-input_product_valuestatetext
                                                    submit         = io_client->_event( 'PRODUCT_INPUT' )
                                                    showclearicon  = abap_true ).

    lo_bb_vb1->layout_data( )->grid_data( span = 'XL4 L4 M4 S12' ).

    DATA(lo_bb_vb2) = lo_bottom_bar->vbox( ).

    lo_bb_vb2->label( text     = 'Quantity'
                      labelfor = 'idInpQuantity' ).

    DATA(lo_bb_fb1) = lo_bb_vb2->flex_box( alignitems = 'Start' ).

    lo_bb_fb1->input( id             = 'idInpQuantity'
                      value          = io_client->_bind_edit( ms_data-input_qty )
                      valuestate     = ms_data-input_qty_valuestate
                      valuestatetext = ms_data-input_qty_valuestatetext
                      width          = '90%'
                      submit         = io_client->_event( 'PACK_QTY' )
                      showclearicon  = abap_true )->get_child( 1 )->layout_data( )->flex_item_data( growfactor = '3' ).

    lo_bb_fb1->input( id       = 'idInpUnit'
                      value    = io_client->_bind_edit( ms_data-unit_qty )
                      editable = abap_false
                      enabled  = abap_false
                      width    = '90%' )->get_child( 2 )->layout_data( )->flex_item_data( growfactor = '1' ).

    lo_bb_vb2->layout_data( )->grid_data( span = 'XL4 L4 M4 S12' ).

    DATA(lo_bb_fb) = lo_bottom_bar->flex_box( alignitems     = 'End'
                                              justifycontent = 'Center'
                                              height         = '50px' ). " . How to do this?

    lo_bb_fb->button( text  = 'Pack'
                      type  = 'Emphasized'
                      width = '90%'
                      press = io_client->_event( 'PACK_QTY' ) )->get_child( 1 )->layout_data( )->flex_item_data(
                                                                                  growfactor = '1' ).

    lo_bb_fb->layout_data( )->grid_data( span = 'XL4 L4 M4 S12' ).

    " ---------------------------------------------------------------------
    " . Show Message Strip
    " ---------------------------------------------------------------------
    IF mv_show_message = abap_true.

      lo_page->message_strip( text            = mv_message_text
                              type            = mv_message_type
                              showicon        = abap_true
                              showclosebutton = abap_true
                              class           = 'sapUiSmallMarginTop' ).

      " . set timer to close message strip after 5 seconds
      ro_screen->_z2ui5( )->timer( finished = io_client->_event( 'CLOSE_MESSAGE_STRIP' )
                                   delayms  = '5000' ).

    ENDIF.
  ENDMETHOD.

  METHOD build_screen_300.
    ro_popup = z2ui5_cl_xml_view=>factory_popup( ).

    DATA(lo_dialog) = ro_popup->dialog( title         = 'Enter Serial Numbers'
                                        contentwidth  = '450px'
                                        contentheight = '450px' ).

    DATA(lo_hbox) = lo_dialog->hbox( class = 'sapUiSmallMargin'
                                     width = '100%'  ).

    lo_hbox->input( placeholder    = 'Any serial number, e.g. 123456'
                    value          = io_client->_bind_edit( ms_data-input_serial )
                    valuestate     = ms_data-input_serial_valuestate
                    valuestatetext = ms_data-input_serial_valuestatetext
                    showclearicon  = abap_true
                    submit         = io_client->_event( 'SERIAL_ENTER' ) ).

    lo_hbox->button( text  = 'Enter'
                     type  = 'Emphasized'
                     press = io_client->_event( 'SERIAL_ENTER' )
                     class = 'sapUiSmallMarginBegin'
                     width = '70%' ).

    lo_hbox->get_child( 1 )->layout_data( )->flex_item_data( growfactor = '1' ).
    lo_hbox->get_child( 2 )->layout_data( )->flex_item_data( growfactor = '1' ).

    DATA(lo_table) = lo_dialog->vbox( class = 'sapUiSmallMarginBeginEnd' )->table(
        items              = io_client->_bind_edit( mt_serials_entered )
        sticky             = 'ColumnHeaders'
        showseparators     = 'All'
        alternaterowcolors = abap_true
        mode               = 'MultiSelect' ).

    lo_table->columns(
        )->column( '20rem'
            )->text( 'Serial Number' ).

    lo_table->items( )->column_list_item( selected = '{SELKZ}' )->cells(
        )->text( '{SERIAL}' ).

    lo_dialog->buttons(
                )->button( text  = 'Delete selected'
                           press = io_client->_event( 'SERIAL_DELETE' )
                           type  = 'Default'
                )->button( text  = 'Continue'
                           press = io_client->_event( 'SERIAL_CONTINUE' )
                           type  = 'Accept'
                )->button( text  = 'Cancel'
                           press = io_client->_event( 'SERIAL_CANCEL' )
                           type  = 'Reject' ).
  ENDMETHOD.

  METHOD build_error_screen.
    " TODO: parameter IO_CLIENT is never used (ABAP cleaner)

    ro_screen = z2ui5_cl_xml_view=>factory( ).

    ro_screen->_z2ui5( )->title( title = 'Workstation'(001) ).

    DATA(lo_page) = ro_screen->shell( )->page( title = 'Error' ).

    lo_page->vbox( height         = '100%'
                   width          = '100%'
                   alignitems     = 'Center'
                   justifycontent = 'Center'  )->icon( src   = 'sap-icon://error'
                                                       size  = '64px'
                                                       color = '#E69A17' )->text(
                                                                             text  = |Step "{ mv_step }" not available!|
                                                                             class = 'sapUiSmallMargin'  ).
  ENDMETHOD.

  METHOD hndl_event_100.
    CASE io_client->get( )-event.
      WHEN 'GO_200'.

        IF validate_input_screen100( ) = abap_true.

          mv_step = 'SCREEN200'.
          CLEAR mv_focus_id.

        ENDIF.

      WHEN 'F4_LGNUM'.

        DATA(lt_lgnum) = NEW zcl_workst_srv( )->get_lgnum_list( ).

        CLEAR mt_lgnum_sel.
        LOOP AT lt_lgnum REFERENCE INTO DATA(lr_lgnum).

          mt_lgnum_sel = VALUE #( BASE mt_lgnum_sel
                                  ( value = lr_lgnum->lgnum
                                    descr = lr_lgnum->description  ) ).

        ENDLOOP.

        f4_lgnum_popup( io_client ).

      WHEN 'F4_LGNUM_CONTINUE'.
        DELETE mt_lgnum_sel WHERE selkz = abap_false.
        IF lines( mt_lgnum_sel ) = 1.
          ms_data-lgnum = mt_lgnum_sel[ 1 ]-value.
        ENDIF.

        io_client->popup_destroy( ).

      WHEN 'F4_LGNUM_CANCEL'.
        CLEAR mt_lgnum_sel.
        io_client->popup_destroy( ).

      WHEN 'F4_WORKST'.

        DATA(lt_workst) = NEW zcl_workst_srv( )->get_workstation_list( ).

        " . filter with LGNUM if set
        IF ms_data-lgnum IS NOT INITIAL.

          DELETE lt_workst WHERE lgnum <> ms_data-lgnum.

        ENDIF.

        CLEAR mt_workst_sel.
        LOOP AT lt_workst REFERENCE INTO DATA(lr_workst).

          mt_workst_sel = VALUE #( BASE mt_workst_sel
                                   ( value = lr_workst->workstation
                                     descr = lr_workst->description  ) ).

        ENDLOOP.

        f4_workst_popup( io_client ).

      WHEN 'F4_WORKST_CONTINUE'.
        DELETE mt_workst_sel WHERE selkz = abap_false.
        IF lines( mt_workst_sel ) = 1.
          ms_data-workstation = mt_workst_sel[ 1 ]-value.

        ENDIF.

        io_client->popup_destroy( ).

      WHEN 'F4_WORKST_CANCEL'.
        CLEAR mt_workst_sel.
        io_client->popup_destroy( ).

      WHEN 'CHANGE_LGNUM'.

        change_lgnum( ).

      WHEN 'CHANGE_WORKST'.

        change_workst( ).

      WHEN 'BACK'.
        io_client->nav_app_leave( ).

    ENDCASE.
  ENDMETHOD.

  METHOD hndl_event_200.
    CASE io_client->get( )-event.

      WHEN 'GO_100'.

        " . TODO: show PopUp, that data will be lost

        mv_step = 'SCREEN100'.

        init_200( ).

      WHEN 'SEL_DLV'.

        " ---------------------------------------------------------------------
        " . Just some sample data
        " ---------------------------------------------------------------------

        DATA(lo_srv) = NEW zcl_workst_srv( ).

        IF ms_data-input_hu IS INITIAL.

          CLEAR: ms_data-input_hu_valuestate,
                 ms_data-input_hu_valuestatetext.

        ENDIF.

        IF ms_data-input_dlv IS INITIAL.

          CLEAR: ms_data-input_dlv_valuestate,
                 ms_data-input_dlv_valuestatetext.

        ENDIF.

        IF     ms_data-input_dlv IS INITIAL
           AND ms_data-input_hu  IS INITIAL.

          show_message_strip( iv_text = 'Delivery or HU not provided'
                              iv_type = 'Information' ).

        ENDIF.

        IF     ms_data-input_dlv IS INITIAL
           AND ms_data-input_hu  IS NOT INITIAL.

          TRY.

              ms_data-input_dlv = lo_srv->get_dlv_by_hu( iv_lgnum   = ms_data-lgnum
                                                         iv_huident = ms_data-input_hu ).

            CATCH zcx_app_general INTO DATA(lo_ex).

              ms_data-input_hu_valuestate     = 'Error'.
              ms_data-input_hu_valuestatetext = lo_ex->get_text( ).

              mv_focus_id = 'idInpHU'.

              RETURN.

          ENDTRY.

          ms_data-input_hu_valuestate     = 'Success'.
          ms_data-input_hu_valuestatetext = ''.

        ENDIF.

        IF ms_data-input_dlv IS NOT INITIAL.

          TRY.

              lo_srv->get_dlv_data( EXPORTING iv_docno     = ms_data-input_dlv
                                    IMPORTING et_pick_hu   = ms_data-t_pick_hu_all
                                              et_ship_hu   = ms_data-t_ship_hu_all
                                              et_pick_item = ms_data-t_pick_hu_item ).

            CATCH zcx_app_general INTO lo_ex.

              ms_data-input_dlv_valuestate     = 'Error'.
              ms_data-input_dlv_valuestatetext = lo_ex->get_text( ).

              mv_focus_id = 'idInpDlv'.

              RETURN.

          ENDTRY.

          ms_data-input_dlv_valuestate     = 'Success'.
          ms_data-input_dlv_valuestatetext = ''.

          mv_focus_id = 'idInpProduct'.

        ENDIF.

      WHEN 'PICK_SINGLE'.

        CLEAR: ms_data-input_product,
               ms_data-input_product_valuestate,
               ms_data-input_product_valuestatetext,
               ms_data-input_qty,
               ms_data-input_qty_valuestate,
               ms_data-input_qty_valuestatetext,
               ms_data-unit_qty.

        " . Display selected product in INPUT_PRODUCT and show quantity in INPUT_QTY, UNIT_QTY
        DATA(lt_pick_item) = ms_data-t_pick_hu_item.
        DELETE lt_pick_item WHERE selected = abap_false.

        CASE lines( lt_pick_item ).
          WHEN 0.

            show_message_strip( iv_text = 'Please select a product first!'
                                iv_type = 'Information' ).

          WHEN 1.

            ms_data-input_product = lt_pick_item[ 1 ]-productno.
            ms_data-input_qty     = lt_pick_item[ 1 ]-quantity.
            ms_data-unit_qty      = lt_pick_item[ 1 ]-unit.

            mv_focus_id = 'idInpQuantity'.

          WHEN OTHERS.

            show_message_strip( iv_text = 'Please select only ONE product!'
                                iv_type = 'Information' ).

        ENDCASE.

      WHEN 'MOVE_PICK_SEL'.

        CLEAR: ms_data-input_product,
               ms_data-input_product_valuestate,
               ms_data-input_product_valuestatetext,
               ms_data-input_qty,
               ms_data-input_qty_valuestate,
               ms_data-input_qty_valuestatetext,
               ms_data-unit_qty.

        LOOP AT ms_data-t_pick_hu_item REFERENCE INTO DATA(lr_pick_item)
             WHERE selected = abap_true.

          lr_pick_item->selected = abap_false.
          APPEND lr_pick_item->* TO ms_data-t_ship_hu_item.

          DELETE ms_data-t_pick_hu_item.

        ENDLOOP.
        IF sy-subrc <> 0.

          show_message_strip( iv_text = 'Please select a product first!'
                              iv_type = 'Information' ).
        ELSE.

          compact_by_product( CHANGING ct_item = ms_data-t_ship_hu_item ).

        ENDIF.

      WHEN 'MOVE_PICK_ALL'.

        CLEAR: ms_data-input_product,
               ms_data-input_product_valuestate,
               ms_data-input_product_valuestatetext,
               ms_data-input_qty,
               ms_data-input_qty_valuestate,
               ms_data-input_qty_valuestatetext,
               ms_data-unit_qty.

        APPEND LINES OF ms_data-t_pick_hu_item TO ms_data-t_ship_hu_item.
        REFRESH ms_data-t_pick_hu_item.

        LOOP AT ms_data-t_ship_hu_item REFERENCE INTO DATA(lr_ship_item)
             WHERE selected = abap_true.

          lr_ship_item->selected = abap_false.

        ENDLOOP.

        compact_by_product( CHANGING ct_item = ms_data-t_ship_hu_item ).

      WHEN 'CREATE_SHIP_HU'.

        IF ms_data-ship_huident IS NOT INITIAL.

          show_message_strip( iv_text = 'Shipping HU already created!'
                              iv_type = 'Information' ).

          RETURN.

        ENDIF.

        lo_srv = NEW zcl_workst_srv( ).

        ms_data-ship_huident = |{ lo_srv->create_ship_hu( ) ALPHA = OUT }|.

        show_message_strip( iv_text = 'New shiping HU created'
                            iv_type = 'Success' ).

      WHEN 'CLOSE_SHIP_HU'.

        " . TODO: Call Service to close HU in real EWM. For now just simulation
        IF ms_data-ship_huident IS INITIAL.

          show_message_strip( iv_text = 'No shipping HU created. Create shipping HU first!'
                              iv_type = 'Information' ).

          RETURN.

        ENDIF.

        IF lines( ms_data-t_ship_hu_item ) = 0.

          show_message_strip( iv_text = 'No Items are packed in the shipping HU. Close HU not possible!'
                              iv_type = 'Information' ).

          RETURN.

        ENDIF.

        TRY.
            NEW zcl_workst_srv( )->close_ship_hu( i_lgnum   = ms_data-lgnum
                                                  i_huident = ms_data-ship_huident ).
          CATCH zcx_app_general INTO lo_ex.

            show_message_strip( iv_text = lo_ex->get_text( )
                                iv_type = 'Error' ).

            RETURN.

        ENDTRY.

        APPEND INITIAL LINE TO ms_data-t_ship_hu_all REFERENCE INTO DATA(lr_ship_hu_all).
        lr_ship_hu_all->huident = ms_data-ship_huident.
        lr_ship_hu_all->lgpla   = |{ ms_data-workstation }-SHIP-OUT1|.

        CLEAR: ms_data-ship_huident,
               ms_data-t_ship_hu_item.

        show_message_strip( iv_text = 'Shiping HU closed'
                            iv_type = 'Success' ).

      WHEN 'MOVE_SHIP_SEL'.

        LOOP AT ms_data-t_ship_hu_item REFERENCE INTO lr_ship_item
             WHERE selected = abap_true.

          lr_ship_item->selected = abap_false.
          APPEND lr_ship_item->* TO ms_data-t_pick_hu_item.

          DELETE ms_data-t_ship_hu_item.

        ENDLOOP.
        IF sy-subrc <> 0.

          show_message_strip( iv_text = 'Please select a product first!'
                              iv_type = 'Information' ).
        ELSE.

          compact_by_product( CHANGING ct_item = ms_data-t_pick_hu_item ).

        ENDIF.

      WHEN 'MOVE_SHIP_ALL'.

        APPEND LINES OF ms_data-t_ship_hu_item TO ms_data-t_pick_hu_item.
        REFRESH ms_data-t_ship_hu_item.

        LOOP AT ms_data-t_pick_hu_item REFERENCE INTO lr_pick_item
             WHERE selected = abap_true.

          lr_pick_item->selected = abap_false.

        ENDLOOP.

        compact_by_product( CHANGING ct_item = ms_data-t_pick_hu_item ).

      WHEN 'PRODUCT_INPUT'.

        CLEAR: ms_data-input_product_valuestate,
               ms_data-input_product_valuestatetext,
               ms_data-input_qty_valuestate,
               ms_data-input_qty_valuestatetext.

        IF ms_data-input_product IS INITIAL.

          ms_data-input_product_valuestate     = 'Error'.
          ms_data-input_product_valuestatetext = 'Product is required'.

          RETURN.

        ENDIF.

        IF NOT line_exists( ms_data-t_pick_hu_item[ productno = ms_data-input_product ] ).

          ms_data-input_product_valuestate     = 'Error'.
          ms_data-input_product_valuestatetext = 'Product not found'.

          RETURN.

        ENDIF.

        ms_data-input_product_valuestate     = 'Success'.
        ms_data-input_product_valuestatetext = ''.

        ms_data-input_qty                    = ms_data-t_pick_hu_item[ productno = ms_data-input_product ]-quantity.
        ms_data-unit_qty                     = ms_data-t_pick_hu_item[ productno = ms_data-input_product ]-unit.

        mv_focus_id = 'idInpQuantity'.

      WHEN 'PACK_QTY'.

        CLEAR:
               ms_data-input_product_valuestate,
               ms_data-input_product_valuestatetext,
               ms_data-input_qty_valuestate,
               ms_data-input_qty_valuestatetext.

        IF ms_data-input_product IS INITIAL.

          ms_data-input_product_valuestate     = 'Error'.
          ms_data-input_product_valuestatetext = 'Product is required'.

          RETURN.

        ENDIF.

        IF NOT line_exists( ms_data-t_pick_hu_item[ productno = ms_data-input_product ] ).

          ms_data-input_product_valuestate     = 'Error'.
          ms_data-input_product_valuestatetext = 'Product not found'.

          RETURN.

        ENDIF.

        IF ms_data-input_qty <= 0.

          ms_data-input_qty_valuestate     = 'Error'.
          ms_data-input_qty_valuestatetext = 'Quantity > 0 is required'.

          RETURN.
        ENDIF.

        lr_pick_item = REF #( ms_data-t_pick_hu_item[ productno = ms_data-input_product ] ).

        IF lr_pick_item->quantity < ms_data-input_qty.

          ms_data-input_qty_valuestate     = 'Error'.
          ms_data-input_qty_valuestatetext = |Only { lr_pick_item->quantity DECIMALS = 2 } { lr_pick_item->unit } of product { ms_data-input_product } available|.

          RETURN.

        ENDIF.

        " . Call PopUp for Serial numbers
        IF     lines( lr_pick_item->serial )  > 0
           AND lr_pick_item->quantity        <> ms_data-input_qty.

          mv_step = 'SCREEN300'.
          RETURN.

        ENDIF.

        APPEND INITIAL LINE TO ms_data-t_ship_hu_item REFERENCE INTO lr_ship_item.
        lr_ship_item->*        = lr_pick_item->*.
        lr_ship_item->quantity = ms_data-input_qty.
        lr_pick_item->quantity -= ms_data-input_qty.

        DELETE ms_data-t_pick_hu_item WHERE quantity <= 0.

        LOOP AT ms_data-t_ship_hu_item REFERENCE INTO lr_ship_item
             WHERE selected = abap_true.

          lr_ship_item->selected = abap_false.

        ENDLOOP.

        LOOP AT ms_data-t_pick_hu_item REFERENCE INTO lr_pick_item
             WHERE selected = abap_true.

          lr_pick_item->selected = abap_false.

        ENDLOOP.

        compact_by_product( CHANGING ct_item = ms_data-t_ship_hu_item ).

        CLEAR: ms_data-input_product,
               ms_data-input_product_valuestate,
               ms_data-input_product_valuestatetext,
               ms_data-input_qty,
               ms_data-input_qty_valuestate,
               ms_data-input_qty_valuestatetext.

        mv_focus_id = 'idInpProduct'.

      WHEN 'FIN_DLV'.

        " . Show PopUp, if HU is not closed or not all items are packed
        IF    lines( ms_data-t_pick_hu_item ) > 0
           OR lines( ms_data-t_ship_hu_item ) > 0.

          mv_step = 'FINDLV'.

          RETURN.

        ENDIF.

        init_200( ).

        mv_focus_id = 'idInpDlv'.

      WHEN 'FINDLV_YES'.

        init_200( ).

        mv_focus_id = 'idInpDlv'.
        mv_step     = 'SCREEN200'.

        io_client->popup_destroy( ).

      WHEN 'FINDLV_NO'.

        mv_step = 'SCREEN200'.

        io_client->popup_destroy( ).

      WHEN 'CLOSE_MESSAGE_STRIP'.

        mv_show_message = abap_false.

    ENDCASE.
  ENDMETHOD.

  METHOD hndl_event_300.
    CASE io_client->get( )-event.
      WHEN 'SERIAL_ENTER'.

        CLEAR: ms_data-input_serial_valuestate,
               ms_data-input_serial_valuestatetext.

        " . Check if already entered
        IF ms_data-input_serial IS NOT INITIAL.

          IF line_exists( mt_serials_entered[ serial = ms_data-input_serial ] ).

            ms_data-input_serial_valuestatetext = 'Serial Number already entered'.
            ms_data-input_serial_valuestate     = 'Error'.

            RETURN.

          ENDIF.

          " . Check if serial number is available
          DATA(lr_pick_item) = REF #( ms_data-t_pick_hu_item[ productno = ms_data-input_product ] ).

          IF NOT line_exists( lr_pick_item->serial[ table_line = ms_data-input_serial ] ).

            ms_data-input_serial_valuestatetext = 'Serial Number not available'.
            ms_data-input_serial_valuestate     = 'Error'.

            RETURN.

          ENDIF.

          IF lines( mt_serials_entered ) + 1 > ms_data-input_qty.

            ms_data-input_serial_valuestatetext = 'Too many serial numbers'.
            ms_data-input_serial_valuestate     = 'Error'.

            RETURN.

          ENDIF.

          APPEND VALUE #( serial = ms_data-input_serial ) TO mt_serials_entered.

          CLEAR ms_data-input_serial.

        ELSE.

          ms_data-input_serial_valuestatetext = 'Serial Number required'.
          ms_data-input_serial_valuestate     = 'Error'.

          RETURN.

        ENDIF.

      WHEN 'SERIAL_DELETE'.

        LOOP AT mt_serials_entered TRANSPORTING NO FIELDS
             WHERE selkz = abap_true.

          DELETE mt_serials_entered.

        ENDLOOP.

      WHEN 'SERIAL_CONTINUE'.

        IF lines( mt_serials_entered ) <> ms_data-input_qty.
          " . number of entered serial number must be equal to entered quantity
          ms_data-input_serial_valuestatetext = 'Too many serial numbers'.
          ms_data-input_serial_valuestate     = 'Error'.

          RETURN.
        ENDIF.

        lr_pick_item = REF #( ms_data-t_pick_hu_item[ productno = ms_data-input_product ] ).

        APPEND INITIAL LINE TO ms_data-t_ship_hu_item REFERENCE INTO DATA(lr_ship_item).
        lr_ship_item->*        = lr_pick_item->*.
        lr_ship_item->quantity = ms_data-input_qty.
        lr_pick_item->quantity -= ms_data-input_qty.

        LOOP AT mt_serials_entered REFERENCE INTO DATA(lr_serial).

          APPEND lr_serial->serial TO lr_ship_item->serial.

          DELETE lr_pick_item->serial WHERE table_line = lr_serial->serial.

        ENDLOOP.

        DELETE ms_data-t_pick_hu_item WHERE quantity <= 0.

        LOOP AT ms_data-t_ship_hu_item REFERENCE INTO lr_ship_item
             WHERE selected = abap_true.

          lr_ship_item->selected = abap_false.

        ENDLOOP.

        LOOP AT ms_data-t_pick_hu_item REFERENCE INTO lr_pick_item
             WHERE selected = abap_true.

          lr_pick_item->selected = abap_false.

        ENDLOOP.

        compact_by_product( CHANGING ct_item = ms_data-t_ship_hu_item ).

        CLEAR: ms_data-input_product,
               ms_data-input_product_valuestate,
               ms_data-input_product_valuestatetext,
               ms_data-input_qty,
               ms_data-input_qty_valuestate,
               ms_data-input_qty_valuestatetext,
               ms_data-input_serial,
               ms_data-input_serial_valuestate,
               ms_data-input_serial_valuestatetext,
               mt_serials_entered.

        " . Continue with pack
        mv_step = 'SCREEN200'.
        mv_focus_id = 'idInpProduct'.

        io_client->popup_destroy( ).

      WHEN 'SERIAL_CANCEL'.

        CLEAR: ms_data-input_product,
               ms_data-input_product_valuestate,
               ms_data-input_product_valuestatetext,
               ms_data-input_qty,
               ms_data-input_qty_valuestate,
               ms_data-input_qty_valuestatetext,
               ms_data-input_serial,
               ms_data-input_serial_valuestate,
               ms_data-input_serial_valuestatetext,
               mt_serials_entered.

        io_client->popup_destroy( ).

        " . Continue with pack
        mv_step = 'SCREEN200'.

      WHEN OTHERS.

    ENDCASE.
  ENDMETHOD.

  METHOD f4_lgnum_popup.
    DATA(lo_popup) = z2ui5_cl_xml_view=>factory_popup( ).

    lo_popup->dialog( 'Warehouse Number'
      )->table( mode  = 'SingleSelectLeft'
                items = io_client->_bind_edit( mt_lgnum_sel )
        )->columns(
            )->column( '20rem'
                )->text( 'Warehouse Number' )->get_parent(
            )->column(
                )->text( 'Description'
        )->get_parent( )->get_parent(
        )->items(
            )->column_list_item( selected = '{SELKZ}'
                )->cells(
                    )->text( '{VALUE}'
                    )->text( '{DESCR}'
      )->get_parent( )->get_parent( )->get_parent( )->get_parent(
      )->buttons(
            )->button( text  = 'Select'
                       press = io_client->_event( 'F4_LGNUM_CONTINUE' )
                       type  = 'Emphasized'
                       )->button( text  = 'Cancel'
                                  press = io_client->_event( 'F4_LGNUM_CANCEL' )
                                  type  = 'Reject' ).

    io_client->popup_display( lo_popup->stringify( ) ).
  ENDMETHOD.

  METHOD f4_workst_popup.
    DATA(lo_popup) = z2ui5_cl_xml_view=>factory_popup( ).

    lo_popup->dialog( 'Workstation'
      )->table( mode  = 'SingleSelectLeft'
                items = io_client->_bind_edit( mt_workst_sel )
        )->columns(
            )->column( '20rem'
                )->text( 'Workstation' )->get_parent(
            )->column(
                )->text( 'Description'
        )->get_parent( )->get_parent(
        )->items(
            )->column_list_item( selected = '{SELKZ}'
                )->cells(
                    )->text( '{VALUE}'
                    )->text( '{DESCR}'
      )->get_parent( )->get_parent( )->get_parent( )->get_parent(
      )->buttons(
            )->button( text  = 'Select'
                       press = io_client->_event( 'F4_WORKST_CONTINUE' )
                       type  = 'Emphasized'
                       )->button( text  = 'Cancel'
                                  press = io_client->_event( 'F4_WORKST_CANCEL' )
                                  type  = 'Reject' ).

    io_client->popup_display( lo_popup->stringify( ) ).
  ENDMETHOD.

  METHOD change_lgnum.
    IF ms_data-lgnum IS INITIAL.
      CLEAR ms_data-lgnum_valuestate.
      CLEAR ms_data-lgnum_valuestatetext.

      mv_focus_id = 'idLgnum'.

      RETURN.
    ENDIF.

    DATA(lt_lgnum) = NEW zcl_workst_srv( )->get_lgnum_list( ).

    IF NOT line_exists( lt_lgnum[ lgnum = ms_data-lgnum ] ).

      ms_data-lgnum_valuestate     = 'Error'.
      ms_data-lgnum_valuestatetext = 'Error in LGNUM'.

      mv_focus_id = 'idLgnum'.

    ELSE.

      CLEAR ms_data-lgnum_valuestate.
      CLEAR ms_data-lgnum_valuestatetext.

      mv_focus_id = 'idWorkst'.

    ENDIF.
  ENDMETHOD.

  METHOD change_workst.
    IF ms_data-workstation IS INITIAL.
      CLEAR ms_data-workst_valuestate.
      CLEAR ms_data-workst_valuestatetext.

      mv_focus_id = 'idWorkst'.

      RETURN.
    ENDIF.

    DATA(lt_workst) = NEW zcl_workst_srv( )->get_workstation_list( ).

    IF ms_data-lgnum IS NOT INITIAL.

      DELETE lt_workst WHERE lgnum <> ms_data-lgnum.

    ENDIF.

    IF NOT line_exists( lt_workst[ workstation = ms_data-workstation ] ).

      ms_data-workst_valuestate     = 'Error'.
      ms_data-workst_valuestatetext = 'Error in Workstation'.

      mv_focus_id = 'idWorkst'.

    ELSE.
      CLEAR ms_data-workst_valuestate.
      CLEAR ms_data-workst_valuestatetext.

      mv_focus_id = 'idLogin'.

    ENDIF.
  ENDMETHOD.

  METHOD validate_input_screen100.
    rv_okey = abap_true.

    IF ms_data-lgnum IS INITIAL.

      ms_data-lgnum_valuestate     = 'Error'.
      ms_data-lgnum_valuestatetext = 'Lgnum required'.

      CLEAR rv_okey.

    ELSE.

      DATA(lt_lgnum) = NEW zcl_workst_srv( )->get_lgnum_list( ).

      IF NOT line_exists( lt_lgnum[ lgnum = ms_data-lgnum ] ).

        ms_data-lgnum_valuestate     = 'Error'.
        ms_data-lgnum_valuestatetext = 'Error in LGNUM'.

        CLEAR rv_okey.
      ELSE.

        CLEAR: ms_data-lgnum_valuestate,
               ms_data-lgnum_valuestatetext.

      ENDIF.
    ENDIF.

    IF ms_data-workstation IS INITIAL.

      ms_data-workst_valuestate     = 'Error'.
      ms_data-workst_valuestatetext = 'Workst required'.

      CLEAR rv_okey.

    ELSE.

      DATA(lt_workst) = NEW zcl_workst_srv( )->get_workstation_list( ).

      IF ms_data-lgnum IS NOT INITIAL.

        DELETE lt_workst WHERE lgnum <> ms_data-lgnum.

      ENDIF.

      IF NOT line_exists( lt_workst[ workstation = ms_data-workstation ] ).

        ms_data-workst_valuestate     = 'Error'.
        ms_data-workst_valuestatetext = 'Error in Workstation'.

        CLEAR rv_okey.

      ELSE.

        CLEAR: ms_data-workst_valuestate,
               ms_data-workst_valuestatetext.

        READ TABLE lt_workst REFERENCE INTO DATA(lr_workst)
             WITH KEY workstation = ms_data-workstation.
        IF sy-subrc = 0.

          ms_data-workst_description = lr_workst->description.

        ENDIF.

      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD show_message_strip.
    mv_message_text = iv_text.
    mv_message_type = iv_type.
    mv_show_message = abap_true.
  ENDMETHOD.

  METHOD compact_by_product.
    DATA(lt_item_compact) = ct_item.

    SORT lt_item_compact BY productno.
    DELETE ADJACENT DUPLICATES FROM lt_item_compact COMPARING productno.

    LOOP AT lt_item_compact REFERENCE INTO DATA(lr_item_compact).

      lr_item_compact->quantity = 0.
      REFRESH lr_item_compact->serial.
      LOOP AT ct_item REFERENCE INTO DATA(lr_item)
           WHERE productno = lr_item_compact->productno.

        lr_item_compact->quantity += lr_item->quantity.
        APPEND LINES OF lr_item->serial TO lr_item_compact->serial.

      ENDLOOP.
    ENDLOOP.

    ct_item = lt_item_compact.
  ENDMETHOD.

  METHOD init_200.
    CLEAR: ms_data-input_dlv,
           ms_data-input_dlv_valuestate,
           ms_data-input_dlv_valuestatetext,
           ms_data-input_hu,
           ms_data-input_hu_valuestate,
           ms_data-input_hu_valuestatetext,
           ms_data-input_product,
           ms_data-input_product_valuestate,
           ms_data-input_product_valuestatetext,
           ms_data-input_qty,
           ms_data-input_qty_valuestate,
           ms_data-input_qty_valuestatetext,
           ms_data-unit_qty,
           ms_data-ship_huident,
           ms_data-t_pick_hu_item,
           ms_data-t_pick_hu_all,
           ms_data-t_ship_hu_item,
           ms_data-t_ship_hu_all,
           ms_data-input_serial,
           ms_data-input_serial_valuestate,
           ms_data-input_serial_valuestatetext.
  ENDMETHOD.

  METHOD build_screen_yesno.
    ro_popup = zcl_abap2ui5_utils=>message_box_query(
                   iv_title  = 'Stop working on delivery?'
                   iv_text   = 'Not all items are packed. Are you sure to finish delivery? All data will be lost!'
                   iv_icon   = 'sap-icon://alert'
                   iv_type   = 'Warning'
                   io_client = io_client
                   it_action = VALUE #( ( name = 'Yes' type = 'Accept' event = 'FINDLV_YES' )
                                        ( name = 'No' type = 'Reject' event = 'FINDLV_NO' ) ) ).
  ENDMETHOD.
ENDCLASS.
