*&---------------------------------------------------------------------*
*& Report  ZITE_SD_SO_REPORT
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT zite_sd_so_report.

TABLES vbap.

**********************************************************************
* Global types
**********************************************************************
TYPES: BEGIN OF t_s_data,
         vbeln TYPE vbeln_va,
         posnr TYPE posnr_va,
         matnr TYPE matnr,
       END OF t_s_data.

TYPES: t_y_data TYPE TABLE OF t_s_data.

**********************************************************************
* Selection screen
**********************************************************************
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE text-b01.
SELECT-OPTIONS: s_werks FOR vbap-werks OBLIGATORY.
SELECT-OPTIONS: s_vbeln FOR vbap-vbeln .
SELECTION-SCREEN END OF BLOCK b01.

**********************************************************************
* Classes definitions
**********************************************************************
CLASS cl_so_report_model DEFINITION FINAL.

  PUBLIC SECTION.

    TYPES: t_vbeln  TYPE RANGE OF vbeln.
    TYPES: t_werks  TYPE RANGE OF werks_d.

    TYPES: BEGIN OF t_selection,
             vbeln TYPE t_vbeln,
             werks TYPE t_werks,
           END OF t_selection.

    DATA ms_selection TYPE t_selection.
    DATA mt_data      TYPE TABLE OF t_s_data.

    METHODS: get_data,
      set_selection
        IMPORTING
          ir_vbeln TYPE t_vbeln
          ir_werks TYPE t_werks.

ENDCLASS.

CLASS cl_so_report_view DEFINITION FINAL.

  PUBLIC SECTION.

    TYPES: t_vbeln  TYPE RANGE OF vbeln.
    TYPES: t_werks  TYPE RANGE OF werks_d.

    TYPES: BEGIN OF t_selection,
             vbeln TYPE t_vbeln,
             werks TYPE t_werks,
           END OF t_selection.

    DATA ms_selection TYPE t_selection.

    METHODS: display_so_list
      CHANGING ct_data TYPE t_y_data.

ENDCLASS.

CLASS cl_so_report_controller DEFINITION FINAL.

  PUBLIC SECTION.
    METHODS:
      constructor
        IMPORTING
          ir_model TYPE REF TO cl_so_report_model
          ir_view  TYPE REF TO cl_so_report_view,

      get_data,
      display_alv.

  PRIVATE SECTION.
    DATA:
      model TYPE REF TO cl_so_report_model,
      view  TYPE REF TO cl_so_report_view.

ENDCLASS.

**********************************************************************
* Classes implementations
**********************************************************************

CLASS cl_so_report_model IMPLEMENTATION.

  METHOD get_data.

    SELECT vbeln posnr matnr FROM vbap INTO CORRESPONDING FIELDS OF TABLE me->mt_data UP TO 10 ROWS WHERE vbeln
      IN me->ms_selection-vbeln AND werks IN me->ms_selection-werks.

  ENDMETHOD.

  METHOD set_selection.

    me->ms_selection-vbeln = ir_vbeln.
    me->ms_selection-werks = ir_werks.

  ENDMETHOD.

ENDCLASS.

CLASS cl_so_report_view IMPLEMENTATION.

  METHOD display_so_list.

    DATA: lx_msg TYPE REF TO cx_salv_msg.
    DATA: o_alv TYPE REF TO cl_salv_table.

    TRY.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = o_alv
          CHANGING
            t_table      = ct_data ).
      CATCH cx_salv_msg INTO lx_msg.
    ENDTRY.

    o_alv->display( ).

  ENDMETHOD.

ENDCLASS.

CLASS cl_so_report_controller IMPLEMENTATION.

  METHOD constructor.

    me->model = ir_model.
    me->view = ir_view.

  ENDMETHOD.

  METHOD get_data.
    me->model->get_data( ).
  ENDMETHOD.

  METHOD display_alv.
    me->view->display_so_list( CHANGING ct_data = model->mt_data ).
  ENDMETHOD.

ENDCLASS.


START-OF-SELECTION.

  DATA:
    o_model      TYPE REF TO cl_so_report_model,
    o_view       TYPE REF TO cl_so_report_view,
    o_controller TYPE REF TO cl_so_report_controller.

  o_model = NEW cl_so_report_model( ).
  o_model->set_selection( ir_vbeln = s_vbeln[] ir_werks = s_werks[] ).
  o_model->get_data( ).

  o_view = NEW cl_so_report_view( ).

  o_controller = NEW cl_so_report_controller( ir_model = o_model ir_view = o_view ).

  o_controller->display_alv( ).