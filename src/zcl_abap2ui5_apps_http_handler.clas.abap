CLASS zcl_abap2ui5_apps_http_handler DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_http_extension.
ENDCLASS.


CLASS zcl_abap2ui5_apps_http_handler IMPLEMENTATION.
  METHOD if_http_extension~handle_request.
    z2ui5_cl_http_handler=>run( server ).
  ENDMETHOD.
ENDCLASS.
