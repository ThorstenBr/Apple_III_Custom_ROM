# DAN2on3: A/// ROM Makefile
# Thorsten Brehm, 2023

# assembler source
DANII_ASM_FILES    := diskio.s saratests.s monitor.s
ROMBANK0_ASM_FILES := diskio.s saratests.s disassembler.s monitor.s
ORIGINAL_ASM_FILES := diskio.s saratests.s monitor.s

# assembler output
DANII_OBJ_FILES  := $(addprefix bin-DANII/,$(DANII_ASM_FILES:.s=.o))
ROMBANK0_OBJ_FILES := $(addprefix bin-BANK0ROM/,$(ROMBANK0_ASM_FILES:.s=.o))
ORIGINAL_OBJ_FILES := $(addprefix bin-ORIGINAL/,$(ORIGINAL_ASM_FILES:.s=.o))

# output files
DANII_ROM_FILE4K := bin-DANII/A3ROM_DANII_4KB.bin
DANII_ROM_FILE8K := bin-DANII/A3ROM_DANII_EXTMONITOR_8KB.bin

ORIGINAL_ROM_FILE4K := bin-ORIGINAL/A3ROM_ORIGINAL_4KB.bin
ORIGINAL_ROM_FILE8K := bin-ORIGINAL/A3ROM_ORIGINAL_EXTMONITOR_8KB.bin

BANK0ROM_FILE4K  := bin-BANK0ROM/A3ROM_BANK0_4KB.bin
ROM_FILE8K       := bin-BANK0ROM/A3ROM_8KB.bin

A3ROMPATCHER := python3 ../../tools/A3ROMPatcher/a3rompatch.py

# Logging stuff
LOG_PREFIX := "--\> "
ECHO := @echo -e

.SILENT: all clean bin list $(DANII_ROM_FILE4K) $(DANII_ROM_FILE8K) $(BANK0ROM_FILE4K) $(ORIGINAL_ROM_FILE8K) $(ORIGINAL_ROM_FILE4K)

all: bin-DANII bin-BANK0ROM bin-ORIGINAL ../../bin $(DANII_ROM_FILE8K) $(BANK0ROM_FILE4K) $(ORIGINAL_ROM_FILE8K) $(ORIGINAL_ROM_FILE4K)

clean:
	rm -f bin-DANII/* bin-ORIGINAL/* bin-BANK0ROM/* bin-TEST/*

../../bin bin-DANII bin-BANK0ROM bin-ORIGINAL bin-TEST:
	- mkdir $@

# ROM BANK 1 VARIANT WITH DAN][ BOOTSTRAPPING
bin-DANII/%.o: %.s Makefile
	$(ECHO) "$(LOG_PREFIX) Assembling $<"
	ca65 -DDANIIBOOT -l $(@:.o=.lst) $< -o $@

$(DANII_ROM_FILE4K): $(DANII_OBJ_FILES)
	$(ECHO) "$(LOG_PREFIX) Linking $@"
	ld65 -tnone $(DANII_OBJ_FILES) -m $(@:.bin=.map) -o $@_
	$(A3ROMPATCHER) --patch $@_ 0xF6E5
	cp $@_ ../../bin/$(notdir $@)
	mv $@_ $@

$(DANII_ROM_FILE8K): $(DANII_ROM_FILE4K) $(BANK0ROM_FILE4K)
#	$(A3ROMPATCHER) --4to8k $< $@
	cat $(BANK0ROM_FILE4K) $(DANII_ROM_FILE4K) > $@
	cp $@ ../../bin/$(notdir $@)

# ROM BANK0 VARIANT WITH DISASSEMBLER
bin-BANK0ROM/%.o: %.s Makefile
	$(ECHO) "$(LOG_PREFIX) Assembling $<"
	ca65 -DBANK0ROM -l $(@:.o=.lst) $< -o $@

$(BANK0ROM_FILE4K): $(ROMBANK0_OBJ_FILES)
	$(ECHO) "$(LOG_PREFIX) Linking $@"
	ld65 -tnone $(ROMBANK0_OBJ_FILES) -m $(@:.bin=.map) -o $@_
	$(A3ROMPATCHER) --patch $@_ 0xF7FF
	mv $@_ $@

# ROM BANK 1: ORIGINAL
bin-ORIGINAL/%.o: %.s Makefile
	$(ECHO) "$(LOG_PREFIX) Assembling $<"
	ca65 -l $(@:.o=.lst) $< -o $@

$(ORIGINAL_ROM_FILE4K): $(ORIGINAL_OBJ_FILES)
	$(ECHO) "$(LOG_PREFIX) Linking $@"
	ld65 -tnone $(ORIGINAL_OBJ_FILES) -m $(@:.bin=.map) -o $@_
	cp $@_ ../../bin/$(notdir $@)
	mv $@_ $@

$(ORIGINAL_ROM_FILE8K): $(ORIGINAL_ROM_FILE4K) $(BANK0ROM_FILE4K)
	cat $(BANK0ROM_FILE4K) $(ORIGINAL_ROM_FILE4K) > $@
	cp $@ ../../bin/$(notdir $@)

# TEST
bin-TEST/%.o: %.s Makefile
	$(ECHO) "$(LOG_PREFIX) Assembling $<"
	ca65 -l $(@:.o=.lst) $< -o $@

bin-TEST/test.bin: bin-TEST/disassembler.o
	$(ECHO) "$(LOG_PREFIX) Linking $@"
	ld65 -tnone $< -m $(@:.bin=.map) -o $@

%.dump: %.bin
	hexdump -C $< > $@

%.dis: %.bin %.dump
	da65 $< > $@

dump: $(DANII_ROM_FILE4K:.bin=.dis) $(DANII_ROM_FILE8K:.bin=.dis) $(BANK0ROM_FILE4K:.bin=.dis) $(ORIGINAL_ROM_FILE8K:.bin=.dis) $(ORIGINAL_ROM_FILE4K:.bin=.dis)

diff: $(DANII_ROM_FILE4K:.bin=.dump)
	meld ../../../ROM/a3rom.dump $(DANII_ROM_FILE4K:.bin=.dump)

test: bin-TEST bin-TEST/test.bin

