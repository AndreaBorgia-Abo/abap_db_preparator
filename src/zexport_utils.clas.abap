CLASS zexport_utils DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      _conditions TYPE STANDARD TABLE OF string .

    CLASS-METHODS get_table_for_all_entries
      IMPORTING
        !table_conjunction TYPE zexport_table_list
      RETURNING
        VALUE(table_name)  TYPE tabname
      EXCEPTIONS
        not_for_all_entries_cond .
    "! Perform select-statement
    "! @parameter table_name | Dictionary-Name of table_for_all_entries
    CLASS-METHODS select
      IMPORTING
        !table_for_all_entries TYPE STANDARD TABLE
        !table_conjunction     TYPE zexport_table_list
        !table_name            TYPE tabname
        select_from_fake       TYPE abap_bool DEFAULT abap_false
      EXPORTING
        result TYPE STANDARD TABLE
      RAISING
        zcx_export_empty.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZEXPORT_UTILS IMPLEMENTATION.


  METHOD get_table_for_all_entries.
    CONSTANTS: expression TYPE string VALUE 'FOR ALL ENTRIES IN'.

    DATA(length) = strlen( expression ).
    IF strlen( table_conjunction-where_restriction ) < length
        OR table_conjunction-where_restriction+0(length) <> expression.
      RAISE not_for_all_entries_cond.
    ENDIF.

    DATA(where_condition) = table_conjunction-where_restriction.
    SHIFT where_condition BY length PLACES LEFT.

    FIND FIRST OCCURRENCE OF 'WHERE' IN where_condition
      MATCH OFFSET length
      IGNORING CASE.
    table_name = where_condition+0(length).
    CONDENSE table_name NO-GAPS.
    TRANSLATE table_name TO UPPER CASE.

  ENDMETHOD.


  METHOD select.
    DATA: offset TYPE i,
          length TYPE i.

    IF table_for_all_entries IS INITIAL.
      RAISE EXCEPTION TYPE zcx_export_empty
        EXPORTING
          table_name = table_name.
    ENDIF.

    CLEAR result.
    FIND FIRST OCCURRENCE OF 'WHERE' IN table_conjunction-where_restriction
      MATCH OFFSET offset
      MATCH LENGTH length.
    ASSERT sy-subrc = 0.
    offset = offset + length.
    DATA(where_restriction) = table_conjunction-where_restriction+offset.
    REPLACE ALL OCCURRENCES OF table_name IN where_restriction
      WITH 'table_for_all_entries'
      IGNORING CASE.

    DATA(select_table) = COND tabname( WHEN select_from_fake = abap_true
      THEN table_conjunction-fake_table
      ELSE table_conjunction-source_table ).
    SELECT * FROM (select_table) INTO TABLE result
      FOR ALL ENTRIES IN table_for_all_entries
      WHERE (where_restriction).

  ENDMETHOD.
ENDCLASS.
