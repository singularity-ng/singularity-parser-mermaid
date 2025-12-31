# =============================================================================
# tree-sitter-mermaid - Makefile for building C library and language bindings
# =============================================================================
#
# This Makefile builds the tree-sitter-mermaid C library from the auto-generated
# parser and external scanner. It creates both static (.a) and shared (.so/.dylib)
# libraries for use in other projects.
#
# USAGE:
#   make          # Build all libraries (static + shared)
#   make test     # Run tree-sitter corpus tests
#   make install  # Install library to system (requires sudo)
#   make clean    # Remove build artifacts
#   make check-spec  # Check for new Mermaid diagram types
#
# OUTPUTS:
#   - libtree-sitter-mermaid.a        Static library
#   - libtree-sitter-mermaid.so       Shared library (Linux)
#   - libtree-sitter-mermaid.dylib    Shared library (macOS)
#   - tree-sitter-mermaid.pc          pkg-config metadata
#
# INSTALLATION:
#   Default: /usr/local/lib and /usr/local/include
#   Custom:  make install PREFIX=/opt/local
#
# DEPENDENCIES:
#   - C11 compiler (gcc, clang)
#   - tree-sitter CLI (for testing)
#   - Node.js (for generating parser from grammar.js)

# Version number (synchronized with package.json and Cargo.toml)
VERSION := 0.9.1

# Library name used for output files
LANGUAGE_NAME := tree-sitter-mermaid

# Source code directory containing parser.c and scanner.c
SRC_DIR := src

# Auto-detect repository URL from git remote
# Used in pkg-config metadata for documentation links
PARSER_REPO_URL := $(shell git -C $(SRC_DIR) remote get-url origin 2>/dev/null)

# Convert git URL to HTTPS format for pkg-config
# Handles both SSH (git@github.com:) and HTTPS formats
ifeq ($(PARSER_URL),)
	PARSER_URL := $(subst .git,,$(PARSER_REPO_URL))
ifeq ($(shell echo $(PARSER_URL) | grep '^[a-z][-+.0-9a-z]*://'),)
	PARSER_URL := $(subst :,/,$(PARSER_URL))
	PARSER_URL := $(subst git@,https://,$(PARSER_URL))
endif
endif

# Tree-sitter CLI command (can be overridden: make TS=npx tree-sitter)
TS ?= tree-sitter

# ABI versioning for shared libraries
# Extracts major and minor version numbers from VERSION
# Example: VERSION=0.25.10 → SONAME_MAJOR=0, SONAME_MINOR=25
SONAME_MAJOR := $(word 1,$(subst ., ,$(VERSION)))
SONAME_MINOR := $(word 2,$(subst ., ,$(VERSION)))

# Installation directory layout
# Can be customized: make install PREFIX=/opt/local
PREFIX ?= /usr/local
INCLUDEDIR ?= $(PREFIX)/include
LIBDIR ?= $(PREFIX)/lib
PCLIBDIR ?= $(LIBDIR)/pkgconfig

# Object files to compile (parser.o and scanner.o)
# Automatically finds all .c files in src/ directory
OBJS := $(patsubst %.c,%.o,$(wildcard $(SRC_DIR)/*.c))

# Compiler and linker flags
ARFLAGS := rcs                           # Static library archiver flags
override CFLAGS += -I$(SRC_DIR) -std=c11 -fPIC  # C11, position-independent code

# =============================================================================
# OS-specific configuration for shared library naming and linking
# =============================================================================
#
# Different operating systems use different shared library extensions and
# versioning schemes. This section handles:
#   - macOS: .dylib with install_name and rpath
#   - Linux: .so with SONAME versioning
#   - FreeBSD/NetBSD: pkg-config in libdata/pkgconfig
#
# SHARED LIBRARY VERSIONING:
#   macOS:  libtree-sitter-mermaid.0.25.dylib
#   Linux:  libtree-sitter-mermaid.so.0.25
#   Symlinks: .dylib/.so → .0.dylib/.so.0 → .0.25.dylib/.so.0.25

ifeq ($(OS),Windows_NT)
	# Windows is not currently supported (requires different build system)
	$(error "Windows is not supported")
else ifeq ($(shell uname),Darwin)
	# macOS configuration
	SOEXT = dylib                               # Shared library extension
	SOEXTVER_MAJOR = $(SONAME_MAJOR).dylib      # Major version: libfoo.0.dylib
	SOEXTVER = $(SONAME_MAJOR).$(SONAME_MINOR).dylib  # Full version: libfoo.0.25.dylib

	# Linker flags for macOS dynamic library
	LINKSHARED := $(LINKSHARED)-dynamiclib -Wl,
	ifneq ($(ADDITIONAL_LIBS),)
	LINKSHARED := $(LINKSHARED)$(ADDITIONAL_LIBS),
	endif
	# install_name: Path where library expects to be installed
	# rpath: Runtime search path relative to executable
	LINKSHARED := $(LINKSHARED)-install_name,$(LIBDIR)/lib$(LANGUAGE_NAME).$(SONAME_MAJOR).dylib,-rpath,@executable_path/../Frameworks
else
	# Linux/Unix configuration
	SOEXT = so                                  # Shared library extension
	SOEXTVER_MAJOR = so.$(SONAME_MAJOR)         # Major version: libfoo.so.0
	SOEXTVER = so.$(SONAME_MAJOR).$(SONAME_MINOR)  # Full version: libfoo.so.0.25

	# Linker flags for Linux shared object
	LINKSHARED := $(LINKSHARED)-shared -Wl,
	ifneq ($(ADDITIONAL_LIBS),)
	LINKSHARED := $(LINKSHARED)$(ADDITIONAL_LIBS)
	endif
	# SONAME: Embedded name used by dynamic linker
	LINKSHARED := $(LINKSHARED)-soname,lib$(LANGUAGE_NAME).so.$(SONAME_MAJOR)
endif

# FreeBSD/NetBSD/DragonFly use libdata/pkgconfig instead of lib/pkgconfig
ifneq ($(filter $(shell uname),FreeBSD NetBSD DragonFly),)
	PCLIBDIR := $(PREFIX)/libdata/pkgconfig
endif

# =============================================================================
# Build targets
# =============================================================================

# Default target: build all libraries and pkg-config file
all: lib$(LANGUAGE_NAME).a lib$(LANGUAGE_NAME).$(SOEXT) $(LANGUAGE_NAME).pc

# Static library (.a)
# Used for static linking into applications
lib$(LANGUAGE_NAME).a: $(OBJS)
	$(AR) $(ARFLAGS) $@ $^

# Shared library (.so or .dylib)
# Used for dynamic linking at runtime
lib$(LANGUAGE_NAME).$(SOEXT): $(OBJS)
	$(CC) $(LDFLAGS) $(LINKSHARED) $^ $(LDLIBS) -o $@
ifneq ($(STRIP),)
	# Strip debug symbols if STRIP variable is set
	$(STRIP) $@
endif

# pkg-config metadata file
# Allows other projects to find and link against this library
# Usage: pkg-config --cflags tree-sitter-mermaid
$(LANGUAGE_NAME).pc: bindings/c/$(LANGUAGE_NAME).pc.in
	sed  -e 's|@URL@|$(PARSER_URL)|' \
		-e 's|@VERSION@|$(VERSION)|' \
		-e 's|@LIBDIR@|$(LIBDIR)|' \
		-e 's|@INCLUDEDIR@|$(INCLUDEDIR)|' \
		-e 's|@REQUIRES@|$(REQUIRES)|' \
		-e 's|@ADDITIONAL_LIBS@|$(ADDITIONAL_LIBS)|' \
		-e 's|=$(PREFIX)|=$${prefix}|' \
		-e 's|@PREFIX@|$(PREFIX)|' $< > $@

# Generate parser from grammar.js
# This is the core build step that creates parser.c from the grammar definition
# Run: npm run generate (or tree-sitter generate)
$(SRC_DIR)/parser.c: grammar.js
	$(TS) generate

# Install library to system directories
# Creates symlinks for version compatibility:
#   libfoo.so → libfoo.so.0 → libfoo.so.0.25
install: all
	install -d '$(DESTDIR)$(INCLUDEDIR)'/tree_sitter '$(DESTDIR)$(PCLIBDIR)' '$(DESTDIR)$(LIBDIR)'
	install -m644 bindings/c/$(LANGUAGE_NAME).h '$(DESTDIR)$(INCLUDEDIR)'/tree_sitter/$(LANGUAGE_NAME).h
	install -m644 $(LANGUAGE_NAME).pc '$(DESTDIR)$(PCLIBDIR)'/$(LANGUAGE_NAME).pc
	install -m644 lib$(LANGUAGE_NAME).a '$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).a
	install -m755 lib$(LANGUAGE_NAME).$(SOEXT) '$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).$(SOEXTVER)
	ln -sf lib$(LANGUAGE_NAME).$(SOEXTVER) '$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).$(SOEXTVER_MAJOR)
	ln -sf lib$(LANGUAGE_NAME).$(SOEXTVER_MAJOR) '$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).$(SOEXT)

# Remove installed files
uninstall:
	$(RM) '$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).a \
		'$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).$(SOEXTVER) \
		'$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).$(SOEXTVER_MAJOR) \
		'$(DESTDIR)$(LIBDIR)'/lib$(LANGUAGE_NAME).$(SOEXT) \
		'$(DESTDIR)$(INCLUDEDIR)'/tree_sitter/$(LANGUAGE_NAME).h \
		'$(DESTDIR)$(PCLIBDIR)'/$(LANGUAGE_NAME).pc

# Remove build artifacts
clean:
	$(RM) $(OBJS) $(LANGUAGE_NAME).pc lib$(LANGUAGE_NAME).a lib$(LANGUAGE_NAME).$(SOEXT)

# Run tree-sitter corpus tests
# Tests are defined in test/corpus/*.txt
test:
	$(TS) test

# Check for new Mermaid diagram types in latest spec
# Runs check-mermaid-spec.sh to compare grammar with Mermaid.js
check-spec:
	./check-mermaid-spec.sh

# Update Rust dependencies to latest stable versions
# Always keeps dependencies up-to-date for security and performance
update-deps:
	@echo "Updating Rust dependencies to latest stable versions..."
	cargo update
	@echo "✓ Dependencies updated"

# Check for outdated dependencies (requires cargo-outdated)
# Install with: cargo install cargo-outdated
check-deps:
	@echo "Checking for outdated dependencies..."
	@command -v cargo-outdated >/dev/null 2>&1 || { \
		echo "Installing cargo-outdated..."; \
		cargo install cargo-outdated; \
	}
	cargo outdated

# Declare phony targets (not real files)
.PHONY: all install uninstall clean test check-spec update-deps check-deps
