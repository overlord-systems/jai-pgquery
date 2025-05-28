# jai-pgquery

Jai bindings for [libpg_query](https://github.com/pganalyze/libpg_query) which gives access to the PostgreSQL parser, and returns the internal parse tree.

Currently only Windows bindings and binaries are available, but it should be easy to compile [libpg_query](https://github.com/pganalyze/libpg_query) (check their README) and then generate bindings using `jai generate.jai`.

## Usage

You can find a simple usage example in `tests/test.jai`. This test also involves using the (incomplete) typing for the parse tree, which is provided for the JSON parse tree.

If you want to generate bindings simply run `jai generate.jai`.

## Compiling

Note that on Windows to compile the main project as `x64` you need to use the `x64 Native Tools Command Promps VS XYZ`, where `XYZ` is your version of Visual Studio.
