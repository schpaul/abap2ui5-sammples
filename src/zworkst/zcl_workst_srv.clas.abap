CLASS zcl_workst_srv DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS get_lgnum_list
      RETURNING VALUE(rt_lgnum) TYPE zui5_t_lgnum.

    METHODS get_workstation_list
      RETURNING VALUE(rt_workst) TYPE zui5_t_workst.

    METHODS get_pick_hu_all
      IMPORTING iv_docno          TYPE char35
      RETURNING VALUE(rt_pick_hu) TYPE zui5_t_workst_hu_overview.

    METHODS get_ship_hu_all
      IMPORTING iv_docno          TYPE char35
      RETURNING VALUE(rt_ship_hu) TYPE zui5_t_workst_hu_overview.

    METHODS get_pick_hu_item
      IMPORTING iv_docno       TYPE char35
      RETURNING VALUE(rt_item) TYPE zui5_t_workst_item_overview.

    METHODS get_ship_hu_item
      IMPORTING iv_huident     TYPE char20
      RETURNING VALUE(rt_item) TYPE zui5_t_workst_item_overview.

    METHODS create_ship_hu
      RETURNING VALUE(rv_huident) TYPE char40.

    METHODS get_dlv_by_hu
      IMPORTING iv_lgnum        TYPE char4
                iv_huident      TYPE char20
      RETURNING VALUE(rv_docno) TYPE char35
      RAISING   zcx_app_general.

    METHODS get_dlv_data IMPORTING iv_docno     TYPE char35
                         EXPORTING et_pick_hu   TYPE zui5_t_workst_hu_overview
                                   et_ship_hu   TYPE zui5_t_workst_hu_overview
                                   et_pick_item TYPE zui5_t_workst_item_overview
                         RAISING   zcx_app_general.

       METHODS close_ship_hu
      IMPORTING i_lgnum        TYPE char4
                i_huident      TYPE char20
      RAISING   zcx_app_general.


ENDCLASS.


CLASS zcl_workst_srv IMPLEMENTATION.
  METHOD get_lgnum_list.
    rt_lgnum = VALUE #( ( lgnum       = '0001'
                          description = 'Sample Warehouse' )
                        ( lgnum       = '3000'
                          description = 'My very big warehouse' ) ).
  ENDMETHOD.

  METHOD get_workstation_list.
    rt_workst = VALUE #( lgnum = '3000'
                         ( workstation = 'WS01'
                           description = 'Packing Workstation 1' )
                         ( workstation = 'WS02'
                           description = 'Packing Workstation 2' )
                         ( workstation = 'WS03'
                           description = 'Packing Workstation 3' ) ).
  ENDMETHOD.

  METHOD get_pick_hu_all.
    IF     iv_docno <> '0815'
       AND iv_docno <> '0814'.
      RETURN.
    ENDIF.

    " . Some sample data
    rt_pick_hu = VALUE #( lgpla = 'WS01-PICK-IN1'
                          ( huident = '5000001'  )
                          ( huident = '5000002'  )
                          ( huident = '5000005'  )
                          ( huident = '5000012'  )
                          lgpla = 'WS01-PICK-IN2'
                          ( huident = '5000011'  )
                          ( huident = '5000006'  )
                          ( huident = '5000015'  )
                          ( huident = '5000014'  ) ).
  ENDMETHOD.

  METHOD get_ship_hu_all.
    IF     iv_docno <> '0815'
       AND iv_docno <> '0814'.
      RETURN.
    ENDIF.

    " . Some sample data
    rt_ship_hu = VALUE #( lgpla = 'WS01-SHIP-OUT1'
                          ( huident = '9000001'  )
                          ( huident = '9000002'  ) ).
  ENDMETHOD.

  METHOD get_pick_hu_item.
    IF NOT ( iv_docno = '0815' OR iv_docno = '0814' ).
      RETURN.
    ENDIF.

    " . some sample data
    rt_item = VALUE #( ( productno    = '12345'
                         productdescr = 'Simple Product'
                         quantity     = 30
                         unit         = 'PC' )
                       ( productno    = '32345'
                         productdescr = 'Simple KG product'
                         quantity     = '10.5'
                         unit         = 'KG' )
                       ( productno    = '99123'
                         productdescr = 'Simple serial number product'
                         quantity     = '3'
                         unit         = 'PC'
                         serial       = VALUE #( ( '123456' )
                                                 ( '123457' )
                                                 ( '123458' ) ) ) ).
  ENDMETHOD.

  METHOD get_ship_hu_item.
    IF iv_huident IS INITIAL.
      RETURN.
    ENDIF.

    " . some sample data
    rt_item = VALUE #( ( productno    = '12345'
                         productdescr = 'Simple Product'
                         quantity     = 2
                         unit         = 'PC' )
                       ( productno    = '0032345'
                         productdescr = 'Simple KG product'
                         quantity     = '1'
                         unit         = 'KG' ) ).
  ENDMETHOD.

  METHOD create_ship_hu.
    " ---------------------------------------------------------------------
    " . Get new HU number, but do not create HU itself
    " ---------------------------------------------------------------------

    DATA(lv_rnd_num) = cl_abap_random_int=>create( seed = CONV i( sy-uzeit )
                                                   min  = 1
                                                   max  = 999
                                        )->get_next( ).

    DATA(lv_rnd_txt) = CONV string( lv_rnd_num ).

    rv_huident = |00000000000009000{ lv_rnd_txt WIDTH = 3 ALPHA = IN }|.
  ENDMETHOD.

  METHOD get_dlv_by_hu.
    IF iv_lgnum = '3000'.

      IF    iv_huident = '5000001'
         OR iv_huident = '5000002'
         OR iv_huident = '5000005'
         OR iv_huident = '5000012'.

        rv_docno = '0815'.

      ELSEIF    iv_huident = '5000006'
             OR iv_huident = '5000011'
             OR iv_huident = '5000015'
             OR iv_huident = '5000014'.

        rv_docno = '0814'.

      ELSE.

        " . // Picking HU &1 not found or no delivery assigned to this HU
        RAISE EXCEPTION TYPE zcx_app_general MESSAGE e001 WITH iv_huident.

      ENDIF.

    ELSE.

      " . // Warehouse number &1 does not exist
      RAISE EXCEPTION TYPE zcx_app_general MESSAGE e002 WITH iv_lgnum.

    ENDIF.
  ENDMETHOD.

  METHOD get_dlv_data.
    " . query delivery data :-)
    IF iv_docno <> '0815' AND iv_docno <> '0814'.

      " . Delivery &1 not found!
      RAISE EXCEPTION TYPE zcx_app_general MESSAGE e003 WITH iv_docno.

    ENDIF.

    et_pick_hu = get_pick_hu_all( iv_docno ).
    et_ship_hu = get_ship_hu_all( iv_docno ).
    et_pick_item = get_pick_hu_item( iv_docno ).
  ENDMETHOD.

  METHOD close_ship_hu.

    " . Just simulate waiting time of processing
    WAIT UP TO 3 SECONDS.

  ENDMETHOD.

ENDCLASS.
