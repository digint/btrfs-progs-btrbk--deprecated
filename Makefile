#
# Basic build targets:
#   all		all main tools and the shared library
#   static      build static bnaries, requires static version of the libraries
#   test        run the full testsuite
#   install     install to default location (/usr/local)
#   clean       clean built binaries (not the documentation)
#   clean-all   clean as above, clean docs and generated files
#
# Tuning by variables (environment or make arguments):
#   V=1            verbose, print command lines (default: quiet)
#   C=1            run checker before compilation (default checker: sparse)
#   D=1            debugging build, turn off optimizations
#   D=dflags       dtto, turn on additional debugging features:
#                  verbose - print file:line along with error/warning messages
#                  trace   - print trace before the error/warning messages
#                  abort   - call abort() on first error (dumps core)
#                  all     - shortcut for all of the above
#                  asan    - enable address sanitizer compiler feature
#                  tsan    - enable thread sanitizer compiler feature
#                  ubsan   - undefined behaviour sanitizer compiler feature
#                  bcheck  - extended build checks
#   W=123          build with warnings (default: off)
#   DEBUG_CFLAGS   additional compiler flags for debugging build
#   EXTRA_CFLAGS   additional compiler flags
#   EXTRA_LDFLAGS  additional linker flags
#
# Testing-specific options (see also tests/README.md):
#   TEST=GLOB      run test(s) from directories matching GLOB
#   TEST_LOG=tty   print name of a command run via the execution helpers
#   TEST_LOG=dump  dump testing log file when a test fails
#
# Static checkers:
#   CHECKER        static checker binary to be called (default: sparse)
#   CHECKER_FLAGS  flags to pass to CHECKER, can override CFLAGS
#

# Export all variables to sub-makes by default
export

-include Makefile.inc
ifneq ($(MAKEFILE_INC_INCLUDED),yes)
$(error Makefile.inc not generated, please configure first)
endif

TAGS_CMD := ctags
CSCOPE_CMD := cscope -u -b -c -q

include Makefile.extrawarn

EXTRA_CFLAGS :=
EXTRA_LDFLAGS :=

DEBUG_CFLAGS_DEFAULT = -O0 -U_FORTIFY_SOURCE -ggdb3
DEBUG_CFLAGS_INTERNAL =
DEBUG_CFLAGS :=

DEBUG_LDFLAGS_DEFAULT =
DEBUG_LDFLAGS_INTERNAL =
DEBUG_LDFLAGS :=

ABSTOPDIR = $(shell pwd)
TOPDIR := .

# Common build flags
CSTD = -std=gnu90
CFLAGS = $(SUBST_CFLAGS) \
	 $(CSTD) \
	 -include config.h \
	 -DBTRFS_FLAT_INCLUDES \
	 -D_XOPEN_SOURCE=700  \
	 -fno-strict-aliasing \
	 -fPIC \
	 -I$(TOPDIR) \
	 -I$(TOPDIR)/kernel-lib \
	 -I$(TOPDIR)/libbtrfsutil \
	 $(EXTRAWARN_CFLAGS) \
	 $(DEBUG_CFLAGS_INTERNAL) \
	 $(EXTRA_CFLAGS)

LIBBTRFSUTIL_CFLAGS = $(SUBST_CFLAGS) \
		      $(CSTD) \
		      -D_GNU_SOURCE \
		      -fPIC \
		      -fvisibility=hidden \
		      -I$(TOPDIR)/libbtrfsutil \
		      $(EXTRAWARN_CFLAGS) \
		      $(EXTRA_CFLAGS)

LDFLAGS = $(SUBST_LDFLAGS) \
	  -rdynamic -L$(TOPDIR) \
	  $(DEBUG_LDFLAGS_INTERNAL) \
	  $(EXTRA_LDFLAGS)

LIBS = $(LIBS_BASE)
LIBBTRFS_LIBS = $(LIBS_BASE)

# Static compilation flags
STATIC_CFLAGS = $(CFLAGS) -ffunction-sections -fdata-sections
STATIC_LDFLAGS = -static -Wl,--gc-sections
STATIC_LIBS = $(STATIC_LIBS_BASE)

# don't use FORTIFY with sparse because glibc with FORTIFY can
# generate so many sparse errors that sparse stops parsing,
# which masks real errors that we want to see.
# Note: additional flags might get added per-target later
CHECKER := sparse
check_defs := .cc-defines.h
CHECKER_FLAGS := -include $(check_defs) -D__CHECKER__ \
	-D__CHECK_ENDIAN__ -Wbitwise -Wuninitialized -Wshadow -Wundef \
	-U_FORTIFY_SOURCE -Wdeclaration-after-statement -Wdefault-bitfield-sign

objects = ctree.o disk-io.o kernel-lib/radix-tree.o extent-tree.o print-tree.o \
	  root-tree.o dir-item.o file-item.o inode-item.o inode-map.o \
	  extent-cache.o extent_io.o volumes.o utils.o repair.o \
	  qgroup.o free-space-cache.o kernel-lib/list_sort.o props.o \
	  kernel-shared/ulist.o qgroup-verify.o backref.o string-table.o task-utils.o \
	  inode.o file.o find-root.o free-space-tree.o help.o send-dump.o \
	  fsfeatures.o kernel-lib/tables.o kernel-lib/raid56.o transaction.o
cmds_objects = cmds-subvolume.o cmds-filesystem.o cmds-device.o cmds-scrub.o \
	       cmds-inspect.o cmds-balance.o cmds-send.o cmds-receive.o \
	       cmds-quota.o cmds-qgroup.o cmds-replace.o check/main.o \
	       cmds-restore.o cmds-rescue.o chunk-recover.o super-recover.o \
	       cmds-property.o cmds-fi-usage.o cmds-inspect-dump-tree.o \
	       cmds-inspect-dump-super.o cmds-inspect-tree-stats.o cmds-fi-du.o \
	       mkfs/common.o check/mode-common.o check/mode-lowmem.o
libbtrfs_objects = send-stream.o send-utils.o kernel-lib/rbtree.o btrfs-list.o \
		   kernel-lib/crc32c.o messages.o \
		   uuid-tree.o utils-lib.o rbtree-utils.o
libbtrfs_headers = send-stream.h send-utils.h send.h kernel-lib/rbtree.h btrfs-list.h \
	       kernel-lib/crc32c.h kernel-lib/list.h kerncompat.h \
	       kernel-lib/radix-tree.h kernel-lib/sizes.h kernel-lib/raid56.h \
	       extent-cache.h extent_io.h ioctl.h ctree.h btrfsck.h version.h
libbtrfsutil_major := $(shell sed -rn 's/^\#define BTRFS_UTIL_VERSION_MAJOR ([0-9])+$$/\1/p' libbtrfsutil/btrfsutil.h)
libbtrfsutil_minor := $(shell sed -rn 's/^\#define BTRFS_UTIL_VERSION_MINOR ([0-9])+$$/\1/p' libbtrfsutil/btrfsutil.h)
libbtrfsutil_patch := $(shell sed -rn 's/^\#define BTRFS_UTIL_VERSION_PATCH ([0-9])+$$/\1/p' libbtrfsutil/btrfsutil.h)
libbtrfsutil_version := $(libbtrfsutil_major).$(libbtrfsutil_minor).$(libbtrfsutil_patch)
libbtrfsutil_objects = libbtrfsutil/errors.o libbtrfsutil/filesystem.o \
		       libbtrfsutil/subvolume.o libbtrfsutil/qgroup.o \
		       libbtrfsutil/stubs.o
convert_objects = convert/main.o convert/common.o convert/source-fs.o \
		  convert/source-ext2.o convert/source-reiserfs.o
mkfs_objects = mkfs/main.o mkfs/common.o mkfs/rootdir.o
image_objects = image/main.o image/sanitize.o
all_objects = $(objects) $(cmds_objects) $(libbtrfs_objects) $(convert_objects) \
	      $(mkfs_objects) $(image_objects) $(libbtrfsutil_objects)

udev_rules = 64-btrfs-dm.rules

ifeq ("$(origin V)", "command line")
  BUILD_VERBOSE = $(V)
endif
ifndef BUILD_VERBOSE
  BUILD_VERBOSE = 0
endif

ifeq ($(BUILD_VERBOSE),1)
  Q =
  SETUP_PY_Q =
else
  Q = @
  SETUP_PY_Q = -q
endif

ifeq ("$(origin D)", "command line")
  DEBUG_CFLAGS_INTERNAL = $(DEBUG_CFLAGS_DEFAULT) $(DEBUG_CFLAGS)
  DEBUG_LDFLAGS_INTERNAL = $(DEBUG_LDFLAGS_DEFAULT) $(DEBUG_LDFLAGS)
endif

ifneq (,$(findstring verbose,$(D)))
  DEBUG_CFLAGS_INTERNAL += -DDEBUG_VERBOSE_ERROR=1
endif

ifneq (,$(findstring trace,$(D)))
  DEBUG_CFLAGS_INTERNAL += -DDEBUG_TRACE_ON_ERROR=1
endif

ifneq (,$(findstring abort,$(D)))
  DEBUG_CFLAGS_INTERNAL += -DDEBUG_ABORT_ON_ERROR=1
endif

ifneq (,$(findstring all,$(D)))
  DEBUG_CFLAGS_INTERNAL += -DDEBUG_VERBOSE_ERROR=1
  DEBUG_CFLAGS_INTERNAL += -DDEBUG_TRACE_ON_ERROR=1
  DEBUG_CFLAGS_INTERNAL += -DDEBUG_ABORT_ON_ERROR=1
endif

ifneq (,$(findstring asan,$(D)))
  DEBUG_CFLAGS_INTERNAL += -fsanitize=address
  DEBUG_LDFLAGS_INTERNAL += -fsanitize=address -lasan
endif

ifneq (,$(findstring tsan,$(D)))
  DEBUG_CFLAGS_INTERNAL += -fsanitize=thread -fPIC
  DEBUG_LDFLAGS_INTERNAL += -fsanitize=thread -ltsan -pie
endif

ifneq (,$(findstring ubsan,$(D)))
  DEBUG_CFLAGS_INTERNAL += -fsanitize=undefined
  DEBUG_LDFLAGS_INTERNAL += -fsanitize=undefined -lubsan
endif

ifneq (,$(findstring bcheck,$(D)))
  DEBUG_CFLAGS_INTERNAL += -DDEBUG_BUILD_CHECKS
endif

MAKEOPTS = --no-print-directory Q=$(Q)

# single-command executables
progs_btrfs_command_group = btrfs-send \
	btrfs-receive \
	btrfs-subvolume-list \
	btrfs-subvolume-show \
	btrfs-subvolume-snapshot \
	btrfs-subvolume-delete \
	btrfs-filesystem-usage \
	btrfs-qgroup-destroy

# PATCH: build only separated progs
progs = $(progs_btrfs_command_group)

# install only selected
progs_install = $(progs_btrfs_command_group)

progs_extra =

progs_static = $(foreach p,$(progs),$(p).static)

progs_install_setcap = $(progs_btrfs_command_group)

# external libs required by various binaries; for btrfs-foo,
# specify btrfs_foo_libs = <list of libs>; see $($(subst...)) rules below
btrfs_convert_cflags = -DBTRFSCONVERT_EXT2=$(BTRFSCONVERT_EXT2)
btrfs_convert_cflags += -DBTRFSCONVERT_REISERFS=$(BTRFSCONVERT_REISERFS)
btrfs_fragments_libs = -lgd -lpng -ljpeg -lfreetype
btrfs_debug_tree_objects = cmds-inspect-dump-tree.o
btrfs_show_super_objects = cmds-inspect-dump-super.o
btrfs_calc_size_objects = cmds-inspect-tree-stats.o
cmds_restore_cflags = -DBTRFSRESTORE_ZSTD=$(BTRFSRESTORE_ZSTD)

CHECKER_FLAGS += $(btrfs_convert_cflags)

# single-command executables, used by btrbk backend "btrfs-progs-separated"
btrfs_send_objects = cmds-send.o
btrfs_receive_objects = cmds-receive.o
btrfs_subvolume_list_objects = cmds-subvolume.o
btrfs_subvolume_show_objects = cmds-subvolume.o
btrfs_subvolume_snapshot_objects = cmds-subvolume.o
btrfs_subvolume_delete_objects = cmds-subvolume.o
btrfs_filesystem_usage_objects = cmds-fi-usage.o
btrfs_qgroup_destroy_objects = cmds-qgroup.o

# collect values of the variables above
standalone_deps = $(foreach dep,$(patsubst %,%_objects,$(subst -,_,$(filter btrfs-%, $(progs) $(progs_extra)))),$($(dep)))

# linux capabilities (caps) needed; used by "install-setcap-%" below
install_setcap_btrfs_send = "cap_sys_admin,cap_fowner,cap_dac_read_search"
install_setcap_btrfs_receive = "cap_sys_admin,cap_fowner,cap_chown,cap_mknod,cap_setfcap,cap_dac_override,cap_dac_read_search"
install_setcap_btrfs_subvolume_list = "cap_sys_admin,cap_fowner,cap_dac_read_search"
install_setcap_btrfs_subvolume_show = "cap_sys_admin,cap_fowner,cap_dac_read_search"
install_setcap_btrfs_subvolume_snapshot = "cap_sys_admin,cap_fowner,cap_dac_override,cap_dac_read_search"
install_setcap_btrfs_subvolume_delete = "cap_sys_admin,cap_dac_override"
install_setcap_btrfs_filesystem_usage = "cap_sys_admin"
install_setcap_btrfs_qgroup_destroy = "cap_sys_admin,cap_dac_override"

SUBDIRS =
BUILDDIRS = $(patsubst %,build-%,$(SUBDIRS))
INSTALLDIRS = $(patsubst %,install-%,$(SUBDIRS))
CLEANDIRS = $(patsubst %,clean-%,$(SUBDIRS))

ifneq ($(DISABLE_DOCUMENTATION),1)
BUILDDIRS += build-Documentation
INSTALLDIRS += install-Documentation
endif

.PHONY: $(SUBDIRS)
.PHONY: $(BUILDDIRS)
.PHONY: $(INSTALLDIRS)
.PHONY: $(TESTDIRS)
.PHONY: $(CLEANDIRS)
.PHONY: all install clean
.PHONY: FORCE

# Create all the static targets
static_objects = $(patsubst %.o, %.static.o, $(objects))
static_cmds_objects = $(patsubst %.o, %.static.o, $(cmds_objects))
static_libbtrfs_objects = $(patsubst %.o, %.static.o, $(libbtrfs_objects))
static_convert_objects = $(patsubst %.o, %.static.o, $(convert_objects))
static_mkfs_objects = $(patsubst %.o, %.static.o, $(mkfs_objects))
static_image_objects = $(patsubst %.o, %.static.o, $(image_objects))

libs_shared = libbtrfs.so.0.1 libbtrfsutil.so.$(libbtrfsutil_version)
libs_static = libbtrfs.a libbtrfsutil.a
libs = $(libs_shared) $(libs_static)
lib_links = libbtrfs.so.0 libbtrfs.so libbtrfsutil.so.$(libbtrfsutil_major) libbtrfsutil.so

# make C=1 to enable sparse
ifdef C
	# We're trying to use sparse against glibc headers which go wild
	# trying to use internal compiler macros to test features.  We
	# copy gcc's and give them to sparse.  But not __SIZE_TYPE__
	# 'cause sparse defines that one.
	#
	dummy := $(shell $(CC) -dM -E -x c - < /dev/null | \
			grep -v __SIZE_TYPE__ > $(check_defs))
	check = $(CHECKER)
	check_echo = echo
	CSTD = -std=gnu89
else
	check = true
	check_echo = true
endif

%.o.d: %.c
	$(Q)$(CC) -MM -MG -MF $@ -MT $(@:.o.d=.o) -MT $(@:.o.d=.static.o) -MT $@ $(CFLAGS) $<

#
# Pick from per-file variables, btrfs_*_cflags
#
.c.o:
	@$(check_echo) "    [SP]     $<"
	$(Q)$(check) $(CFLAGS) $(CHECKER_FLAGS) $<
	@echo "    [CC]     $@"
	$(Q)$(CC) $(CFLAGS) -c $< -o $@ $($(subst -,_,$(@:%.o=%)-cflags)) \
		$($(subst -,_,btrfs-$(@:%/$(notdir $@)=%)-cflags))

%.static.o: %.c
	@echo "    [CC]     $@"
	$(Q)$(CC) $(STATIC_CFLAGS) -c $< -o $@ $($(subst -,_,$(@:%.static.o=%)-cflags)) \
		$($(subst -,_,btrfs-$(@:%/$(notdir $@)=%)-cflags))

all: $(progs) $(libs) $(lib_links) $(BUILDDIRS)
ifeq ($(PYTHON_BINDINGS),1)
all: libbtrfsutil_python
endif
$(SUBDIRS): $(BUILDDIRS)
$(BUILDDIRS):
	@echo "Making all in $(patsubst build-%,%,$@)"
	$(Q)$(MAKE) $(MAKEOPTS) -C $(patsubst build-%,%,$@)

test-convert: btrfs btrfs-convert
	@echo "    [TEST]   convert-tests.sh"
	$(Q)bash tests/convert-tests.sh

test-check: test-fsck
test-fsck: btrfs btrfs-image btrfs-corrupt-block mkfs.btrfs btrfstune
	@echo "    [TEST]   fsck-tests.sh"
	$(Q)bash tests/fsck-tests.sh

test-misc: btrfs btrfs-image btrfs-corrupt-block mkfs.btrfs btrfstune fssum \
		btrfs-zero-log btrfs-find-root btrfs-select-super btrfs-convert
	@echo "    [TEST]   misc-tests.sh"
	$(Q)bash tests/misc-tests.sh

test-mkfs: btrfs mkfs.btrfs
	@echo "    [TEST]   mkfs-tests.sh"
	$(Q)bash tests/mkfs-tests.sh

test-fuzz: btrfs btrfs-image
	@echo "    [TEST]   fuzz-tests.sh"
	$(Q)bash tests/fuzz-tests.sh

test-cli: btrfs mkfs.btrfs
	@echo "    [TEST]   cli-tests.sh"
	$(Q)bash tests/cli-tests.sh

test-clean:
	@echo "Cleaning tests"
	$(Q)bash tests/clean-tests.sh

test-inst: all
	@tmpdest=`mktemp --tmpdir -d btrfs-inst.XXXXXX` && \
		echo "Test installation to $$tmpdest" && \
		$(MAKE) $(MAKEOPTS) DESTDIR=$$tmpdest install && \
		$(RM) -rf -- $$tmpdest

test: test-fsck test-mkfs test-misc test-cli test-convert test-fuzz

testsuite: btrfs-corrupt-block fssum
	@echo "Export tests as a package"
	$(Q)cd tests && ./export-testsuite.sh

ifeq ($(PYTHON_BINDINGS),1)
test-libbtrfsutil: libbtrfsutil_python mkfs.btrfs
	$(Q)cd libbtrfsutil/python; \
		LD_LIBRARY_PATH=../.. $(PYTHON) -m unittest discover -v tests

.PHONY: test-libbtrfsutil

test: test-libbtrfsutil
endif

#
# NOTE: For static compiles, you need to have all the required libs
# 	static equivalent available
#
static: $(progs_static)

version.h: version.h.in configure.ac
	@echo "    [SH]     $@"
	$(Q)bash ./config.status --silent $@

mktables: kernel-lib/mktables.c
	@echo "    [CC]     $@"
	$(Q)$(CC) $(CFLAGS) $< -o $@

# the target can be regenerated manually using mktables, but a local copy is
# kept so the build process is simpler
kernel-lib/tables.c:
	@echo "    [TABLE]  $@"
	$(Q)./mktables > $@ || ($(RM) -f $@ && exit 1)

libbtrfs.so.0.1: $(libbtrfs_objects)
	@echo "    [LD]     $@"
	$(Q)$(CC) $(CFLAGS) $^ $(LDFLAGS) $(LIBBTRFS_LIBS) \
		-shared -Wl,-soname,libbtrfs.so.0 -o $@

libbtrfs.a: $(libbtrfs_objects)
	@echo "    [AR]     $@"
	$(Q)$(AR) cr $@ $^

libbtrfs.so.0 libbtrfs.so: libbtrfs.so.0.1
	@echo "    [LN]     $@"
	$(Q)$(LN_S) -f $< $@

libbtrfsutil/%.o: libbtrfsutil/%.c
	@echo "    [CC]     $@"
	$(Q)$(CC) $(LIBBTRFSUTIL_CFLAGS) -o $@ -c $< -o $@

libbtrfsutil.so.$(libbtrfsutil_version): $(libbtrfsutil_objects)
	@echo "    [LD]     $@"
	$(Q)$(CC) $(LIBBTRFSUTIL_CFLAGS) $(libbtrfsutil_objects) \
		-shared -Wl,-soname,libbtrfsutil.so.$(libbtrfsutil_major) -o $@

libbtrfsutil.a: $(libbtrfsutil_objects)
	@echo "    [AR]     $@"
	$(Q)$(AR) cr $@ $^

libbtrfsutil.so.$(libbtrfsutil_major) libbtrfsutil.so: libbtrfsutil.so.$(libbtrfsutil_version)
	@echo "    [LN]     $@"
	$(Q)$(LN_S) -f $< $@

ifeq ($(PYTHON_BINDINGS),1)
libbtrfsutil_python: libbtrfsutil.so.$(libbtrfsutil_major) libbtrfsutil.so libbtrfsutil/btrfsutil.h
	@echo "    [PY]     libbtrfsutil"
	$(Q)cd libbtrfsutil/python; \
		CFLAGS= LDFLAGS= $(PYTHON) setup.py $(SETUP_PY_Q) build_ext -i build

.PHONY: libbtrfsutil_python
endif

# keep intermediate files from the below implicit rules around
.PRECIOUS: $(addsuffix .o,$(progs))

# Make any btrfs-foo out of btrfs-foo.o, with appropriate libs.
# The $($(subst...)) bits below takes the btrfs_*_libs definitions above and
# turns them into a list of libraries to link against if they exist
#
# For static variants, use an extra $(subst) to get rid of the ".static"
# from the target name before translating to list of libs

btrfs-%.static: btrfs-%.static.o $(static_objects) $(patsubst %.o,%.static.o,$(standalone_deps)) $(static_libbtrfs_objects)
	@echo "    [LD]     $@"
	$(Q)$(CC) -o $@ $@.o $(static_objects) \
		$(patsubst %.o, %.static.o, $($(subst -,_,$(subst .static,,$@)-objects))) \
		$(static_libbtrfs_objects) $(STATIC_LDFLAGS) \
		$($(subst -,_,$(subst .static,,$@)-libs)) $(STATIC_LIBS)

btrfs-%: btrfs-%.o $(objects) $(standalone_deps) $(libs_static)
	@echo "    [LD]     $@"
	$(Q)$(CC) -o $@ $(objects) $@.o \
		$($(subst -,_,$@-objects)) \
		$(libs_static) \
		$(LDFLAGS) $(LIBS) $($(subst -,_,$@-libs))

btrfs: btrfs.o $(objects) $(cmds_objects) $(libs_static)
	@echo "    [LD]     $@"
	$(Q)$(CC) -o $@ $^ $(LDFLAGS) $(LIBS) $(LIBS_COMP)

btrfs.static: btrfs.static.o $(static_objects) $(static_cmds_objects) $(static_libbtrfs_objects)
	@echo "    [LD]     $@"
	$(Q)$(CC) -o $@ $^ $(STATIC_LDFLAGS) $(STATIC_LIBS) $(STATIC_LIBS_COMP)

# For backward compatibility, 'btrfs' changes behaviour to fsck if it's named 'btrfsck'
btrfsck: btrfs
	@echo "    [LN]     $@"
	$(Q)$(LN_S) -f btrfs btrfsck

btrfsck.static: btrfs.static
	@echo "    [LN]     $@"
	$(Q)$(LN_S) -f $^ $@

mkfs.btrfs: $(mkfs_objects) $(objects) $(libs_static)
	@echo "    [LD]     $@"
	$(Q)$(CC) -o $@ $^ $(LDFLAGS) $(LIBS)

mkfs.btrfs.static: $(static_mkfs_objects) $(static_objects) $(static_libbtrfs_objects)
	@echo "    [LD]     $@"
	$(Q)$(CC) -o $@ $^ $(STATIC_LDFLAGS) $(STATIC_LIBS)

btrfstune: btrfstune.o $(objects) $(libs_static)
	@echo "    [LD]     $@"
	$(Q)$(CC) -o $@ $^ $(LDFLAGS) $(LIBS)

btrfstune.static: btrfstune.static.o $(static_objects) $(static_libbtrfs_objects)
	@echo "    [LD]     $@"
	$(Q)$(CC) -o $@ $^ $(STATIC_LDFLAGS) $(STATIC_LIBS)

btrfs-image: $(image_objects) $(objects) $(libs_static)
	@echo "    [LD]     $@"
	$(Q)$(CC) -o $@ $^ $(LDFLAGS) $(LIBS) $(LIBS_COMP)

btrfs-image.static: $(static_image_objects) $(static_objects) $(static_libbtrfs_objects)
	@echo "    [LD]     $@"
	$(Q)$(CC) -o $@ $^ $(STATIC_LDFLAGS) $(STATIC_LIBS) $(STATIC_LIBS_COMP)

btrfs-convert: $(convert_objects) $(objects) $(libs_static)
	@echo "    [LD]     $@"
	$(Q)$(CC) -o $@ $^ $(LDFLAGS) $(btrfs_convert_libs) $(LIBS)

btrfs-convert.static: $(static_convert_objects) $(static_objects) $(static_libbtrfs_objects)
	@echo "    [LD]     $@"
	$(Q)$(CC) -o $@ $^ $(STATIC_LDFLAGS) $(btrfs_convert_libs) $(STATIC_LIBS)

dir-test: dir-test.o $(objects) $(libs)
	@echo "    [LD]     $@"
	$(Q)$(CC) -o $@ $^ $(LDFLAGS) $(LIBS)

quick-test: quick-test.o $(objects) $(libs)
	@echo "    [LD]     $@"
	$(Q)$(CC) -o $@ $^ $(LDFLAGS) $(LIBS)

ioctl-test.o: ioctl-test.c ioctl.h kerncompat.h ctree.h
	@echo "    [CC]   $@"
	$(Q)$(CC) $(CFLAGS) -c $< -o $@

ioctl-test-32.o: ioctl-test.c ioctl.h kerncompat.h ctree.h
	@echo "    [CC32]   $@"
	$(Q)$(CC) $(CFLAGS) -m32 -c $< -o $@

ioctl-test-64.o: ioctl-test.c ioctl.h kerncompat.h ctree.h
	@echo "    [CC64]   $@"
	$(Q)$(CC) $(CFLAGS) -m64 -c $< -o $@

ioctl-test: ioctl-test.o
	@echo "    [LD]   $@"
	$(Q)$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)
	@echo "   ?[PAHOLE] $@.pahole"
	-$(Q)pahole $@ > $@.pahole

ioctl-test-32: ioctl-test-32.o
	@echo "    [LD32]   $@"
	$(Q)$(CC) -m32 -o $@ $< $(LDFLAGS)
	@echo "   ?[PAHOLE] $@.pahole"
	-$(Q)pahole $@ > $@.pahole

ioctl-test-64: ioctl-test-64.o
	@echo "    [LD64]   $@"
	$(Q)$(CC) -m64 -o $@ $< $(LDFLAGS)
	@echo "   ?[PAHOLE] $@.pahole"
	-$(Q)pahole $@ > $@.pahole

test-ioctl: ioctl-test ioctl-test-32 ioctl-test-64
	@echo "    [TEST/ioctl]"
	$(Q)./ioctl-test > ioctl-test.log
	$(Q)./ioctl-test-32 > ioctl-test-32.log
	$(Q)./ioctl-test-64 > ioctl-test-64.log

library-test: library-test.c libbtrfs.so
	@echo "    [TEST PREP]  $@"$(eval TMPD=$(shell mktemp -d))
	$(Q)mkdir -p $(TMPD)/include/btrfs && \
	cp $(libbtrfs_headers) $(TMPD)/include/btrfs && \
	cd $(TMPD) && $(CC) -I$(TMPD)/include -o $@ $(addprefix $(ABSTOPDIR)/,$^) -Wl,-rpath=$(ABSTOPDIR) -lbtrfs
	@echo "    [TEST RUN]   $@"
	$(Q)cd $(TMPD) && ./$@
	@echo "    [TEST CLEAN] $@"
	$(Q)$(RM) -rf -- $(TMPD)

library-test.static: library-test.c $(libs_static)
	@echo "    [TEST PREP]  $@"$(eval TMPD=$(shell mktemp -d))
	$(Q)mkdir -p $(TMPD)/include/btrfs && \
	cp $(libbtrfs_headers) $(TMPD)/include/btrfs && \
	cd $(TMPD) && $(CC) -I$(TMPD)/include -o $@ $(addprefix $(ABSTOPDIR)/,$^) $(STATIC_LDFLAGS) $(STATIC_LIBS)
	@echo "    [TEST RUN]   $@"
	$(Q)cd $(TMPD) && ./$@
	@echo "    [TEST CLEAN] $@"
	$(Q)$(RM) -rf -- $(TMPD)

fssum: tests/fssum.c tests/sha224-256.c
	@echo "    [LD]     $@"
	$(Q)$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

test-build: test-build-pre test-build-real

test-build-pre:
	$(MAKE) $(MAKEOPTS) clean-all
	./autogen.sh
	./configure

test-build-real:
	$(MAKE) $(MAKEOPTS) library-test
	-$(MAKE) $(MAKEOPTS) library-test.static
	$(MAKE) $(MAKEOPTS) -j 8 all
	-$(MAKE) $(MAKEOPTS) -j 8 static
	$(MAKE) $(MAKEOPTS) -j 8 $(progs_extra)

manpages:
	$(Q)$(MAKE) $(MAKEOPTS) -C Documentation

tags: FORCE
	@echo "    [TAGS]   $(TAGS_CMD)"
	$(Q)$(TAGS_CMD) *.[ch] image/*.[ch] convert/*.[ch] mkfs/*.[ch] \
		check/*.[ch] kernel-lib/*.[ch] kernel-shared/*.[ch] \
		libbtrfsutil/*.[ch]

cscope: FORCE
	@echo "    [CSCOPE] $(CSCOPE_CMD)"
	$(Q)ls -1 *.[ch] image/*.[ch] convert/*.[ch] mkfs/*.[ch] check/*.[ch] \
		kernel-lib/*.[ch] kernel-shared/*.[ch] libbtrfsutil/*.[ch] \
		> cscope.files
	$(Q)$(CSCOPE_CMD)

clean-all: clean clean-doc clean-gen

clean: $(CLEANDIRS)
	@echo "Cleaning"
	$(Q)$(RM) -f -- $(progs) *.o *.o.d \
		kernel-lib/*.o kernel-lib/*.o.d \
		kernel-shared/*.o kernel-shared/*.o.d \
		image/*.o image/*.o.d \
		convert/*.o convert/*.o.d \
		mkfs/*.o mkfs/*.o.d check/*.o check/*.o.d \
	      dir-test ioctl-test quick-test library-test library-test-static \
              mktables btrfs.static mkfs.btrfs.static fssum \
	      $(check_defs) \
	      $(libs) $(lib_links) \
	      $(progs_static) $(progs_extra) \
	      libbtrfsutil/*.o libbtrfsutil/*.o.d
ifeq ($(PYTHON_BINDINGS),1)
	$(Q)cd libbtrfsutil/python; \
		$(PYTHON) setup.py $(SETUP_PY_Q) clean -a
endif

clean-doc:
	@echo "Cleaning Documentation"
	$(Q)$(MAKE) $(MAKEOPTS) -C Documentation clean

clean-gen:
	@echo "Cleaning Generated Files"
	$(Q)$(RM) -rf -- version.h config.status config.cache connfig.log \
		configure.lineno config.status.lineno Makefile.inc \
		Documentation/Makefile tags \
		cscope.files cscope.out cscope.in.out cscope.po.out \
		config.log config.h config.h.in~ aclocal.m4 \
		configure autom4te.cache/ config/

$(CLEANDIRS):
	@echo "Cleaning $(patsubst clean-%,%,$@)"
	$(Q)$(MAKE) $(MAKEOPTS) -C $(patsubst clean-%,%,$@) clean

install: $(libs) $(progs_install) $(INSTALLDIRS)
	$(INSTALL) -m755 -d $(DESTDIR)$(bindir)
	$(INSTALL) $(progs_install) $(DESTDIR)$(bindir)
	$(INSTALL) fsck.btrfs $(DESTDIR)$(bindir)
	# btrfsck is a link to btrfs in the src tree, make it so for installed file as well
	$(LN_S) -f btrfs $(DESTDIR)$(bindir)/btrfsck
	$(INSTALL) -m755 -d $(DESTDIR)$(libdir)
	$(INSTALL) $(libs) $(DESTDIR)$(libdir)
	cp -d $(lib_links) $(DESTDIR)$(libdir)
	$(INSTALL) -m755 -d $(DESTDIR)$(incdir)/btrfs
	$(INSTALL) -m644 $(libbtrfs_headers) $(DESTDIR)$(incdir)/btrfs
	$(INSTALL) -m644 libbtrfsutil/btrfsutil.h $(DESTDIR)$(incdir)
ifneq ($(udevdir),)
	$(INSTALL) -m755 -d $(DESTDIR)$(udevruledir)
	$(INSTALL) -m644 $(udev_rules) $(DESTDIR)$(udevruledir)
endif

ifeq ($(PYTHON_BINDINGS),1)
install_python: libbtrfsutil_python
	$(Q)cd libbtrfsutil/python; \
		$(PYTHON) setup.py install --skip-build $(if $(DESTDIR),--root $(DESTDIR)) --prefix $(prefix)

.PHONY: install_python
endif

install-static: $(progs_static) $(INSTALLDIRS)
	$(INSTALL) -m755 -d $(DESTDIR)$(bindir)
	$(INSTALL) $(progs_static) $(DESTDIR)$(bindir)
	# btrfsck is a link to btrfs in the src tree, make it so for installed file as well
	$(LN_S) -f btrfs.static $(DESTDIR)$(bindir)/btrfsck.static

# install, and set linux capabilities for a single-command executable
# defined in install_setcap_* above, using setcap(8)
install-setcap-%: $(subst install-setcap-,,$@)
	$(INSTALL) -m755 -d $(DESTDIR)$(bindir)
	$(INSTALL) -m750 -g btrfs $(subst install-setcap-,,$@) $(DESTDIR)$(bindir)
	$(SETCAP) $($(subst -,_,$@))+ep $(DESTDIR)$(bindir)/$(subst install-setcap-,,$@)

# install all $progs_install, and set linux capabilities using setcap(8)
install-setcap: $(patsubst %,install-setcap-%,$(progs_install_setcap))

$(INSTALLDIRS):
	@echo "Making install in $(patsubst install-%,%,$@)"
	$(Q)$(MAKE) $(MAKEOPTS) -C $(patsubst install-%,%,$@) install

uninstall:
	$(Q)$(MAKE) $(MAKEOPTS) -C Documentation uninstall
	cd $(DESTDIR)$(incdir)/btrfs; $(RM) -f -- $(libbtrfs_headers)
	$(RMDIR) -p --ignore-fail-on-non-empty -- $(DESTDIR)$(incdir)/btrfs
	cd $(DESTDIR)$(incdir); $(RM) -f -- btrfsutil.h
	cd $(DESTDIR)$(libdir); $(RM) -f -- $(lib_links) $(libs)
	cd $(DESTDIR)$(bindir); $(RM) -f -- btrfsck fsck.btrfs $(progs_install)

ifneq ($(MAKECMDGOALS),clean)
-include $(all_objects:.o=.o.d) $(subst .btrfs,, $(filter-out btrfsck.o.d, $(progs:=.o.d)))
endif
