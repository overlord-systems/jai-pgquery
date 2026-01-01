/*
This is to support reading the parsed Postgres Parse Tree into Jai.

We don't support protobuf so this might be a bit specialized for dealing with the json parse tree format.
*/

Pg_Parse_Tree :: struct {
    version: s32;
    stmts: []Pg_Pt_Stmt;
}

Pg_Pt_Stmt_Type :: enum {
    UNKNOWN;
    CREATE;
    CREATE_SCHEMA;
    DROP;
    INDEX;
    ALTER_TABLE;
    CREATE_EXTENSION;
}

Pg_Pt_Stmt :: struct {
    stmt: union {
        base_stmt: *Pg_Pt_Stmt_Base; // This is only here for convenience
        create_stmt: *Pg_Pt_Create_Stmt; @JsonName(CreateStmt)
        create_schema_stmt: *Pg_Pt_Create_Schema_Stmt; @JsonName(CreateSchemaStmt)
        drop_stmt: *Pg_Pt_Drop_Stmt; @JsonName(DropStmt)
        index_stmt: *Pg_Pt_Index_Stmt; @JsonName(IndexStmt)
        alter_table_stmt: *Pg_Pt_Alter_Table_Stmt; @JsonName(AlterTableStmt)
        create_ext_stmt: *Pg_Pt_Create_Ext_Stmt; @JsonName(CreateExtensionStmt)
    };
    stmt_len: s32;
    stmt_location: s32;
}

// All statements must embed this as the first member
Pg_Pt_Stmt_Base :: struct {
    jai_stmt_type: Pg_Pt_Stmt_Type;
}

Pg_Pt_Create_Stmt :: struct {

    using stmt_base: Pg_Pt_Stmt_Base;
    stmt_base.jai_stmt_type = .CREATE;

    relation: Pg_Pt_Relation;
    table_elements: []Pg_Pt_Table_Element; @JsonName(tableElts)

    if_not_exists: bool;

    // This is only used for temp tables
    on_commit: Pg_Pt_On_Commit_Action; @JsonName(oncommit)
}

Pg_Pt_Relation :: struct {
    catalogname: string;
    schemaname: string;
    relname: string;
    inh: bool;
    relpersistence: string;
    location: s32;
}

Pg_Pt_Table_Element :: struct {
    col_def: *Pg_Pt_Col_Def; @JsonName(ColumnDef)
    constraint: *Pg_Pt_Constraint; @JsonName(Constraint)
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

Pg_Pt_Constraint :: struct {
    type: Pg_Pt_Constraint_Type; @JsonName(contype)
    raw_expr: *Pg_Pt_Raw_Expr;

    inhcount: s32;
    location: s32;

    deferrable: bool;
    initdeferred: bool;
    skip_validation: bool;
    nulls_not_distinct: bool;

    // Foreign key related
    initially_valid: bool;
    pktable: Pg_Pt_Relation;
    pk_attrs: []struct {
        string_attr: *struct {
            sval: string;
        }; @JsonName(String)
    };
    fk_attrs: []struct {
        string_attr: *struct {
            sval: string;
        }; @JsonName(String)
    };
    keys: []struct {
        string_attr: *struct {
            sval: string;
        }; @JsonName(String)
    };
    // @TODO: Make enum
    fk_matchtype: string;
    fk_upd_action: string;
    fk_del_action: string;
}

Pg_Pt_Raw_Expr_Type :: enum {
    UNKNOWN;
    SQL_VAL_FUNC;
    A_CONST;
    FUNC_CALL;
}

Pg_Pt_Raw_Expr_Base :: struct {
    jai_raw_expr_type: Pg_Pt_Raw_Expr_Type;
}

Pg_Pt_Raw_Expr_A_Const_Type :: enum {
    UNKNOWN;
    STRING;
    INT;
    BOOL;
}

Pg_Pt_Raw_Expr_A_Const_Base :: struct {
    jai_raw_expr_a_const_type: Pg_Pt_Raw_Expr_A_Const_Type;
}

Pg_Pt_Raw_Expr :: struct {

    union {

        raw_expr_base: *Pg_Pt_Raw_Expr_Base;

        sql_val_func: *struct {

            using raw_expr_base: Pg_Pt_Raw_Expr_Base;
            raw_expr_base.jai_raw_expr_type = .SQL_VAL_FUNC;

            op: Sql_Value_Func_Op;
            type_mod: s32; @JsonName(typemod)
            location: s32;
        }; @JsonName(SQLValueFunction)

        a_const: *struct {

            using raw_expr_base: Pg_Pt_Raw_Expr_Base;
            raw_expr_base.jai_raw_expr_type = .A_CONST;

            union {

                base: *Pg_Pt_Raw_Expr_A_Const_Base;

                sval: *struct {

                    using a_const_base: Pg_Pt_Raw_Expr_A_Const_Base;
                    a_const_base.jai_raw_expr_a_const_type = .STRING;

                    sval: string;
                };

                ival: *struct {

                    using a_const_base: Pg_Pt_Raw_Expr_A_Const_Base;
                    a_const_base.jai_raw_expr_a_const_type = .INT;

                    ival: int;
                };

                boolval: *struct {

                    using a_const_base: Pg_Pt_Raw_Expr_A_Const_Base;
                    a_const_base.jai_raw_expr_a_const_type = .BOOL;

                    boolval: bool;
                };
            }

        }; @JsonName(A_Const)

        func_call: *struct {

            using raw_expr_base: Pg_Pt_Raw_Expr_Base;
            raw_expr_base.jai_raw_expr_type = .FUNC_CALL;

            funcname: []struct {
                string_val: *struct {
                    sval: string;
                }; @JsonName(String)
            };
        }; @JsonName(FuncCall)
    }

    func_format: string; @JsonName(funcformat) // @TODO: Make enum
    location: s32;
}

Pg_Pt_Create_Schema_Stmt :: struct {

    using stmt_base: Pg_Pt_Stmt_Base;
    stmt_base.jai_stmt_type = .CREATE_SCHEMA;

    schemaname: string;
    if_not_exists: bool;
}

Pg_Pt_Drop_Stmt :: struct {

    using stmt_base: Pg_Pt_Stmt_Base;
    stmt_base.jai_stmt_type = .DROP;

    objects: []struct{};
    remove_type: string; @JsonName(removeType) // @TODO: Make enum
    behavior: string; // TODO: Make enum
    missing_ok: bool;
}

Pg_Pt_Index_Stmt :: struct {

    using stmt_base: Pg_Pt_Stmt_Base;
    stmt_base.jai_stmt_type = .INDEX;

    idxname: string;
    relation: Pg_Pt_Relation;
    access_method: string; @JsonName(accessMethod) // @TODO: Make enum
    index_params: []struct {
        index_elem: *struct {
            name: string;   // column indexed
            ordering: string; // @TODO: Make enum
            nulls_ordering: string; // @TODO: Make enum
        }; @JsonName(IndexElem)
    }; @JsonName(indexParams)
}

Pg_Pt_Alter_Table_Stmt :: struct {

    using stmt_base: Pg_Pt_Stmt_Base;
    stmt_base.jai_stmt_type = .ALTER_TABLE;

    relation: Pg_Pt_Relation;
    objtype: Pg_Pt_Object_Type;
    cmds: []Pg_Pt_Alter_Table_Cmd_Base;
}

Pg_Pt_Create_Ext_Stmt :: struct {

    using stmt_base: Pg_Pt_Stmt_Base;
    stmt_base.jai_stmt_type = .CREATE_EXTENSION;

    extname: string;
    if_not_exists: bool;
}

Pg_Pt_Alter_Table_Cmd_Base :: struct {
    alter_table_cmd: *Pg_Pt_Alter_Table_Cmd_Alter_Table; @JsonName(AlterTableCmd)
}

Pg_Pt_Alter_Table_Cmd_Alter_Table :: struct {
    subtype: Pg_Pt_Alter_Table_Type;
    behavior: Pg_Pt_Drop_Behavior;
    name: string; // Used in things like name of column to be dropped
    def: struct {
        col_def: Pg_Pt_Col_Def; @JsonName(ColumnDef)
    };
}

Sql_Value_Func_Op :: string;

SVFOP_CURRENT_DATE : Sql_Value_Func_Op : "SVFOP_CURRENT_DATE";
SVFOP_CURRENT_TIME : Sql_Value_Func_Op : "SVFOP_CURRENT_TIME";
SVFOP_CURRENT_TIME_N : Sql_Value_Func_Op : "SVFOP_CURRENT_TIME_N";
SVFOP_CURRENT_TIMESTAMP : Sql_Value_Func_Op : "SVFOP_CURRENT_TIMESTAMP";
SVFOP_CURRENT_TIMESTAMP_N : Sql_Value_Func_Op : "SVFOP_CURRENT_TIMESTAMP_N";
SVFOP_LOCALTIME : Sql_Value_Func_Op : "SVFOP_LOCALTIME";
SVFOP_LOCALTIME_N : Sql_Value_Func_Op : "SVFOP_LOCALTIME_N";
SVFOP_LOCALTIMESTAMP : Sql_Value_Func_Op : "SVFOP_LOCALTIMESTAMP";
SVFOP_LOCALTIMESTAMP_N : Sql_Value_Func_Op : "SVFOP_LOCALTIMESTAMP_N";
SVFOP_CURRENT_ROLE : Sql_Value_Func_Op : "SVFOP_CURRENT_ROLE";
SVFOP_CURRENT_USER : Sql_Value_Func_Op : "SVFOP_CURRENT_USER";
SVFOP_USER : Sql_Value_Func_Op : "SVFOP_USER";
SVFOP_SESSION_USER : Sql_Value_Func_Op : "SVFOP_SESSION_USER";
SVFOP_CURRENT_CATALOG : Sql_Value_Func_Op : "SVFOP_CURRENT_CATALOG";
SVFOP_CURRENT_SCHEMA : Sql_Value_Func_Op : "SVFOP_CURRENT_SCHEMA";

Pg_Pt_Constraint_Type :: string;

// Not standard SQL; but a lot of people expect it
CONSTR_TYPE_NULL : Pg_Pt_Constraint_Type : "CONSTR_NULL";
CONSTR_TYPE_NOTNULL : Pg_Pt_Constraint_Type : "CONSTR_NOTNULL";
CONSTR_TYPE_DEFAULT : Pg_Pt_Constraint_Type : "CONSTR_DEFAULT";
CONSTR_TYPE_IDENTITY : Pg_Pt_Constraint_Type : "CONSTR_IDENTITY";
CONSTR_TYPE_GENERATED : Pg_Pt_Constraint_Type : "CONSTR_GENERATED";
CONSTR_TYPE_CHECK : Pg_Pt_Constraint_Type : "CONSTR_CHECK";
CONSTR_TYPE_PRIMARY : Pg_Pt_Constraint_Type : "CONSTR_PRIMARY";
CONSTR_TYPE_UNIQUE : Pg_Pt_Constraint_Type : "CONSTR_UNIQUE";
CONSTR_TYPE_EXCLUSION : Pg_Pt_Constraint_Type : "CONSTR_EXCLUSION";
CONSTR_TYPE_FOREIGN : Pg_Pt_Constraint_Type : "CONSTR_FOREIGN";

// attributes for previous constraint node
CONSTR_TYPE_ATTR_DEFERRABLE : Pg_Pt_Constraint_Type : "CONSTR_ATTR_DEFERRABLE";
CONSTR_TYPE_ATTR_NOT_DEFERRABLE : Pg_Pt_Constraint_Type : "CONSTR_ATTR_NOT_DEFERRABLE";
CONSTR_TYPE_ATTR_DEFERRED : Pg_Pt_Constraint_Type : "CONSTR_ATTR_DEFERRED";
CONSTR_TYPE_ATTR_IMMEDIATE : Pg_Pt_Constraint_Type : "CONSTR_ATTR_IMMEDIATE";

Pg_Pt_On_Commit_Action :: string;

ON_COMMIT_ACTION_UNKNOWN : Pg_Pt_On_Commit_Action : "ON_COMMIT_ACTION_UNDEFINED";
ON_COMMIT_ACTION_NOOP : Pg_Pt_On_Commit_Action : "ONCOMMIT_NOOP";
ON_COMMIT_ACTION_PRESERVE_ROWS : Pg_Pt_On_Commit_Action : "ONCOMMIT_PRESERVE_ROWS";
ON_COMMIT_ACTION_DELETE_ROWS : Pg_Pt_On_Commit_Action : "ONCOMMIT_DELETE_ROWS";
ON_COMMIT_ACTION_DROP : Pg_Pt_On_Commit_Action : "ONCOMMIT_DROP";

Pg_Pt_Object_Type :: string;

OBJ_TYPE_UNKNOWN : Pg_Pt_Object_Type : "OBJECT_TYPE_UNDEFINED";
OBJ_TYPE_ACCESS_METHOD : Pg_Pt_Object_Type : "OBJECT_ACCESS_METHOD";
OBJ_TYPE_AGGREGATE : Pg_Pt_Object_Type : "OBJECT_AGGREGATE";
OBJ_TYPE_AMOP : Pg_Pt_Object_Type : "OBJECT_AMOP";
OBJ_TYPE_AMPROC : Pg_Pt_Object_Type : "OBJECT_AMPROC";
OBJ_TYPE_ATTRIBUTE : Pg_Pt_Object_Type : "OBJECT_ATTRIBUTE";
OBJ_TYPE_CAST : Pg_Pt_Object_Type : "OBJECT_CAST";
OBJ_TYPE_COLUMN : Pg_Pt_Object_Type : "OBJECT_COLUMN";
OBJ_TYPE_COLLATION : Pg_Pt_Object_Type : "OBJECT_COLLATION";
OBJ_TYPE_CONVERSION : Pg_Pt_Object_Type : "OBJECT_CONVERSION";
OBJ_TYPE_DATABASE : Pg_Pt_Object_Type : "OBJECT_DATABASE";
OBJ_TYPE_DEFAULT : Pg_Pt_Object_Type : "OBJECT_DEFAULT";
OBJ_TYPE_DEFACL : Pg_Pt_Object_Type : "OBJECT_DEFACL";
OBJ_TYPE_DOMAIN : Pg_Pt_Object_Type : "OBJECT_DOMAIN";
OBJ_TYPE_DOMCONSTRAINT : Pg_Pt_Object_Type : "OBJECT_DOMCONSTRAINT";
OBJ_TYPE_EVENT_TRIGGER : Pg_Pt_Object_Type : "OBJECT_EVENT_TRIGGER";
OBJ_TYPE_EXTENSION : Pg_Pt_Object_Type : "OBJECT_EXTENSION";
OBJ_TYPE_FDW : Pg_Pt_Object_Type : "OBJECT_FDW";
OBJ_TYPE_FOREIGN_SERVER : Pg_Pt_Object_Type : "OBJECT_FOREIGN_SERVER";
OBJ_TYPE_FOREIGN_TABLE : Pg_Pt_Object_Type : "OBJECT_FOREIGN_TABLE";
OBJ_TYPE_FUNCTION : Pg_Pt_Object_Type : "OBJECT_FUNCTION";
OBJ_TYPE_INDEX : Pg_Pt_Object_Type : "OBJECT_INDEX";
OBJ_TYPE_LANGUAGE : Pg_Pt_Object_Type : "OBJECT_LANGUAGE";
OBJ_TYPE_LARGEOBJECT : Pg_Pt_Object_Type : "OBJECT_LARGEOBJECT";
OBJ_TYPE_MATVIEW : Pg_Pt_Object_Type : "OBJECT_MATVIEW";
OBJ_TYPE_OPCLASS : Pg_Pt_Object_Type : "OBJECT_OPCLASS";
OBJ_TYPE_OPERATOR : Pg_Pt_Object_Type : "OBJECT_OPERATOR";
OBJ_TYPE_OPFAMILY : Pg_Pt_Object_Type : "OBJECT_OPFAMILY";
OBJ_TYPE_PARAMETER_ACL : Pg_Pt_Object_Type : "OBJECT_PARAMETER_ACL";
OBJ_TYPE_POLICY : Pg_Pt_Object_Type : "OBJECT_POLICY";
OBJ_TYPE_PROCEDURE : Pg_Pt_Object_Type : "OBJECT_PROCEDURE";
OBJ_TYPE_PUBLICATION : Pg_Pt_Object_Type : "OBJECT_PUBLICATION";
OBJ_TYPE_PUBLICATION_NAMESPACE : Pg_Pt_Object_Type : "OBJECT_PUBLICATION_NAMESPACE";
OBJ_TYPE_PUBLICATION_REL : Pg_Pt_Object_Type : "OBJECT_PUBLICATION_REL";
OBJ_TYPE_ROLE : Pg_Pt_Object_Type : "OBJECT_ROLE";
OBJ_TYPE_ROUTINE : Pg_Pt_Object_Type : "OBJECT_ROUTINE";
OBJ_TYPE_RULE : Pg_Pt_Object_Type : "OBJECT_RULE";
OBJ_TYPE_SCHEMA : Pg_Pt_Object_Type : "OBJECT_SCHEMA";
OBJ_TYPE_SEQUENCE : Pg_Pt_Object_Type : "OBJECT_SEQUENCE";
OBJ_TYPE_SUBSCRIPTION : Pg_Pt_Object_Type : "OBJECT_SUBSCRIPTION";
OBJ_TYPE_STATISTIC_EXT : Pg_Pt_Object_Type : "OBJECT_STATISTIC_EXT";
OBJ_TYPE_TABCONSTRAINT : Pg_Pt_Object_Type : "OBJECT_TABCONSTRAINT";
OBJ_TYPE_TABLE : Pg_Pt_Object_Type : "OBJECT_TABLE";
OBJ_TYPE_TABLESPACE : Pg_Pt_Object_Type : "OBJECT_TABLESPACE";
OBJ_TYPE_TRANSFORM : Pg_Pt_Object_Type : "OBJECT_TRANSFORM";
OBJ_TYPE_TRIGGER : Pg_Pt_Object_Type : "OBJECT_TRIGGER";
OBJ_TYPE_TSCONFIGURATION : Pg_Pt_Object_Type : "OBJECT_TSCONFIGURATION";
OBJ_TYPE_TSDICTIONARY : Pg_Pt_Object_Type : "OBJECT_TSDICTIONARY";
OBJ_TYPE_TSPARSER : Pg_Pt_Object_Type : "OBJECT_TSPARSER";
OBJ_TYPE_TSTEMPLATE : Pg_Pt_Object_Type : "OBJECT_TSTEMPLATE";
OBJ_TYPE_TYPE : Pg_Pt_Object_Type : "OBJECT_TYPE";
OBJ_TYPE_USER_MAPPING : Pg_Pt_Object_Type : "OBJECT_USER_MAPPING";
OBJ_TYPE_VIEW : Pg_Pt_Object_Type : "OBJECT_VIEW";


Pg_Pt_Drop_Behavior :: string;
DROP_UNKNOWN : Pg_Pt_Drop_Behavior : "DROP_UNKNOWN";
DROP_RESTRICT : Pg_Pt_Drop_Behavior : "DROP_RESTRICT";
DROP_CASCADE : Pg_Pt_Drop_Behavior : "DROP_CASCADE";

Pg_Pt_Alter_Table_Type :: string;
ALTER_TABLE_TYPE_UNKNOWN : Pg_Pt_Alter_Table_Type : "ALTER_TABLE_TYPE_UNDEFINED";
ALTER_TABLE_TYPE_ADD_COLUMN : Pg_Pt_Alter_Table_Type : "AT_AddColumn";
ALTER_TABLE_TYPE_ADD_COLUMN_TO_VIEW : Pg_Pt_Alter_Table_Type : "AT_AddColumnToView";
ALTER_TABLE_TYPE_COLUMN_DEFAULT : Pg_Pt_Alter_Table_Type : "AT_ColumnDefault";
ALTER_TABLE_TYPE_COOKED_COLUMN_DEFAULT : Pg_Pt_Alter_Table_Type : "AT_CookedColumnDefault";
ALTER_TABLE_TYPE_DROP_NOT_NULL : Pg_Pt_Alter_Table_Type : "AT_DropNotNull";
ALTER_TABLE_TYPE_SET_NOT_NULL : Pg_Pt_Alter_Table_Type : "AT_SetNotNull";
ALTER_TABLE_TYPE_SET_EXPRESSION : Pg_Pt_Alter_Table_Type : "AT_SetExpression";
ALTER_TABLE_TYPE_DROP_EXPRESSION : Pg_Pt_Alter_Table_Type : "AT_DropExpression";
ALTER_TABLE_TYPE_CHECK_NOT_NULL : Pg_Pt_Alter_Table_Type : "AT_CheckNotNull";
ALTER_TABLE_TYPE_SET_STATISTICS : Pg_Pt_Alter_Table_Type : "AT_SetStatistics";
ALTER_TABLE_TYPE_SET_OPTIONS : Pg_Pt_Alter_Table_Type : "AT_SetOptions";
ALTER_TABLE_TYPE_RESET_OPTIONS : Pg_Pt_Alter_Table_Type : "AT_ResetOptions";
ALTER_TABLE_TYPE_SET_STORAGE : Pg_Pt_Alter_Table_Type : "AT_SetStorage";
ALTER_TABLE_TYPE_SET_COMPRESSION : Pg_Pt_Alter_Table_Type : "AT_SetCompression";
ALTER_TABLE_TYPE_DROP_COLUMN : Pg_Pt_Alter_Table_Type : "AT_DropColumn";
ALTER_TABLE_TYPE_ADD_INDEX : Pg_Pt_Alter_Table_Type : "AT_AddIndex";
ALTER_TABLE_TYPE_RE_ADD_INDEX : Pg_Pt_Alter_Table_Type : "AT_ReAddIndex";
ALTER_TABLE_TYPE_ADD_CONSTRAINT : Pg_Pt_Alter_Table_Type : "AT_AddConstraint";
ALTER_TABLE_TYPE_RE_ADD_CONSTRAINT : Pg_Pt_Alter_Table_Type : "AT_ReAddConstraint";
ALTER_TABLE_TYPE_RE_ADD_DOMAIN_CONSTRAINT : Pg_Pt_Alter_Table_Type : "AT_ReAddDomainConstraint";
ALTER_TABLE_TYPE_ALTER_CONSTRAINT : Pg_Pt_Alter_Table_Type : "AT_AlterConstraint";
ALTER_TABLE_TYPE_VALIDATE_CONSTRAINT : Pg_Pt_Alter_Table_Type : "AT_ValidateConstraint";
ALTER_TABLE_TYPE_ADD_INDEX_CONSTRAINT : Pg_Pt_Alter_Table_Type : "AT_AddIndexConstraint";
ALTER_TABLE_TYPE_DROP_CONSTRAINT : Pg_Pt_Alter_Table_Type : "AT_DropConstraint";
ALTER_TABLE_TYPE_RE_ADD_COMMENT : Pg_Pt_Alter_Table_Type : "AT_ReAddComment";
ALTER_TABLE_TYPE_ALTER_COLUMN_TYPE : Pg_Pt_Alter_Table_Type : "AT_AlterColumnType";
ALTER_TABLE_TYPE_ALTER_COLUMN_GENERIC_OPTIONS : Pg_Pt_Alter_Table_Type : "AT_AlterColumnGenericOptions";
ALTER_TABLE_TYPE_CHANGE_OWNER : Pg_Pt_Alter_Table_Type : "AT_ChangeOwner";
ALTER_TABLE_TYPE_CLUSTER_ON : Pg_Pt_Alter_Table_Type : "AT_ClusterOn";
ALTER_TABLE_TYPE_DROP_CLUSTER : Pg_Pt_Alter_Table_Type : "AT_DropCluster";
ALTER_TABLE_TYPE_SET_LOGGED : Pg_Pt_Alter_Table_Type : "AT_SetLogged";
ALTER_TABLE_TYPE_SET_UN_LOGGED : Pg_Pt_Alter_Table_Type : "AT_SetUnLogged";
ALTER_TABLE_TYPE_DROP_OIDS : Pg_Pt_Alter_Table_Type : "AT_DropOids";
ALTER_TABLE_TYPE_SET_ACCESS_METHOD : Pg_Pt_Alter_Table_Type : "AT_SetAccessMethod";
ALTER_TABLE_TYPE_SET_TABLE_SPACE : Pg_Pt_Alter_Table_Type : "AT_SetTableSpace";
ALTER_TABLE_TYPE_SET_REL_OPTIONS : Pg_Pt_Alter_Table_Type : "AT_SetRelOptions";
ALTER_TABLE_TYPE_RESET_REL_OPTIONS : Pg_Pt_Alter_Table_Type : "AT_ResetRelOptions";
ALTER_TABLE_TYPE_REPLACE_REL_OPTIONS : Pg_Pt_Alter_Table_Type : "AT_ReplaceRelOptions";
ALTER_TABLE_TYPE_ENABLE_TRIG : Pg_Pt_Alter_Table_Type : "AT_EnableTrig";
ALTER_TABLE_TYPE_ENABLE_ALWAYS_TRIG : Pg_Pt_Alter_Table_Type : "AT_EnableAlwaysTrig";
ALTER_TABLE_TYPE_ENABLE_REPLICA_TRIG : Pg_Pt_Alter_Table_Type : "AT_EnableReplicaTrig";
ALTER_TABLE_TYPE_DISABLE_TRIG : Pg_Pt_Alter_Table_Type : "AT_DisableTrig";
ALTER_TABLE_TYPE_ENABLE_TRIG_ALL : Pg_Pt_Alter_Table_Type : "AT_EnableTrigAll";
ALTER_TABLE_TYPE_DISABLE_TRIG_ALL : Pg_Pt_Alter_Table_Type : "AT_DisableTrigAll";
ALTER_TABLE_TYPE_ENABLE_TRIG_USER : Pg_Pt_Alter_Table_Type : "AT_EnableTrigUser";
ALTER_TABLE_TYPE_DISABLE_TRIG_USER : Pg_Pt_Alter_Table_Type : "AT_DisableTrigUser";
ALTER_TABLE_TYPE_ENABLE_RULE : Pg_Pt_Alter_Table_Type : "AT_EnableRule";
ALTER_TABLE_TYPE_ENABLE_ALWAYS_RULE : Pg_Pt_Alter_Table_Type : "AT_EnableAlwaysRule";
ALTER_TABLE_TYPE_ENABLE_REPLICA_RULE : Pg_Pt_Alter_Table_Type : "AT_EnableReplicaRule";
ALTER_TABLE_TYPE_DISABLE_RULE : Pg_Pt_Alter_Table_Type : "AT_DisableRule";
ALTER_TABLE_TYPE_ADD_INHERIT : Pg_Pt_Alter_Table_Type : "AT_AddInherit";
ALTER_TABLE_TYPE_DROP_INHERIT : Pg_Pt_Alter_Table_Type : "AT_DropInherit";
ALTER_TABLE_TYPE_ADD_OF : Pg_Pt_Alter_Table_Type : "AT_AddOf";
ALTER_TABLE_TYPE_DROP_OF : Pg_Pt_Alter_Table_Type : "AT_DropOf";
ALTER_TABLE_TYPE_REPLICA_IDENTITY : Pg_Pt_Alter_Table_Type : "AT_ReplicaIdentity";
ALTER_TABLE_TYPE_ENABLE_ROW_SECURITY : Pg_Pt_Alter_Table_Type : "AT_EnableRowSecurity";
ALTER_TABLE_TYPE_DISABLE_ROW_SECURITY : Pg_Pt_Alter_Table_Type : "AT_DisableRowSecurity";
ALTER_TABLE_TYPE_FORCE_ROW_SECURITY : Pg_Pt_Alter_Table_Type : "AT_ForceRowSecurity";
ALTER_TABLE_TYPE_NO_FORCE_ROW_SECURITY : Pg_Pt_Alter_Table_Type : "AT_NoForceRowSecurity";
ALTER_TABLE_TYPE_GENERIC_OPTIONS : Pg_Pt_Alter_Table_Type : "AT_GenericOptions";
ALTER_TABLE_TYPE_ATTACH_PARTITION : Pg_Pt_Alter_Table_Type : "AT_AttachPartition";
ALTER_TABLE_TYPE_DETACH_PARTITION : Pg_Pt_Alter_Table_Type : "AT_DetachPartition";
ALTER_TABLE_TYPE_DETACH_PARTITION_FINALIZE : Pg_Pt_Alter_Table_Type : "AT_DetachPartitionFinalize";
ALTER_TABLE_TYPE_ADD_IDENTITY : Pg_Pt_Alter_Table_Type : "AT_AddIdentity";
ALTER_TABLE_TYPE_SET_IDENTITY : Pg_Pt_Alter_Table_Type : "AT_SetIdentity";
ALTER_TABLE_TYPE_DROP_IDENTITY : Pg_Pt_Alter_Table_Type : "AT_DropIdentity";
ALTER_TABLE_TYPE_RE_ADD_STATISTICS : Pg_Pt_Alter_Table_Type : "AT_ReAddStatistics";
