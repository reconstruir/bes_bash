

# project name
TARGET = bash/bes_bash_one_file/bes_bash.bash
SOURCES := $(wildcard bash/bes_bash/bes_*.bash)
BES_BASH_MAKER = scripts/make_bes_bash.sh

all: $(TARGET)

$(TARGET): $(SOURCES) $(BES_BASH_MAKER)
	@$(BES_BASH_MAKER) $(TARGET)

