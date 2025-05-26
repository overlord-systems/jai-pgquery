#if OS == .WINDOWS {
    #load "windows/windows.jai";

    #scope_module

    // Doing `#program_export getpid :: _getpid` does NOT work, so we
    // do a c wrapper and export it so libpg_query can see these procs
    // that it needs.

    // pgquery relies on 'getpid' and 'strdup' from libc,
    // but the windows 'ucrt' exposes '_getpid' and '_strdup'
    // so we wrap them and export the wrappers.
    _getpid :: () -> s32 #foreign crt;
    _strdup :: (s: *u8) -> *u8 #foreign crt;

    #program_export
    getpid :: () -> s32 #c_call {
        return _getpid();
    }

    #program_export
    strdup :: (s: *u8) -> *u8 #c_call {
        return _strdup(s);
    }

    // Either works, but msvcrt is deprecated
    // crt :: #library,system,no_dll "msvcrt";
    crt :: #library,system,no_dll "ucrt";

} else #if OS == .MACOS {
    #load "macos/macos.jai";
} else #if OS == .LINUX {
    #load "linux/linux.jai";
}
