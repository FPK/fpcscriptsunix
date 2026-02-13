# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is the **Free Pascal Compiler (FPC)** source repository. It is a self-hosting compiler supporting multiple CPU architectures operating systems. The compiler is written in Pascal and compiles itself. License: compiler is GPL v2, RTL is modified LGPL.

## Build Commands

FPC requires FPC 3.2.2 to bootstrap. This is installed on the development system. All builds use GNU Make.

### Building the compiler and the run time library

```bash
# Full bootstrap cycle: builds compiler 3 times, verifies binary identity of last two
cd compiler
make cycle

# Full cycle including all cross-compilers
make fullcycle

# Build with optimization
make cycle "OPT=-O2"
```

The cycle target: (1) compiles RTL with current compiler, (2) compiles compiler with that RTL, (3) recompiles compiler with itself, (4) diffs the last two binaries to verify consistency. If make returns 0, all good.

As FPC is very fast, it is often benefical to run make cycle instead of trying to compile single files for testing.

The Makefiles support -j.

### Building everything (compiler + RTL + packages + utils)

```bash
# From repository root - builds compiler via cycle, then RTL, packages, and utils
make all
```

### Cross-compilation

```bash
# From root or compiler directory
make all CPU_TARGET=aarch64 OS_TARGET=linux
```

### Running tests

```bash
cd tests

# Run full test suite
make full TEST_FPC=/path/to/compiler/ppcx64

# Run tests in parallel
make full TEST_FPC=/path/to/compiler/ppcx64 -j

# Run a single test (compile + execute)
make testprep TEST_FPC=/path/to/compiler/ppcx64
utils/dotest -e test/tbs/tb0001.pp

# Compile-only a single test
utils/dotest test/tbs/tb0001.pp

# View test results summary
make digest TEST_FPC=/path/to/compiler/ppcx64

# Clean between runs for same platform
make clean TEST_FPC=/path/to/compiler/ppcx64
```

## Repository Structure

```
compiler/       Compiler sources (entry point: pp.pas)
rtl/            Runtime library (platform-specific system units)
packages/       additional packages (FCL, database bindings, etc.)
tests/          Test suite, several thousands of tests
utils/          Utilities (fpdoc, h2pas, fpcmkcfg, etc.)
installer/      Installation tools
```

## Compiler Architecture

### Source organization (`compiler/`)

The compiler uses a naming convention for source files:

- **`p*.pas`** — Parser units (`parser.pas`, `pexpr.pas`, `pstatmnt.pas`, `pdecl.pas`, `ptype.pas`)
- **`n*.pas`** — Node (AST) units: `node.pas` (base), `nadd.pas` (add/compare), `nbas.pas` (basic), `ncal.pas` (calls), `ncnv.pas` (conversions), `ncon.pas` (constants), `nflw.pas` (flow control), `ninl.pas` (inline), `nld.pas` (load), `nmem.pas` (memory), `nmat.pas` (math), `nset.pas` (sets), `nobj.pas` (objects)
- **`ncg*.pas`** — Code generation for nodes: `ncgadd.pas`, `ncgbas.pas`, `ncgcal.pas`, etc. (generic CG implementations of corresponding `n*.pas`)
- **`sym*.pas`** — Symbol table: `symtable.pas`, `symbase.pas`, `symdef.pas` (type definitions), `symsym.pas` (symbols), `symtype.pas`
- **`aasm*.pas`** — Abstract assembler: `aasmbase.pas`, `aasmtai.pas` (target abstract instructions), `aasmdata.pas`, `aasmcnst.pas`
- **`ag*.pas`** — Assembler generators (output writers): `aggas.pas` (GNU as), etc.
- **`cg*.pas`** — Low-level code generator: `cgbase.pas`, `cgobj.pas`, `cgutils.pas`
- **`hlcg*.pas`** — High-level code generator: `hlcgobj.pas`, `hlcg2ll.pas`
- **`opt*.pas`** — Optimizations: `optconstprop.pas`, `optdeadstore.pas`, etc.
- **`aopt*.pas`** — Assembly-level (peephole) optimizer: `aopt.pas`, `aoptobj.pas`, `aoptbase.pas`
- **`ra*.pas`** — Inline assembler readers: `rabase.pas`, `rautils.pas`

Key standalone units: `scanner.pas` (lexer), `compiler.pas` (main interface), `verbose.pas` (messages), `switches.pas` (compiler options), `systems.pas` (target OS definitions), `assemble.pas` (external assembler invocation).

### CPU-specific code (`compiler/<cpu>/`)

Each CPU architecture has its own subdirectory (e.g., `i386/`, `x86_64/`, `aarch64/`, `arm/`, `m68k/`, `riscv64/`, `wasm32/`, `z80/`, etc.) containing:

- `cpuinfo.pas` — CPU feature definitions and capabilities
- `cgcpu.pas` — CPU-specific code generation
- `hlcgcpu.pas` — High-level CG for CPU
- `aoptcpu.pas` — CPU-specific peephole optimizations
- `racpugas.pas` — GNU assembler reader for CPU
- `agcpugas.pas` — GNU assembler output for CPU
- `*.inc` files — Instruction tables, register definitions, they are generated from the corresponding *.dat files.

Shared generators: `x86/` (shared i386/x86_64), `armgen/` (shared arm/aarch64), `ppcgen/` (shared powerpc/powerpc64), `sparcgen/` (shared sparc/sparc64).

### OS-specific code (`compiler/systems/`)

Each OS target has an `i_<os>.pas` file that registers the target and defines ABI, calling conventions, and system-specific behavior.

### Compiler pipeline

1. **Scanning** (`scanner.pas`) — Tokenization and preprocessor directives
2. **Parsing** (`parser.pas`, `p*.pas`) — Builds AST from tokens, produces node trees (`n*.pas`)
3. **Semantic analysis** — Type checking, symbol resolution (integrated into parsing via `sym*.pas`)
4. **High-level code gen** (`hlcg*.pas`) — Converts nodes to abstract instructions
5. **Low-level code gen** (`cg*.pas`, `ncg*.pas`) — Platform-specific instruction selection
6. **Optimization** (`opt*.pas`, `aopt*.pas`) — Both node-level and assembly-level
7. **Assembly output** (`aasm*.pas`, `ag*.pas`) — Emit assembler or binary
8. **Linking** — External linker invocation

### Compiler executable naming

- Native: `ppc<suffix>` (e.g., `ppc386`, `ppcx64`, `ppcarm`, `ppca64`)
- Cross: `ppcross<suffix>` (e.g., `ppcrossx64`, `ppcrossa64`)

CPU suffixes: `386` (i386), `x64` (x86_64), `arm` (arm), `a64` (aarch64), `ppc` (powerpc), `ppc64` (powerpc64), `68k` (m68k), `sparc`, `sparc64`, `mips`, `mipsel`, `8086` (i8086), `avr`, `rv32` (riscv32), `rv64` (riscv64), `jvm`, `wasm32`, `z80`, `xtensa`, `loongarch64`.

## RTL Structure (`rtl/`)

- `inc/` — Platform-independent include files (string handling, dynamic arrays, exceptions, RTTI, math, etc.)
- `<cpu>/` — CPU-specific assembler routines (e.g., `x86_64/`, `i386/`)
- `<os>/` — OS-specific system unit and syscall implementations (e.g., `linux/`, `win64/`, `darwin/`)
- Each platform combination has a `system.pp` or equivalent that is the root unit

## Test Suite (`tests/`)

### Directory structure

- `tbs/` — Integration tests (should compile/run successfully)
- `tbf/` — Integration tests (should fail to compile)
- `webtbs/` — Bug tracker tests (should compile/run successfully)
- `webtbf/` — Bug tracker tests (should fail to compile)
- `test/` — Feature/category tests (further organized into subdirectories: `cg/`, `opt/`, `packages/`, etc.)

### Test file format

Tests are `.pp` files named `t*.pp`. Directives go in comments at the top:

```pascal
{ %CPU=x86_64 }         { only run on x86_64 }
{ %TARGET=linux }        { only run on linux }
{ %OPT=-O2 }            { compile with -O2 }
{ %FAIL }               { expect compilation to fail }
{ %NORUN }              { compile only, don't execute }
{ %RESULT=1 }           { expect exit code 1 }
{ %SKIPCPU=arm }        { skip on arm }
{ %SKIPTARGET=win32 }   { skip on win32 }
{ %KNOWNRUNERROR=217 }  { known bug with exit code 217 }
```

A successful test returns exit code 0. Use `halt(1)` (or any nonzero) to signal failure.

## Makefile.fpc Format

FPC uses its own declarative `Makefile.fpc` files which are converted to GNU Makefiles via the `fpcmake` tool. Each directory with buildable sources has a `Makefile.fpc` that declares targets, dependencies, compiler options, and custom rules. The generated `Makefile` should not be edited directly.

## Notes on coding style
- do not use inline variable declarations
- use { ... } styled comments
