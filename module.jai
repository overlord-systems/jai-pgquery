#load "parse_tree.jai";

#if OS == .WINDOWS {
    #load "windows/windows.jai";

    #scope_module

    // pgquery relies on 'getpid' and 'strdup' from libc,
    // but the windows 'ucrt' exposes '_getpid' and '_strdup'.
    //
    // Reference: https://devblogs.microsoft.com/oldnewthing/20200730-00/?p=104021
    //
    // Windows has this magical lib called 'oldnames' that contains no
    // code, but simply remaps (for example) getpid->_getpid. It does that by
    // having the symbol 'getpid' but instead of code it tells the linker that
    // actually the name is _getpid, and so the linker starts looking for _getpid,
    // which it finally finds in ucrt/msvcrt.

    getpid :: () -> s32 #foreign oldnames;
    strdup :: (s: *u8) -> *u8 #foreign oldnames;

    // We can also use msvcrt instead of ucrt, but msvcrt is deprecated now.
    crt :: #library,system,no_dll "ucrt";
    oldnames :: #library,system,no_dll,link_always "oldnames";

} else #if OS == .MACOS {
    #load "macos/macos.jai";
} else #if OS == .LINUX {
    #load "linux/linux.jai";
}
