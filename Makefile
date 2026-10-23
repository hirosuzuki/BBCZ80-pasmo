# Build BBC BASIC (Z80) with pasmo (no MACRO-80/LINK needed)
#
# Step 1: pasmo/m80topasmo.py converts src/*.Z80 to pasmo/*.asm
# Step 2: pasmo assembles pasmo/BBCBASIC.asm and pasmo/BBCTUBE.asm
OUT = pasmo/out
MODULES = DIST MAIN EXEC EVAL ASMB MATH HOOK CMOS ACORN AMOS DATA
ASMS = $(MODULES:%=pasmo/%.asm)

all: $(OUT)/BBCBASIC.COM $(OUT)/BBCTUBE.COM

cpm: $(OUT)/BBCBASIC.COM
acorn: $(OUT)/BBCTUBE.COM

convert: pasmo/.converted

pasmo/.converted: $(wildcard src/*.Z80) pasmo/m80topasmo.py
	python3 pasmo/m80topasmo.py
	@touch $@

$(ASMS) pasmo/BBCBASIC.asm pasmo/BBCTUBE.asm: pasmo/.converted

$(OUT)/BBCBASIC.COM: pasmo/BBCBASIC.asm $(ASMS)
	@mkdir -p $(OUT)
	pasmo -I pasmo --bin $< $@

$(OUT)/BBCTUBE.COM: pasmo/BBCTUBE.asm $(ASMS)
	@mkdir -p $(OUT)
	pasmo -I pasmo --bin $< $@

# Compare against the reference binaries in bin/ and check the committed .asm
# files are up to date
check: all
	cmp $(OUT)/BBCBASIC.COM bin/cpm/BBCBASIC.COM
	cmp $(OUT)/BBCTUBE.COM bin/acorn/BBCBASIC.COM
	git diff --exit-code -- pasmo/*.asm

# Also removes the generated .asm files; run `make convert` to regenerate them
clean:
	rm -rf $(OUT) $(ASMS) pasmo/BBCBASIC.asm pasmo/BBCTUBE.asm pasmo/.converted

.PHONY: all cpm acorn convert check clean
