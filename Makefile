#
# Makefile for musl (requires GNU make)
#
# This is how simple every makefile should be...
# No, I take that back - actually most should be less than half this size.
#
# Use config.mak to override any of the following variables.
# Do not make changes here.
#

srcdir = .
exec_prefix = /usr/local
bindir = $(exec_prefix)/bin

prefix = /usr/local/musl
includedir = $(prefix)/include
libdir = $(prefix)/lib
syslibdir = /lib

BASE_SRCS = $(sort $(wildcard $(srcdir)/src/*/*.c $(srcdir)/arch/$(ARCH)/src/*.c))
BASE_OBJS = $(patsubst $(srcdir)/%.c,%.o,$(BASE_SRCS))
ARCH_SRCS = $(wildcard $(srcdir)/src/*/$(ARCH)/*.s $(srcdir)/src/*/$(ARCH)$(ASMSUBARCH)/*.sub)
ARCH_OBJS = $(patsubst $(srcdir)/%.sub,%.o,$(patsubst $(srcdir)/%.s,%.o,$(ARCH_SRCS)))
REPLACED_OBJS = $(sort $(subst /$(ARCH)$(ASMSUBARCH)/,/,$(subst /$(ARCH)/,/,$(ARCH_OBJS))) $(subst /$(ARCH)$(ASMSUBARCH)/,/$(ARCH)/,$(subst /$(ARCH)/,/,$(ARCH_OBJS))))
OBJS = $(addprefix obj/, $(filter-out $(REPLACED_OBJS), $(sort $(BASE_OBJS) $(ARCH_OBJS))))
LOBJS = $(OBJS:.o=.lo)
GENH = obj/include/bits/alltypes.h
GENH_INT = obj/src/internal/version.h
IMPH = $(addprefix $(srcdir)/, src/internal/stdio_impl.h src/internal/pthread_impl.h src/internal/libc.h)

LDFLAGS =
LDFLAGS_AUTO =
LIBCC = -lgcc
CPPFLAGS =
CFLAGS =
CFLAGS_AUTO = -Os -pipe
CFLAGS_C99FSE = -std=c99 -ffreestanding -nostdinc 

CFLAGS_ALL = $(CFLAGS_C99FSE)
CFLAGS_ALL += -D_XOPEN_SOURCE=700 -I$(srcdir)/arch/$(ARCH) -Iobj/src/internal -I$(srcdir)/src/internal -Iobj/include -I$(srcdir)/include
CFLAGS_ALL += $(CPPFLAGS) $(CFLAGS_AUTO) $(CFLAGS)
CFLAGS_ALL_STATIC = $(CFLAGS_ALL)
CFLAGS_ALL_SHARED = $(CFLAGS_ALL) -fPIC -DSHARED

LDFLAGS_ALL = $(LDFLAGS_AUTO) $(LDFLAGS)

AR      = $(CROSS_COMPILE)ar
RANLIB  = $(CROSS_COMPILE)ranlib
INSTALL = $(srcdir)/tools/install.sh

ARCH_INCLUDES = $(wildcard $(srcdir)/arch/$(ARCH)/bits/*.h)
INCLUDES = $(wildcard $(srcdir)/include/*.h $(srcdir)/include/*/*.h)
ALL_INCLUDES = $(sort $(INCLUDES:$(srcdir)/%=%) $(GENH:obj/%=%) $(ARCH_INCLUDES:$(srcdir)/arch/$(ARCH)/%=include/%))

EMPTY_LIB_NAMES = m rt pthread crypt util xnet resolv dl
EMPTY_LIBS = $(EMPTY_LIB_NAMES:%=lib/lib%.a)
CRT_LIBS = lib/crt1.o lib/Scrt1.o lib/rcrt1.o lib/crti.o lib/crtn.o
STATIC_LIBS = lib/libc.a
SHARED_LIBS = lib/libc.so
TOOL_LIBS = lib/musl-gcc.specs
ALL_LIBS = $(CRT_LIBS) $(STATIC_LIBS) $(SHARED_LIBS) $(EMPTY_LIBS) $(TOOL_LIBS)
ALL_TOOLS = obj/musl-gcc

WRAPCC_GCC = gcc
WRAPCC_CLANG = clang

LDSO_PATHNAME = $(syslibdir)/ld-musl-$(ARCH)$(SUBARCH).so.1

-include config.mak

ifeq ($(ARCH),)
$(error Please set ARCH in config.mak before running make.)
endif

all: $(ALL_LIBS) $(ALL_TOOLS)

OBJ_DIRS = $(sort $(patsubst %/,%,$(dir $(ALL_LIBS) $(ALL_TOOLS) $(OBJS) $(GENH) $(GENH_INT))) $(addprefix obj/, crt crt/$(ARCH) include))

$(ALL_LIBS) $(ALL_TOOLS) $(CRT_LIBS:lib/%=obj/crt/%) $(OBJS) $(LOBJS) $(GENH) $(GENH_INT): | $(OBJ_DIRS)

$(OBJ_DIRS):
	mkdir -p $@

install: install-libs install-headers install-tools

clean:
	rm -f obj/crt/*.o obj/crt/$(ARCH)/*.o
	rm -f $(OBJS)
	rm -f $(LOBJS)
	rm -f $(ALL_LIBS) lib/*.[ao] lib/*.so
	rm -f $(ALL_TOOLS)
	rm -f $(GENH) $(GENH_INT)
	rm -f obj/include/bits/alltypes.h

distclean: clean
	rm -f config.mak

obj/include/bits/alltypes.h: $(srcdir)/arch/$(ARCH)/bits/alltypes.h.in $(srcdir)/include/alltypes.h.in $(srcdir)/tools/mkalltypes.sed
	sed -f $(srcdir)/tools/mkalltypes.sed $(srcdir)/arch/$(ARCH)/bits/alltypes.h.in $(srcdir)/include/alltypes.h.in > $@

obj/src/internal/version.h: $(wildcard $(srcdir)/VERSION $(srcdir)/.git)
	printf '#define VERSION "%s"\n' "$$(cd $(srcdir); sh tools/version.sh)" > $@

obj/src/internal/version.o obj/src/internal/version.lo: obj/src/internal/version.h

obj/crt/rcrt1.o obj/src/ldso/dlstart.lo obj/src/ldso/dynlink.lo: $(srcdir)/src/internal/dynlink.h $(srcdir)/arch/$(ARCH)/reloc.h

obj/crt/crt1.o obj/crt/scrt1.o obj/crt/rcrt1.o obj/src/ldso/dlstart.lo: $(srcdir)/arch/$(ARCH)/crt_arch.h

obj/crt/rcrt1.o: $(srcdir)/src/ldso/dlstart.c

obj/crt/Scrt1.o obj/crt/rcrt1.o: CFLAGS_ALL += -fPIC

obj/crt/$(ARCH)/crti.o: $(srcdir)/crt/$(ARCH)/crti.s

obj/crt/$(ARCH)/crtn.o: $(srcdir)/crt/$(ARCH)/crtn.s

OPTIMIZE_SRCS = $(wildcard $(OPTIMIZE_GLOBS:%=$(srcdir)/src/%))
$(OPTIMIZE_SRCS:$(srcdir)/%.c=obj/%.o) $(OPTIMIZE_SRCS:$(srcdir)/%.c=obj/%.lo): CFLAGS += -O3

MEMOPS_SRCS = src/string/memcpy.c src/string/memmove.c src/string/memcmp.c src/string/memset.c
$(MEMOPS_SRCS:%.c=obj/%.o) $(MEMOPS_SRCS:%.c=obj/%.lo): CFLAGS_ALL += $(CFLAGS_MEMOPS)

NOSSP_SRCS = $(wildcard crt/*.c) \
	src/env/__libc_start_main.c src/env/__init_tls.c \
	src/thread/__set_thread_area.c src/env/__stack_chk_fail.c \
	src/string/memset.c src/string/memcpy.c \
	src/ldso/dlstart.c src/ldso/dynlink.c
$(NOSSP_SRCS:%.c=obj/%.o) $(NOSSP_SRCS:%.c=obj/%.lo): CFLAGS_ALL += $(CFLAGS_NOSSP)

$(CRT_LIBS:lib/%=obj/crt/%): CFLAGS_ALL += -DCRT

# This incantation ensures that changes to any subarch asm files will
# force the corresponding object file to be rebuilt, even if the implicit
# rule below goes indirectly through a .sub file.
define mkasmdep
$(patsubst $(srcdir)/%,obj/%,$(dir $(patsubst %/,%,$(dir $(1))))$(ARCH)$(ASMSUBARCH)/$(notdir $(1:.s=.o))): $(1)
endef
$(foreach s,$(wildcard $(srcdir)/src/*/$(ARCH)*/*.s),$(eval $(call mkasmdep,$(s))))

# Choose invocation of assembler to be used
# $(1) is input file, $(2) is output file, $(3) is assembler flags
ifeq ($(ADD_CFI),yes)
	AS_CMD = LC_ALL=C awk -f $(srcdir)/tools/add-cfi.common.awk -f $(srcdir)/tools/add-cfi.$(ARCH).awk $< | $(CC) -x assembler -c -o $@ -
else
	AS_CMD = $(CC) -c -o $@ $<
endif

obj/%.o: $(srcdir)/%.sub
	$(CC) $(CFLAGS_ALL_STATIC) -c -o $@ $(dir $<)$$(cat $<)

obj/%.o: $(srcdir)/%.s
	$(AS_CMD) $(CFLAGS_ALL_STATIC)

obj/%.o: $(srcdir)/%.c $(GENH) $(IMPH)
	$(CC) $(CFLAGS_ALL_STATIC) -c -o $@ $<

obj/%.lo: $(srcdir)/%.sub
	$(CC) $(CFLAGS_ALL_SHARED) -c -o $@ $(dir $<)$$(cat $<)

obj/%.lo: $(srcdir)/%.s
	$(AS_CMD) $(CFLAGS_ALL_SHARED)

obj/%.lo: $(srcdir)/%.c $(GENH) $(IMPH)
	$(CC) $(CFLAGS_ALL_SHARED) -c -o $@ $<

lib/libc.so: $(LOBJS)
	$(CC) $(CFLAGS_ALL_SHARED) $(LDFLAGS_ALL) -nostdlib -shared \
	-Wl,-e,_dlstart -Wl,-Bsymbolic-functions \
	-o $@ $(LOBJS) $(LIBCC)

lib/libc.a: $(OBJS)
	rm -f $@
	$(AR) rc $@ $(OBJS)
	$(RANLIB) $@

$(EMPTY_LIBS):
	rm -f $@
	$(AR) rc $@

lib/%.o: obj/crt/%.o
	cp $< $@

lib/crti.o: obj/crt/$(ARCH)/crti.o
	cp $< $@

lib/crtn.o: obj/crt/$(ARCH)/crtn.o
	cp $< $@

lib/musl-gcc.specs: $(srcdir)/tools/musl-gcc.specs.sh config.mak
	sh $< "$(includedir)" "$(libdir)" "$(LDSO_PATHNAME)" > $@

obj/musl-gcc: config.mak
	printf '#!/bin/sh\nexec "$${REALGCC:-$(WRAPCC_GCC)}" "$$@" -specs "%s/musl-gcc.specs"\n' "$(libdir)" > $@
	chmod +x $@

obj/%-clang: $(srcdir)/tools/%-clang.in config.mak
	sed -e 's!@CC@!$(WRAPCC_CLANG)!g' -e 's!@PREFIX@!$(prefix)!g' -e 's!@INCDIR@!$(includedir)!g' -e 's!@LIBDIR@!$(libdir)!g' -e 's!@LDSO@!$(LDSO_PATHNAME)!g' $< > $@
	chmod +x $@

$(DESTDIR)$(bindir)/%: obj/%
	$(INSTALL) -D $< $@

$(DESTDIR)$(libdir)/%.so: lib/%.so
	$(INSTALL) -D -m 755 $< $@

$(DESTDIR)$(libdir)/%: lib/%
	$(INSTALL) -D -m 644 $< $@

$(DESTDIR)$(includedir)/bits/%: $(srcdir)/arch/$(ARCH)/bits/%
	$(INSTALL) -D -m 644 $< $@

$(DESTDIR)$(includedir)/bits/%: obj/include/bits/%
	$(INSTALL) -D -m 644 $< $@

$(DESTDIR)$(includedir)/%: $(srcdir)/include/%
	$(INSTALL) -D -m 644 $< $@

$(DESTDIR)$(LDSO_PATHNAME): $(DESTDIR)$(libdir)/libc.so
	$(INSTALL) -D -l $(libdir)/libc.so $@ || true

install-libs: $(ALL_LIBS:lib/%=$(DESTDIR)$(libdir)/%) $(if $(SHARED_LIBS),$(DESTDIR)$(LDSO_PATHNAME),)

install-headers: $(ALL_INCLUDES:include/%=$(DESTDIR)$(includedir)/%)

install-tools: $(ALL_TOOLS:obj/%=$(DESTDIR)$(bindir)/%)

musl-git-%.tar.gz: .git
	 git --git-dir=$(srcdir)/.git archive --format=tar.gz --prefix=$(patsubst %.tar.gz,%,$@)/ -o $@ $(patsubst musl-git-%.tar.gz,%,$@)

musl-%.tar.gz: .git
	 git --git-dir=$(srcdir)/.git archive --format=tar.gz --prefix=$(patsubst %.tar.gz,%,$@)/ -o $@ v$(patsubst musl-%.tar.gz,%,$@)

.PHONY: all clean install install-libs install-headers install-tools
