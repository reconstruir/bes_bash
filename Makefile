TARGET = bash/bes_bash_one_file/bes_bash.bash
SOURCES := $(wildcard bash/bes_bash/bes_*.bash)
BES_BASH_MAKER = scripts/make_bes_bash.sh
RUN_TESTS_SCRIPT = scripts/run_tests.sh
TESTS := $(wildcard tests/bes_bash/test_bes_*.sh tests/bes_bash_one_file/test_bes_*.sh)

all: $(TARGET) test

test: $(TESTS) $(RUN_TESTS_SCRIPT)
	@$(RUN_TESTS_SCRIPT) $(TESTS)

$(TARGET): $(SOURCES) $(TESTS) $(BES_BASH_MAKER)
	@$(RUN_TESTS_SCRIPT) $(TESTS)
	@$(BES_BASH_MAKER) $(TARGET)

