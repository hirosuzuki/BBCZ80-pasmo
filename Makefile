# Build BBC BASIC (Z80) with pasmo (no MACRO-80/LINK needed)
OUT = pasmo/out
SRCS = $(wildcard src/*.Z80) pasmo/build.py

all: $(OUT)/BBCBASIC.COM $(OUT)/BBCTUBE.COM

cpm: $(OUT)/BBCBASIC.COM
acorn: $(OUT)/BBCTUBE.COM

$(OUT)/BBCBASIC.COM: $(SRCS)
	python3 pasmo/build.py cpm $(OUT)

$(OUT)/BBCTUBE.COM: $(SRCS)
	python3 pasmo/build.py acorn $(OUT)

# Compare against the reference binaries in bin/
check: all
	cmp $(OUT)/BBCBASIC.COM bin/cpm/BBCBASIC.COM
	cmp $(OUT)/BBCTUBE.COM bin/acorn/BBCBASIC.COM

clean:
	rm -rf $(OUT)

.PHONY: all cpm acorn check clean
