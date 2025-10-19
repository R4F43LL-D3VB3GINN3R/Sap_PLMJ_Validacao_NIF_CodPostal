  METHOD verify_nif.

*$*$-------------------------------------------------------------------* 
*$*  IMPLEMENTAÇÃO
*$---------------------------------------------------------------------*
*& Autor        : Rafael Albuquerque (SBX)
*& Data         : 19.09.2025
*& Referência   : [1900/00663.01]
*& Transporte   : S4DK908558
*& Ch. pesquisa : RLAINC0142476
*& Objetivo     : Verifies if nif is valid or not
*&                Verifies if nif is empty or not
*&--------------------------------------------------------------------

    "Verifies if nif is empty or not
    "-------------------------------------------------------------------------------------------
    gv_flag_empty_nif = COND #( WHEN gs_header-stceg IS INITIAL THEN abap_true ELSE abap_false ).

    CHECK gv_flag_empty_nif EQ abap_false.

    "Verifies if nif is a special case
    "-------------------------------------------------------------------------------------------
    CASE gs_header-land1.
      WHEN 'KR'.               "Andorra
        verify_special_nif( ).
        EXIT.
      WHEN OTHERS.             "Nif is not a special case

        "Verifies if nif is valid or not
        "-------------------------------------------------------------------------------------------

        "First Validation
        "-------------------------------------------------------------------------------------------
        DATA(lv_natural_person_flag) = COND #( WHEN gv_person_status EQ abap_true THEN abap_false ELSE abap_true ).

        DATA: ls_is_additional_data TYPE ftx_bptaxnum_data.

        DATA(lv_iv_taxnum)                    = CONV dfkkbptaxnum-taxnum( gs_header-stceg ).
        DATA(lv_iv_taxtype)                   = CONV tfktaxnumtype-taxtype( gs_header-taxtype ).
        ls_is_additional_data-natpers         = lv_natural_person_flag.
        ls_is_additional_data-taxtype_country = gs_header-land1.

        TRY.
            CALL FUNCTION 'VAT_REGISTRATION_NUMBER_CHECK'
              EXPORTING
                iv_taxnum          = lv_iv_taxnum
                iv_taxtype         = lv_iv_taxtype
                is_additional_data = ls_is_additional_data
                iv_combined_check  = abap_true
              EXCEPTIONS
                invalid_taxnum     = 1
                vies_service       = 2
                OTHERS             = 3.
          CATCH cx_root INTO DATA(lx_err2).
            gv_message_error_system = lx_err2->get_text( ).
        ENDTRY.

        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                  INTO gv_message_error_system.
        ENDIF.

        IF gv_message_error_system IS INITIAL.

          "Second Validation
          "-------------------------------------------------------------------------------------------
          DATA(lv_tax_code_1)          = CONV kna1_bf-stcd1( gs_header-stceg ).
          DATA(lv_country)             = CONV sadr-land1( gs_header-land1 ).

          IF gs_header-land1 EQ 'PT'.
            lv_tax_code_1 = lv_tax_code_1+2(9).
          ENDIF.

          TRY.
              CALL FUNCTION 'TAX_NUMBER_CHECK'
                EXPORTING
                  country             = lv_country
                  natural_person_flag = lv_natural_person_flag
                  tax_code_1          = lv_tax_code_1
                EXCEPTIONS
                  not_valid           = 1
                  different_fprcd     = 2
                  OTHERS              = 3.

            CATCH cx_root INTO DATA(lx_err).
              gv_message_error_system = lx_err->get_text( ).
          ENDTRY.

          "get exceptions messages
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                    INTO gv_message_error_system.
          ENDIF.

          IF gs_header-land1 EQ 'PT'.
            CONCATENATE 'PT' lv_tax_code_1 INTO lv_tax_code_1.
            CONDENSE lv_tax_code_1 NO-GAPS.
          ENDIF.

        ENDIF.

        gv_flag_valid_nif = COND #( WHEN gv_message_error_system IS INITIAL THEN abap_true ELSE abap_false ).

    ENDCASE.

  ENDMETHOD.
