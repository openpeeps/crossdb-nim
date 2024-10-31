# CrossDB - A ultra high-performance, lightweight
# embedded and server OLTP RDBMS
# https://github.com/crossdb-org/crossdb
#
# This package implements CrossDB Driver for Nim language
#
# (c) 2024 George Lemon | MIT License
#     Made by Humans from OpenPeeps
#     https://github.com/openpeeps/crossdb-nim

import std/macros

import ./crossdb/bindings
export bindings

# todo high level api