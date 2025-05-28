#import "Basic";
#import "Jaison";
#import,file "../module.jai";
main :: () {

    // Parse a query
    Q1 :: "SELECT * FROM users";

    result := pg_query_parse(Q1);
    if result.error {
        log("failed to parse query with err = %; Query=%", result.error.*, Q1, flags=.ERROR);
        exit(1);
    }
    print("parsed query successfully. Parse tree = %\n", to_string(result.parse_tree));
    pg_query_free_parse_result(result);

    // Parse a DDL
    Q2 :: #string EOF
    CREATE TABLE users (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        age INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    EOF

    result = pg_query_parse(Q2);
    defer pg_query_free_parse_result(result);
    if result.error {
        log("failed to parse query with err = %; Query=%", result.error.*, Q2, flags=.ERROR);
        exit(1);
    }

    print("\nparsed DDL successfully. Parse tree = %\n", to_string(result.parse_tree));

    // Parse the JSON tree into a jai struct (you need the Jaison library)
    success, tree := json_parse_string(to_string(result.parse_tree), Pg_Parse_Tree);
    if !success {
        log("failed to parse JSON parse tree into jai struct", flags=.ERROR);
        exit(1);
    }
    pg_pt_set_stmt_type_on_tree(*tree);

    print("\n\njai parsed tree = %\n", tree);
}
