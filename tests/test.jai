#import "Basic";
#import,file "../module.jai";

main :: () {
    Q1 :: "SELECT * FROM users";
    result := pg_query_parse(Q1);
    if result.error {
        log("failed to parse query with err = %; Query=%", result.error.*, Q1, flags=.ERROR);
        exit(1);
    }

    print("parsed query successfully. Parse tree = %\n", to_string(result.parse_tree));
}
