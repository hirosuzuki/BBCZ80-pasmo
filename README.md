# BBCZ80
BBC BASIC (Z80) v5 is an implementation of the BBC BASIC programming language for the Z80 CPU.
It is largely compatible with Acorn's ARM BASIC V but with a few language extensions based on
features of 'BBC BASIC for Windows' and 'BBC BASIC for SDL 2.0'.  These extensions include the
EXIT statement, the address-of operator (^) and byte (unsigned 8-bit) variables and arrays
(& suffix character).

More details of the features added in version 5.00 can be found in the file WHATSNEW.TXT.

![Architecture](https://www.bbcbasic.co.uk/bbcbasic/z80arch.png)

The files in green constitute the generic BBC BASIC interpreter which is shared by all the
editions, it (just!) fits in 16 Kbytes so could be held in a ROM of this size.  The files in
the blue box are used to build the generic CP/M edition.  The files in the red box are used
to build the Acorn Z80 Second Processor edition.

Note that the name 'BBC BASIC' is used by permission of the British Broadcasting Corporation
and is not transferrable to a derived or forked work.

## Building with pasmo
MACRO-80 is not required; the sources can be assembled with [pasmo](https://pasmo.speccy.org/).
The build has two steps:

1. `pasmo/m80topasmo.py` converts each `src/*.Z80` module to a pasmo source `pasmo/*.asm`
   (module-local labels are prefixed with the module name).  `pasmo/BBCBASIC.asm` (CP/M) and
   `pasmo/BBCTUBE.asm` (Acorn) `INCLUDE` the modules, as pasmo has no linker.
2. pasmo assembles the result.

The generated `.asm` files are committed; do not edit them by hand.

    make          # convert + assemble: pasmo/out/BBCBASIC.COM (CP/M) and pasmo/out/BBCTUBE.COM (Acorn)
    make convert  # only src/*.Z80 -> pasmo/*.asm
    make check    # compares the results with the binaries in bin/
    make clean    # removes pasmo/out and the generated pasmo/*.asm

Without Python, the committed files can be assembled directly:

    pasmo -I pasmo --bin pasmo/BBCBASIC.asm BBCBASIC.COM
