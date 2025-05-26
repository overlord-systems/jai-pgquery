//
// This file was auto-generated using the following command:
//
// jai generate.jai
//



PG_QUERY_PARSE_MODE_BITS :: 4;
PG_QUERY_PARSE_MODE_BITMASK :: (1 << PG_QUERY_PARSE_MODE_BITS) - 1;

PG_QUERY_DISABLE_BACKSLASH_QUOTE :: 16;
PG_QUERY_DISABLE_STANDARD_CONFORMING_STRINGS :: 32;
PG_QUERY_DISABLE_ESCAPE_STRING_WARNING :: 64;

PG_MAJORVERSION :: "17";
PG_VERSION :: "17.4";
PG_VERSION_NUM :: 170004;

PgQueryError :: struct {
    message:   *u8; // exception message
    funcname:  *u8; // source function of exception (e.g. SearchSysCache)
    filename:  *u8; // source of exception (e.g. parse.l)
    lineno:    s32; // source of exception (e.g. 104)
    cursorpos: s32; // char in query at which exception occurred
    _context:  *u8; // additional context (optional, can be NULL)
}

PgQueryProtobuf :: struct {
    len:  u64;
    data: *u8;
}

PgQueryScanResult :: struct {
    pbuf:          PgQueryProtobuf;
    stderr_buffer: *u8;
    error:         *PgQueryError;
}

PgQueryParseResult :: struct {
    parse_tree:    *u8;
    stderr_buffer: *u8;
    error:         *PgQueryError;
}

PgQueryProtobufParseResult :: struct {
    parse_tree:    PgQueryProtobuf;
    stderr_buffer: *u8;
    error:         *PgQueryError;
}

PgQuerySplitStmt :: struct {
    stmt_location: s32;
    stmt_len:      s32;
}

PgQuerySplitResult :: struct {
    stmts:         **PgQuerySplitStmt;
    n_stmts:       s32;
    stderr_buffer: *u8;
    error:         *PgQueryError;
}

PgQueryDeparseResult :: struct {
    query: *u8;
    error: *PgQueryError;
}

PgQueryPlpgsqlParseResult :: struct {
    plpgsql_funcs: *u8;
    error:         *PgQueryError;
}

PgQueryFingerprintResult :: struct {
    fingerprint:     u64;
    fingerprint_str: *u8;
    stderr_buffer:   *u8;
    error:           *PgQueryError;
}

PgQueryNormalizeResult :: struct {
    normalized_query: *u8;
    error:            *PgQueryError;
}

// Postgres parser options (parse mode and GUCs that affect parsing)
PgQueryParseMode :: enum s32 {
    DEFAULT         :: 0;
    TYPE_NAME       :: 1;
    PLPGSQL_EXPR    :: 2;
    PLPGSQL_ASSIGN1 :: 3;
    PLPGSQL_ASSIGN2 :: 4;
    PLPGSQL_ASSIGN3 :: 5;

    PG_QUERY_PARSE_DEFAULT         :: DEFAULT;
    PG_QUERY_PARSE_TYPE_NAME       :: TYPE_NAME;
    PG_QUERY_PARSE_PLPGSQL_EXPR    :: PLPGSQL_EXPR;
    PG_QUERY_PARSE_PLPGSQL_ASSIGN1 :: PLPGSQL_ASSIGN1;
    PG_QUERY_PARSE_PLPGSQL_ASSIGN2 :: PLPGSQL_ASSIGN2;
    PG_QUERY_PARSE_PLPGSQL_ASSIGN3 :: PLPGSQL_ASSIGN3;
}

pg_query_normalize :: (input: *u8) -> PgQueryNormalizeResult #foreign pg_query;
pg_query_normalize_utility :: (input: *u8) -> PgQueryNormalizeResult #foreign pg_query;
pg_query_scan :: (input: *u8) -> PgQueryScanResult #foreign pg_query;
pg_query_parse :: (input: *u8) -> PgQueryParseResult #foreign pg_query;
pg_query_parse_opts :: (input: *u8, parser_options: s32) -> PgQueryParseResult #foreign pg_query;
pg_query_parse_protobuf :: (input: *u8) -> PgQueryProtobufParseResult #foreign pg_query;
pg_query_parse_protobuf_opts :: (input: *u8, parser_options: s32) -> PgQueryProtobufParseResult #foreign pg_query;
pg_query_parse_plpgsql :: (input: *u8) -> PgQueryPlpgsqlParseResult #foreign pg_query;

pg_query_fingerprint :: (input: *u8) -> PgQueryFingerprintResult #foreign pg_query;
pg_query_fingerprint_opts :: (input: *u8, parser_options: s32) -> PgQueryFingerprintResult #foreign pg_query;

// Use pg_query_split_with_scanner when you need to split statements that may
// contain parse errors, otherwise pg_query_split_with_parser is recommended
// for improved accuracy due the parser adding additional token handling.
//
// Note that we try to support special cases like comments, strings containing
// ";" on both, as well as oddities like "CREATE RULE .. (SELECT 1; SELECT 2);"
// which is treated as as single statement.
pg_query_split_with_scanner :: (input: *u8) -> PgQuerySplitResult #foreign pg_query;
pg_query_split_with_parser :: (input: *u8) -> PgQuerySplitResult #foreign pg_query;

pg_query_deparse_protobuf :: (parse_tree: PgQueryProtobuf) -> PgQueryDeparseResult #foreign pg_query;

pg_query_free_normalize_result :: (result: PgQueryNormalizeResult) -> void #foreign pg_query;
pg_query_free_scan_result :: (result: PgQueryScanResult) -> void #foreign pg_query;
pg_query_free_parse_result :: (result: PgQueryParseResult) -> void #foreign pg_query;
pg_query_free_split_result :: (result: PgQuerySplitResult) -> void #foreign pg_query;
pg_query_free_deparse_result :: (result: PgQueryDeparseResult) -> void #foreign pg_query;
pg_query_free_protobuf_parse_result :: (result: PgQueryProtobufParseResult) -> void #foreign pg_query;
pg_query_free_plpgsql_parse_result :: (result: PgQueryPlpgsqlParseResult) -> void #foreign pg_query;
pg_query_free_fingerprint_result :: (result: PgQueryFingerprintResult) -> void #foreign pg_query;

// Optional, cleans up the top-level memory context (automatically done for threads that exit)
pg_query_exit :: () -> void #foreign pg_query;

// Deprecated APIs below
pg_query_init :: () -> void #foreign pg_query;

#scope_file

#if CPU == .X64 {
    pg_query :: #library,no_dll "bin/x64/pg_query";
} else #if CPU == .ARM64 {
    #assert false "Windows ARM64 is not supported, but you might be able to compile for that!";
}
