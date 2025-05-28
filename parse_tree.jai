/*
This is to support reading the parsed Postgres Parse Tree into Jai.

Currently, since we don't support protobuf, this is specalized for dealing
with the json parse tree format.

The issue with that is we don't have a good way of knowing the tagged union type so we have to use large structs with pointer-per-union.

We should be able to get rid of this when we support protobuf parse trees, which will also be much more efficient.
*/

pg_pt_set_stmt_type_on_tree :: (pt: *Pg_Parse_Tree) {
    if !pt return;
    for * pt.stmts pg_pt_set_stmt_type(it);
}

pg_pt_set_stmt_type :: (stmt: *Pg_Pt_Stmt) {
    if !stmt return;

    if stmt.stmt.create_stmt stmt.jai_stmt_type = .CREATE;
}

Pg_Parse_Tree :: struct {
    version: s32;
    stmts: []Pg_Pt_Stmt;
}

Pg_Pt_Stmt_Type :: enum {
    UNKNOWN;
    CREATE;
}

Pg_Pt_Stmt :: struct {
    jai_stmt_type: Pg_Pt_Stmt_Type;
    stmt: struct {
        create_stmt: *Pg_Pt_Create_Stmt; @JsonName(CreateStmt)
    };
    stmt_len: s32;
}

Pg_Pt_Create_Stmt :: struct {
    relation: Pg_Pt_Relation;
    table_elements: []Pg_Pt_Table_Element; @JsonName(tableElts)
    // @TODO: This is only used for temp tables
    on_commit: string; @JsonName(oncommit)
}

Pg_Pt_Relation :: struct {
    relname: string;
    inh: bool;
    relpersistence: string;
    location: s32;
}

Pg_Pt_Table_Element :: struct {
    col_def: Pg_Pt_Col_Def; @JsonName(ColumnDef)
}

Pg_Pt_Constraint :: struct {
    type: Pg_Pt_Constraint_Type; @JsonName(contype)
    location: s32;
}

Pg_Pt_Col_Def :: struct {
    name: string; @JsonName(colname)
    type_name: Pg_Pt_Type_Name; @JsonName(typeName)
    is_local: bool;
    constraints: []struct {
        constraint: *Pg_Pt_Constraint; @JsonName(Constraint)
    };
    location: s32;
}

Pg_Pt_Type_Name :: struct {
    names: []struct {
        string_name: *struct {
            sval: string;
        }; @JsonName(String)
    };
    type_mod: s32; @JsonName(typemod)
    location: s32;
}

Pg_Pt_Constraint_Type :: string;

// Not standard SQL; but a lot of people expect it
NULL : Pg_Pt_Constraint_Type : "NULL";
NOTNULL : Pg_Pt_Constraint_Type : "NOTNULL";
DEFAULT : Pg_Pt_Constraint_Type : "DEFAULT";
IDENTITY : Pg_Pt_Constraint_Type : "IDENTITY";
GENERATED : Pg_Pt_Constraint_Type : "GENERATED";
CHECK : Pg_Pt_Constraint_Type : "CHECK";
PRIMARY : Pg_Pt_Constraint_Type : "PRIMARY";
UNIQUE : Pg_Pt_Constraint_Type : "UNIQUE";
EXCLUSION : Pg_Pt_Constraint_Type : "EXCLUSION";
FOREIGN : Pg_Pt_Constraint_Type : "FOREIGN";

// attributes for previous constraint node
ATTR_DEFERRABLE : Pg_Pt_Constraint_Type : "ATTR_DEFERRABLE";
ATTR_NOT_DEFERRABLE : Pg_Pt_Constraint_Type : "ATTR_NOT_DEFERRABLE";
ATTR_DEFERRED : Pg_Pt_Constraint_Type : "ATTR_DEFERRED";
ATTR_IMMEDIATE : Pg_Pt_Constraint_Type : "ATTR_IMMEDIATE";
