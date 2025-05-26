#run build();

build :: () {

    set_build_options_dc(.{do_output=false});

    options := get_build_options();

    if !generate_bindings() {
        compiler_set_workspace_status(.FAILED);
        return;
    }
}

generate_bindings :: () -> bool {

    output_filename: string;
    opts: Generate_Bindings_Options;

    {
        opts.header = HEADER;
        opts.strip_flags &= ~.SYMBOLS_WITH_UNKNOWN_FOREIGN_LIBS;

        #if OS == .WINDOWS {

            output_filename = "windows/windows.jai";

            FOOTER :: #string EOF
#if CPU == .X64 {
    pg_query :: #library,no_dll "bin/x64/pg_query";
} else #if CPU == .ARM64 {
    #assert false "Windows ARM64 is not supported, but you might be able to compile for that!";
}
EOF
            opts.footer = FOOTER;
            opts.generate_library_declarations = false;

            #if CPU == .X64 {
                array_add(*opts.libpaths, "windows/bin/x64");
            } else {
                assert(false, "the CPU % is currently unsupported. You might be able to add support for it though!", CPU);
            }

            array_add(*opts.libnames, "pg_query");

        } else #if OS == .LINUX {
            output_filename = "linux/linux.jai";

            FOOTER :: #string EOF
pg_query :: #library,system "pg_query";
EOF;
            opts.footer = FOOTER;
            opts.generate_library_declarations = false;

            array_add(*opts.libnames, "pg_query");

        } else #if OS == .MACOS {

            output_filename = "macos/macos.jai";

            FOOTER :: #string EOF
#if CPU == .X64 {
    pg_query :: #library "bin/x64/pg_query";
} else #if CPU == .ARM64 {
    pg_query :: #library "bin/arm64/pg_query";
}
EOF;
            #if CPU == .X64 {
                array_add(*opts.libpaths, "macos/bin/x64");
            } else #if CPU == .ARM64 {
                array_add(*opts.libpaths, "macos/bin/arm64");
            } else {
                assert(false, "the CPU % is currently unsupported. You might be able to add support for it though!", CPU);
            }

            opts.footer = FOOTER;

            array_add(*opts.libnames, "pg_query");
        } else {
            assert(false, "the OS % is currently unsupported. You might be able to add support for it though!", OS);
        }

        array_add(*opts.include_paths, "include");
        array_add(*opts.source_files, "include/pg_query.h");

        opts.visitor = pg_query_visitor;
        opts.generate_compile_time_struct_checks = false;
    }

    success := generate_bindings(opts, output_filename);
    if !success return false;

    // Horrible hack because for some reason the symbols aren't found
    defer {
        if !success {
            log("failed to replace invalid library name from generated bindings at '%'. You will have to manually replace '#foreign __UnknownLib' and '#elsewhere __UnknownLib' with '#foreign pg_query' and '#elsewhere pg_query'", output_filename, flags=.ERROR);
        }
    }

    contents, success= := read_entire_file(output_filename);
    if success {
        defer free(contents);

        replace1 := replace(contents, "#foreign __UnknownLib", "#foreign pg_query");
        defer free(replace1);

        replace2 := replace(replace1, "#elsewhere __UnknownLib", "#elsewhere pg_query");
        defer free(replace2);

        success = write_entire_file(output_filename, replace2);
    }

    return success;
}

pg_query_visitor :: (decl: *Declaration, parent_decl: *Declaration) -> Declaration_Visit_Result {

    if array_find(DECLARATIONS_TO_OMIT, decl.name) {
        decl.decl_flags |= .OMIT_FROM_OUTPUT;
        return .STOP;
    }

    return .RECURSE;
}

#scope_file

#import "Basic";
#import "Compiler";
#import "BuildCpp";
#import "Check";
#import "Bindings_Generator";
#import "File";
#import "String";

DECLARATIONS_TO_OMIT :: string.[
];

HEADER :: #string EOF
EOF
