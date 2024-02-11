# `cargo pgrx run` to run db w/ extension on :28814
# `make test` to run the tests
.PHONY: test
test:
	@psql -d pg_render -h ~/.pgrx -p 28814 -f ./test/sql/test.sql | diff - ./test/expected/test.out || (echo "Test failed" && exit 1)
