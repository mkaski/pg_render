# `cargo pgrx run pg19` to run db w/ extension on :28819
# `make test` to run the tests
PGPORT ?= 28819

.PHONY: test
test:
	@psql -d pg_render -h ~/.pgrx -p $(PGPORT) -f ./test/sql/test.sql | diff - ./test/expected/test.out || (echo "Test failed" && exit 1) && echo "Test passed"
