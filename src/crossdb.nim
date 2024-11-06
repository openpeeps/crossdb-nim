# CrossDB - A ultra high-performance, lightweight
# embedded and server OLTP RDBMS
# https://github.com/crossdb-org/crossdb
#
# This package implements CrossDB Driver for Nim language
#
# (c) 2024 George Lemon | MIT License
#     Made by Humans from OpenPeeps
#     https://github.com/openpeeps/crossdb-nim

from std/nativesockets import Port

import ./crossdb/bindings
export bindings

type
  CDBConnection* = xdb_conn_t
  CDBStatement* = xdb_stmt_t
  CDBResult* = ptr xdb_res_t
  CDBColumn* = ptr xdb_col_t
  CDBType* = ptr xdb_type_t

  CDBValue* = object
    ## Object variant representing CrossDB Values
    name*: string
    case kind*: xdb_type_t
    of XDB_TYPE_INT:
      int32Value*: int32
    of XDB_TYPE_BIGINT:
      int64Value*: int64
    of XDB_TYPE_SMALLINT:
      smallIntValue*: range[-32768..32767]
    of XDB_TYPE_USMALLINT:
      usIntValue*: range[0..65535]
    of XDB_TYPE_UTINYINT:
      uTinyIntValue*: range[0..255]
    of XDB_TYPE_TINYINT:
      tinyIntValue*: range[-128..127]
    of XDB_TYPE_UINT:
      uIntValue*: uint32
    of XDB_TYPE_UBIGINT:
      uBigIntValue*: uint64
    of XDB_TYPE_CHAR, XDB_TYPE_VCHAR:
      strValue*: string
    of XDB_TYPE_FLOAT:
      float32Value*: float32
    of XDB_TYPE_DOUBLE:
      float64Value*: float64
    of XDB_TYPE_TIMESTAMP:
      timestampValue*: string # todo parse with `std/times`
    of XDB_TYPE_BINARY:
      binVal*: seq[byte]
    of XDB_TYPE_NULL: discard
    else: discard # todo

#
# High-level API for Nim development
#
proc open*(path: string): CDBConnection =
  ## Create a new `CDBConnection`
  xdb_open(path)

proc initMemory*: CDBConnection =
  ## Create a new CrossDB connection in `:memory:`
  xdb_open(":memory:")

proc connect*(host, user, pass, db: string, port: Port): CDBConnection =
  ## Connect to CrossDB with credentials
  xdb_connect(host, user, pass, db, port.uint16)

proc close*(cdb: CDBConnection) =
  ## Close a `CDBConnection`
  xdb_close(cdb)

#
# Prepared Statement
#
proc prepare*(cdb: CDBConnection; sql: string): CDBStatement =
  ## Prepare the SQL statement
  xdb_stmt_prepare(cdb, sql)

#
# SQL
#
proc execute*(cdb: CDBConnection; sql: string): CDBResult {.discardable.} =
  ## Execute SQL statement and return result set
  xdb_exec(cdb, sql)

proc destroyCDBResult*(cdbRes: CDBResult) =
  ## Free result set
  xdb_free_result(cdbRes)

#
# Result
#
proc getColmeta*(cdbres: CDBResult, i: uint16): ptr xdb_col_t =
  ## Retrieve column meta info based on `i` position
  xdb_column_meta(cdbres[].col_meta, i)

proc getColtype*(cdbres: CDBResult, i: uint16): xdb_type_t =
  ## Retrieve the column type based on `i` position
  xdb_column_type(cdbres[].col_meta, i)

proc getColname*(cdbres: CDBResult, icol: uint16): string =
  ## Retrieve name of a column based on `i` position
  $(xdb_column_name(cdbres[].col_meta, icol))

#
# Internal procs to create CDBValue variants
#
proc `$charValue`(cdbres: CDBResult, xdbRow: ptr xdb_row_t, i: var uint16): CDBValue =
  ## Create new CDBValue of `XDB_TYPE_CHAR`
  CDBValue(kind: XDB_TYPE_CHAR, strValue: $(xdb_column_str(cdbres[].col_meta, xdbRow, i)))

proc `$int32Value`(cdbres: CDBResult, xdbRow: ptr xdb_row_t, i: var uint16): CDBValue =
  ## Create a new CDBValue of `XDB_TYPE_INT`
  CDBValue(kind: XDB_TYPE_INT, int32Value: cast[int32](xdb_column_int(cdbres[].col_meta, xdbRow, i)))

proc `$int64Value`(cdbres: CDBResult, xdbRow: ptr xdb_row_t, i: var uint16): CDBValue =
  ## Create a new CDBValue of `XDB_TYPE_BIGINT`
  CDBValue(kind: XDB_TYPE_BIGINT, int64Value: xdb_column_int64(cdbres[].col_meta, xdbRow, i))

proc `$uTinyIntValue`(cdbres: CDBResult, xdbRow: ptr xdb_row_t, i: var uint16): CDBValue =
  ## Create a new CDBValue of `XDB_TYPE_UTINYINT`
  CDBValue(kind: XDB_TYPE_UTINYINT, uTinyIntValue: cast[int8](xdb_column_int(cdbres[].col_meta, xdbRow, i)))

proc `$tinyIntValue`(cdbres: CDBResult, xdbRow: ptr xdb_row_t, i: var uint16): CDBValue =
  ## Create a new CDBValue of `XDB_TYPE_TINYINT`
  CDBValue(kind: XDB_TYPE_TINYINT, tinyIntValue: cast[int8](xdb_column_int(cdbres[].col_meta, xdbRow, i)))

proc `$uIntValue`(cdbres: CDBResult, xdbRow: ptr xdb_row_t, i: var uint16): CDBValue =
  ## Create a new CDBValue of `XDB_TYPE_UINT`
  CDBValue(kind: XDB_TYPE_UINT, uIntValue: cast[uint32](xdb_column_int(cdbres[].col_meta, xdbRow, i)))

proc `$usIntValue`(cdbres: CDBResult, xdbRow: ptr xdb_row_t, i: var uint16): CDBValue =
  ## Create a new CDBValue of `XDB_TYPE_USMALLINT`
  CDBValue(kind: XDB_TYPE_USMALLINT, usIntValue: cast[uint8](xdb_column_int(cdbres[].col_meta, xdbRow, i)))

proc `$uBigIntValue`(cdbres: CDBResult, xdbRow: ptr xdb_row_t, i: var uint16): CDBValue =
  ## Create a new CDBValue of `XDB_TYPE_UBIGINT`
  CDBValue(kind: XDB_TYPE_UBIGINT, uBigIntValue: cast[uint64](xdb_column_int(cdbres[].col_meta, xdbRow, i)))

proc `$float32Value`(cdbres: CDBResult, xdbRow: ptr xdb_row_t, i: var uint16): CDBValue =
  ## Create a new CDBValue of `XDB_TYPE_FLOAT`
  CDBValue(kind: XDB_TYPE_FLOAT, float32Value: cast[float32](xdb_column_float(cdbres[].col_meta, xdbRow, i)))

proc `$float64Value`(cdbres: CDBResult, xdbRow: ptr xdb_row_t, i: var uint16): CDBValue =
  ## Create a new CDBValue of `XDB_TYPE_DOUBLE`
  CDBValue(kind: XDB_TYPE_DOUBLE, float64Value: cast[float64](xdb_column_double(cdbres[].col_meta, xdbRow, i)))

proc `$timestampValue`(cdbres: CDBResult, xdbRow: ptr xdb_row_t, i: var uint16): CDBValue =
  ## Create a new CDBValue of `XDB_TYPE_TIMESTAMP`
  CDBValue(kind: XDB_TYPE_TIMESTAMP, timestampValue: $(xdb_column_str(cdbres[].col_meta, xdbRow, i)))

# todo support blob

proc execGet*(cdb: CDBConnection; sql: string): seq[seq[CDBValue]] =
  ## Execute SQL statement and returns rows
  let cdbres = xdb_exec(cdb, sql)
  assert cdbres[].errcode == 0
  if cdbres[].row_count > 0:
    var xdbRow: ptr xdb_row_t = cdbres.xdb_fetch_row()
    while xdbRow != nil:
      var i: uint16 = 0
      var row: seq[CDBValue]
      while i < cdbres[].col_count:
        var col: CDBValue
        let xdbColType = cdbres.getColtype(i)
        col =
          case xdbColType
          of XDB_TYPE_CHAR:      `$charValue`(cdbres, xdbRow, i)
          of XDB_TYPE_INT:       `$int32Value`(cdbres, xdbRow, i)
          of XDB_TYPE_BIGINT:    `$int64Value`(cdbres, xdbRow, i)
          of XDB_TYPE_TINYINT:   `$tinyIntValue`(cdbres, xdbRow, i)
          of XDB_TYPE_USMALLINT: `$usIntValue`(cdbres, xdbRow, i)
          of XDB_TYPE_UTINYINT:  `$uTinyintValue`(cdbres, xdbRow, i)
          of XDB_TYPE_UINT:      `$uIntValue`(cdbres, xdbRow, i)
          of XDB_TYPE_UBIGINT:   `$uBigIntValue`(cdbres, xdbRow, i)
          of XDB_TYPE_FLOAT:     `$float32Value`(cdbres, xdbRow, i)
          of XDB_TYPE_DOUBLE:    `$float64Value`(cdbres, xdbRow, i)
          of XDB_TYPE_TIMESTAMP: `$timestampValue`(cdbres, xdbRow, i)
          else: CDBValue(kind: XDB_TYPE_NULL)
        col.name = cdbres.getColname(i)
        row.add(col)
        inc i
      add result, row
      xdbRow = cdbres.xdb_fetch_row()
