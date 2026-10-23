#!/usr/bin/env python3
"""Build BBC BASIC (Z80) with pasmo instead of MACRO80/LINK.

pasmo has no linker, so the modules are preprocessed and concatenated into a
single source file:
  * GLOBAL/EXTRN/TITLE/ASEG/CSEG/END directives are removed
  * labels that are not GLOBAL are local to their module in MACRO80, so they
    are prefixed with the module name to avoid clashes
  * GLOBAL labels that collide with pasmo reserved words get a trailing '_'
  * the DATA module (RAM variables) is turned into EQUs at the data origin

Usage: build.py cpm|acorn [outdir]
"""
import os, re, subprocess, sys

SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'src')

TARGETS = {
    # name: (output, code origin, modules in link order, data origin)
    'cpm':   ('BBCBASIC.COM', 0x200,
              ['DIST', 'MAIN', 'EXEC', 'EVAL', 'ASMB', 'MATH', 'HOOK', 'CMOS'], 0x4B00),
    'acorn': ('BBCTUBE.COM', 0x100,
              ['MAIN', 'EXEC', 'EVAL', 'ASMB', 'MATH', 'ACORN', 'AMOS'], 0x4C00),
}

RESERVED = set('''
ADC ADD AND BIT CALL CCF CP CPD CPDR CPI CPIR CPL DAA DEC DI DJNZ EI EX EXX HALT
IM IN INC IND INDR INI INIR JP JR LD LDD LDDR LDI LDIR NEG NOP OR OTDR OTIR OUT
OUTD OUTI POP PUSH RES RET RETI RETN RL RLA RLC RLCA RLD RR RRA RRC RRCA RRD RST
SBC SCF SET SLA SLL SRA SRL SUB XOR
A B C D E H L I R AF BC DE HL SP IX IY IXH IXL IYH IYL NZ Z NC PO PE P M
DEFB DEFW DEFS DEFM DEFL DB DW DS DM EQU ORG END IF ELSE ENDIF MACRO ENDM LOCAL
PROC ENDP INCLUDE INCBIN ASEG CSEG DSEG PUBLIC
MOD SHL SHR NOT HIGH LOW EQ NE LT LE GT GE
'''.split())

IDENT = re.compile(r"[A-Za-z_?@][A-Za-z0-9_?@$]*")
DROP = ('TITLE', 'GLOBAL', 'EXTRN', 'ASEG', 'CSEG', 'DSEG', 'END', 'PUBLIC', 'ERROR', '.Z80')


def split_code(line):
    """Split a line into (code, comment) honouring quoted strings."""
    i, n = 0, len(line)
    while i < n:
        c = line[i]
        if c == ';':
            return line[:i], line[i:]
        if c in '\'"':
            if c == "'" and i > 0 and line[i - 1].upper() in 'FS' and line[i - 2:i].upper() in ('AF',):
                i += 1          # AF'
                continue
            j = i + 1
            while j < n:
                if line[j] == c:
                    if j + 1 < n and line[j + 1] == c:
                        j += 2
                        continue
                    break
                j += 1
            i = j + 1
            continue
        i += 1
    return line, ''


def rename_idents(text, mapping):
    out, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        if c in '\'"':
            if c == "'" and i >= 2 and text[i - 2:i].upper() == 'AF':
                out.append(c)
                i += 1
                continue
            j = i + 1
            while j < n:
                if text[j] == c:
                    if j + 1 < n and text[j + 1] == c:
                        j += 2
                        continue
                    break
                j += 1
            out.append(text[i:j + 1])
            i = j + 1
            continue
        m = IDENT.match(text, i)
        if m and (i == 0 or not (text[i - 1].isalnum() or text[i - 1] in '_?@$')):
            w = m.group(0)
            out.append(mapping.get(w.upper(), w))
            i = m.end()
            continue
        if c.isalnum():                     # number such as 0FFH: copy whole
            m = re.compile(r"[0-9A-Za-z_$]+").match(text, i)
            out.append(m.group(0))
            i = m.end()
            continue
        out.append(c)
        i += 1
    return ''.join(out)


def parse(path):
    lines = open(path, encoding='latin-1').read().replace('\r', '').split('\n')
    glob, ext, labels = set(), set(), set()
    for ln in lines:
        code, _ = split_code(ln)
        t = code.split()
        if len(t) >= 2 and ln[:1] in ' \t' and t[0].upper() == 'GLOBAL':
            glob.add(t[1].upper())
        elif len(t) >= 2 and ln[:1] in ' \t' and t[0].upper() == 'EXTRN':
            ext.add(t[1].upper())
        elif ln[:1] not in (' ', '\t', ';', '') and ln.strip():
            m = IDENT.match(ln)
            if m:
                labels.add(m.group(0).upper())
    return lines, glob, ext, labels


def convert(mod, lines, glob, labels, allglob, data_org=None):
    mapping = {}
    for g in allglob:
        if g in RESERVED:
            mapping[g] = g + '_'
    for l in labels:
        if l not in glob:
            mapping[l] = mod + '_' + l
    out = ['; ---- %s ----' % mod]
    for ln in lines:
        code, com = split_code(ln)
        t = code.split()
        if not t:
            out.append(ln)
            continue
        label = ''
        rest = code
        if ln[0] not in ' \t' and ln[0] != ';':
            m = IDENT.match(ln)
            label = m.group(0)
            rest = code[m.end():]
            if rest.startswith(':'):
                rest = rest[1:]
        u = rest.split(None, 1)
        op = u[0].upper() if u else ''
        args = u[1] if len(u) > 1 else ''
        if op in DROP and not label:
            continue
        if op == 'IF' and False:
            pass
        if label:
            label = mapping.get(label.upper(), label)
        if op == 'DEFS' and data_org is not None:
            out.append('%s\tEQU\tDPTR%s' % (label or 'DUMMY_', com and '  ' + com))
            out.append('DPTR\tDEFL\tDPTR+(%s)' % rename_idents(args, mapping))
            continue
        if data_org is not None and op == 'END':
            out.append('%s\tEQU\tDPTR' % label)
            continue
        if op == 'END':
            if label:
                out.append('%s:' % label)
            continue
        args = rename_idents(args, mapping)
        if op in ('ADD', 'ADC', 'SBC') and ',' not in args:
            args = 'A,' + args          # MACRO80 allows the implicit accumulator
        s = (label + ':' if label else '') + ('\t' + op + ('\t' + args if args else '') if op else '')
        out.append(s + (com and '\t' + com))
    return out


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in TARGETS:
        sys.exit(__doc__)
    outname, org, mods, data_org = TARGETS[sys.argv[1]]
    outdir = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(os.path.abspath(__file__)), 'out')
    os.makedirs(outdir, exist_ok=True)
    parsed = {m: parse(os.path.join(SRC, m + '.Z80')) for m in mods + ['DATA']}
    allglob = set().union(*(p[1] for p in parsed.values()))
    out = ['; generated by pasmo/build.py -- do not edit']
    if 'DIST' in mods:
        out.append('\tORG\t100H')
    else:
        out.append('\tORG\t%04XH' % org)
    for m in mods:
        lines, glob, _, labels = parsed[m]
        if m == 'DIST':
            lines = [l for l in lines if l.split(';')[0].strip().upper() != "ERROR\t'INSUFFICIENT SPACE'"
                     and not re.match(r"\s*ERROR\s+'", l)]
            out += convert(m, lines, glob, labels, allglob)
            out.append('\tORG\t%04XH' % org)
        else:
            out += convert(m, lines, glob, labels, allglob)
    out.append('\tDEFS\t%04XH-$' % data_org)
    out.append('CODEEND:')
    out.append('DPTR\tDEFL\t%04XH' % data_org)
    lines, glob, _, labels = parsed['DATA']
    out += convert('DATA', lines, glob, labels, allglob, data_org)
    out.append('\tEND')
    asm = os.path.join(outdir, outname.split('.')[0] + '.asm')
    with open(asm, 'w', encoding='latin-1') as f:
        f.write('\n'.join(out) + '\n')
    binf = os.path.join(outdir, outname)
    r = subprocess.run(['pasmo', '--bin', asm, binf])
    if r.returncode:
        sys.exit(r.returncode)
    print('%s: %d bytes' % (binf, os.path.getsize(binf)))


if __name__ == '__main__':
    main()
