# DAN2on3: A/// ROM Makefile
# Thorsten Brehm, 2023

# assembler source
ASM_FILES  := diskio.s saratests.s monitor.s

# assembler output
OBJ_FILES  := $(addprefix bin/,$(ASM_FILES:.s=.o))

# output files
ROM_FILE4K := bin/A3ROM_DANII_4KB.bin
ROM_FILE8K := bin/A3ROM_DANII_8KB.bin

A3ROMPATCHER := python3 ../../tools/A3ROMPatcher/a3rompatch.py

# Logging stuff
LOG_PREFIX := "--\> "
ECHO := @echo -e

.SILENT: all clean bin list $(OBJ_FILES) $(ROM_FILE4K) $(ROM_FILE8K)

all: bin $(ROM_FILE8K)

clean:
	rm -f bin/*

bin:
	- mkdir $@

bin/%.o: %.s Makefile
	$(ECHO) "$(LOG_PREFIX) Assembling $<"
	ca65 $(VERSION_INFO) -l $(@:.o=.lst) $< -o $@

$(ROM_FILE4K): $(OBJ_FILES)
	$(ECHO) "$(LOG_PREFIX) Linking $@"
	ld65 -tnone $(OBJ_FILES) -o $@_
	$(A3ROMPATCHER) --patch $@_ 0xF6E5
	cp $@_ ../../bin/$(notdir $@)
	mv $@_ $@

$(ROM_FILE8K): $(ROM_FILE4K)
	$(A3ROMPATCHER) --4to8k $< $@
	cp $@ ../../bin/$(notdir $@)

$(ROM_FILE4K:.bin=.dump): $(ROM_FILE4K)
	hexdump -C $(ROM_FILE4K) > $@

dump: $(ROM_FILE4K:.bin=.dump)

diff: $(ROM_FILE4K:.bin=.dump)
	meld ../../../ROM/a3rom.dump $(ROM_FILE4K:.bin=.dump)
