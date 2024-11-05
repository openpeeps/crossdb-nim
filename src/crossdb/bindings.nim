# CrossDB - A ultra high-performance, lightweight
# embedded and server OLTP RDBMS
# https://github.com/crossdb-org/crossdb
#
# This package implements CrossDB Driver for Nim language
#
# (c) 2024 George Lemon | MIT License
#     Made by Humans from OpenPeeps
#     https://github.com/openpeeps/crossdb-nim

type
  va_list* {.importc: "va_list", header: "<stdarg.h>".} = object

{.push importc, header: "crossdb.h".}
type
  xdb_errno_e* = enum
    XDB_OK = 0
    XDB_ERROR = 1
    XDB_E_PARAM = 2
    XDB_E_STMT = 3
    XDB_E_NODB = 4
    XDB_E_NOTFOUND = 5
    XDB_E_EXISTS = 6
    XDB_E_FULL = 7
    XDB_E_CONSTRAINT = 8
    XDB_E_AUTH = 9
    XDB_E_MEMORY = 10
    XDB_E_FILE = 11
    XDB_E_SOCK = 12

  xdb_ret = int

  xdb_type_t* = enum
    XDB_TYPE_NULL       = 0 # 1 bit
    XDB_TYPE_TINYINT  = 1 # 1 byte
    XDB_TYPE_SMALLINT   = 2 # 2 bytes
    XDB_TYPE_INT        = 3 # 4 bytes
    XDB_TYPE_BIGINT     = 4 # 8 bytes
    XDB_TYPE_UTINYINT   = 5 # 1 byte
    XDB_TYPE_USMALLINT  = 6 # 2 bytes
    XDB_TYPE_UINT       = 7 # 4 bytes
    XDB_TYPE_UBIGINT    = 8 # 8 bytes
    XDB_TYPE_FLOAT      = 9 # 4 bytes
    XDB_TYPE_DOUBLE     = 10 # 8 bytes
    XDB_TYPE_TIMESTAMP  = 11 # 8 bytes
    XDB_TYPE_CHAR       = 12 # fixed-length string(at most 65535 byte)
    XDB_TYPE_BINARY     = 13 # fixed-length binary(at most 65535 byte)
    XDB_TYPE_VCHAR      = 14 # varied-length string(at most 65535 byte)
    XDB_TYPE_VBINARY    = 15 # varied-length binary(at most 65535 byte)
    # MAC,IPv4,IPv6,CIDR
    # XDB_TYPE_DECIMAL    = 16 # TBD decimal
    # XDB_TYPE_GEOMETRY   = 17 # TBD geometry
    # XDB_TYPE_JSON       = 18 # TBD json string
    # XDB_TYPE_DYNAMIC  = 20, 
    # XDB_TYPE_MAX = 21

  #
  # CrossDB Result
  #
  xdb_restype_t* = enum
    XDB_RET_ROW = 0, XDB_RET_REPLY, XDB_RET_META, XDB_RET_MSG, XDB_RET_COMPRESS, XDB_RET_INSERT, ##  (meta + row)
    XDB_RET_DELETE,           ##  (meta + row)
    XDB_RET_UPDATE,           ##  (old meta, old row, set meta, set row)
    XDB_RET_EOF = 0xF

  xdb_status_t* = enum
    XDB_STATUS_MORE_RESULTS = (1 shl 3)

  xdb_row_t* = uint64

  xdb_rowlist_t* {.bycopy.} = object
    rl_count*: uint32
    rl_curid*: uint32
    rl_pRows*: array[4096, xdb_row_t]

  xdb_res_t* {.bycopy.} = object
    len_type*: uint32
    errcode*, status*: uint16
    meta_len*: uint32
    col_count*: uint16
    stmt_type*, rsvd*: uint8
    row_count*, affected_rows*, insert_id*,
      col_meta*, row_data*, data_len*: uint64

  xdb_msg_t* {.bycopy.} = object
    ##  MSB 4bit are type
    len_type*: uint32
    `len`*: uint16
    msg*: array[2048, char]

  xdb_rowdat_t* {.bycopy.} = object
    ##  MSB 4bit are type
    len_type*: uint32
    rowdat*: UncheckedArray[uint8]

  xdb_col_t* {.bycopy.} = object
    col_len*: uint16
    ##  colum total len
    col_type*: uint8
    ##  2 xdb_type_t
    col_dtid*: uint8
    ##  3
    col_off*: uint32
    ##  4
    col_flags*: uint16
    ##  10
    col_vid*: uint16
    ##  8
    col_decimal*: uint8
    ##  12
    col_charset*: uint8
    ##  12
    col_nmlen*: uint8
    ##  13
    col_name*: UncheckedArray[char]
    ##  14

  xdb_meta_t* {.bycopy.} = object
    len_type*: uint32
    ##  MSB 4bit are type
    col_count*, col_vcount*,
      cols_off*, rsvd*: uint16
    row_size*, null_off*, rsvd2*: uint32
    col_list*, tbl_nmlen*: uint16
    tbl_name*: UncheckedArray[char]
    ## xdb_col_t  cols[];

  xdb_conn_t* = pointer
  xdb_stmt_t* = pointer

#
# Connection
#
proc xdb_open*(path: cstring): xdb_conn_t
proc xdb_connect*(host: cstring; user: cstring; pass: cstring; db: cstring;
                 port: uint16): xdb_conn_t
proc xdb_close*(pConn: xdb_conn_t)
proc xdb_curdb*(pConn: xdb_conn_t): cstring

#
# SQL
#
proc xdb_exec*(pConn: xdb_conn_t; sql: cstring): ptr xdb_res_t
proc xdb_exec2*(pConn: xdb_conn_t; sql: cstring; len: cint): ptr xdb_res_t
proc xdb_bexec*(pConn: xdb_conn_t; sql: cstring): ptr xdb_res_t {.varargs.}
proc xdb_vbexec*(pConn: xdb_conn_t; sql: cstring; ap: va_list): ptr xdb_res_t
proc xdb_pexec*(pConn: xdb_conn_t; sql: cstring): ptr xdb_res_t {.varargs.}
proc xdb_next_result*(pConn: xdb_conn_t): ptr xdb_res_t
proc xdb_more_result*(pConn: xdb_conn_t): bool
proc xdb_free_result*(pRes: ptr xdb_res_t)

#
# Result
#
proc xdb_column_meta*(meta: uint64; iCol: uint16): ptr xdb_col_t
proc xdb_column_type*(meta: uint64; iCol: uint16): xdb_type_t
proc xdb_column_name*(meta: uint64; iCol: uint16): cstring
proc xdb_fetch_row*(pRes: ptr xdb_res_t): ptr xdb_row_t
proc xdb_column_int*(meta: uint64; pRow: ptr xdb_row_t; iCol: uint16): cint
proc xdb_column_int64*(meta: uint64; pRow: ptr xdb_row_t; iCol: uint16): int64
proc xdb_column_float*(meta: uint64; pRow: ptr xdb_row_t; iCol: uint16): cfloat
proc xdb_column_double*(meta: uint64; pRow: ptr xdb_row_t; iCol: uint16): cdouble
proc xdb_column_str*(meta: uint64; pRow: ptr xdb_row_t; iCol: uint16): cstring
proc xdb_column_str2*(meta: uint64; pRow: ptr xdb_row_t; iCol: uint16;
                     pLen: ptr cint): cstring
proc xdb_column_blob*(meta: uint64; pRow: ptr xdb_row_t; iCol: uint16;
                     pLen: ptr cint): pointer
type
  xdb_row_callback* = proc (meta: uint64; pRow: ptr xdb_row_t; pArg: pointer): cint

#
# Prepared Statement
#
proc xdb_stmt_prepare*(pConn: xdb_conn_t; sql: cstring): xdb_stmt_t
proc xdb_bind_int*(pStmt: xdb_stmt_t; para_id: uint16; val: cint): xdb_ret
proc xdb_bind_int64*(pStmt: xdb_stmt_t; para_id: uint16; val: int64): xdb_ret
proc xdb_bind_float*(pStmt: xdb_stmt_t; para_id: uint16; val: cfloat): xdb_ret
proc xdb_bind_double*(pStmt: xdb_stmt_t; para_id: uint16; val: cdouble): xdb_ret
proc xdb_bind_str*(pStmt: xdb_stmt_t; para_id: uint16; str: cstring): xdb_ret
proc xdb_bind_str2*(pStmt: xdb_stmt_t; para_id: uint16; str: cstring; len: cint): xdb_ret
proc xdb_clear_bindings*(pStmt: xdb_stmt_t): xdb_ret
proc xdb_stmt_exec*(pStmt: xdb_stmt_t): ptr xdb_res_t
proc xdb_stmt_bexec*(pStmt: xdb_stmt_t): ptr xdb_res_t {.varargs.}
proc xdb_stmt_vbexec*(pStmt: xdb_stmt_t; ap: varargs[pointer]): ptr xdb_res_t
proc xdb_stmt_close*(pStmt: xdb_stmt_t)

# proc xdb_stmt_exec_cb*(pStmt: xdb_stmt_t; callback: xdb_row_callback;
#                       pArg: pointer): ptr xdb_res_t
# proc xdb_stmt_bexec_cb*(pStmt: xdb_stmt_t; callback: xdb_row_callback;
#                        pArg: pointer): ptr xdb_res_t {.varargs.}
# proc xdb_stmt_vbexec_cb*(pStmt: xdb_stmt_t; callback: xdb_row_callback;
#                         pArg: pointer; ap: va_list): ptr xdb_res_t

#
# Transaction
#
proc xdb_begin*(pConn: xdb_conn_t): xdb_ret
proc xdb_commit*(pConn: xdb_conn_t): xdb_ret
proc xdb_rollback*(pConn: xdb_conn_t): xdb_ret

#
# Misc
#
proc xdb_print_row*(meta: uint64, row: ptr xdb_row_t, format: cint): cint
{.pop.}
