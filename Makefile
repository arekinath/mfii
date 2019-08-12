ROOT=		$(PWD)
PROTO_AREA=	$(PWD)/../../../proto
STRAP_AREA=	$(PWD)/../../../proto.strap
KERNEL_SOURCE =	$(PWD)/../../illumos

CC=		$(STRAP_AREA)/usr/bin/gcc
LD=		/usr/bin/ld
CSTYLE=		$(KERNEL_SOURCE)/usr/src/tools/scripts/cstyle
CTFBINDIR =	$(KERNEL_SOURCE)/usr/src/tools/proto/*/opt/onbld/bin/i386
CTFCONVERT =	$(CTFBINDIR)/ctfconvert

BASE_CFLAGS=	-gdwarf-2 -isystem $(PROTO_AREA)/usr/include -Wall
CFLAGS+=	$(BASE_CFLAGS) 
CFLAGS+=	-m64 -msave-args -Wall
LDFLAGS+=	-L$(PROTO_AREA)/usr/lib

MANIFEST_FLAGS=

CFLAGS+=	-D_KERNEL -mcmodel=kernel -mno-red-zone -ffreestanding \
		-nodefaultlibs -Wall -Wno-unknown-pragmas -Wno-missing-braces \
		-fno-inline-functions -fno-inline -fno-strict-aliasing \
		-fwrapv -Wpointer-arith
CFLAGS+=	-I$(KERNEL_SOURCE)/usr/src/uts/common \
		-I$(KERNEL_SOURCE)/usr/src/uts/intel \
		-I$(KERNEL_SOURCE)/usr/src/uts/i86pc

HEADERS=	mfiireg.h \
		mfiref.h \
		mpiireg.h

SOURCES= 	mfii.c

OBJS=		$(SOURCES:%.c=%.o)

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -o $@ -c $<

mfii: $(OBJS)
	$(LD) -r -o $@ $(OBJS)
	$(CTFCONVERT) -L VERSION -o $@ $@

driver_aliases: $(KERNEL_SOURCE)/usr/src/uts/intel/os/driver_aliases
	(cat $< | grep -v '"pciex1000,5[bdf]"'; cat mfii_aliases) > $@

driver_classes: $(KERNEL_SOURCE)/usr/src/uts/intel/os/driver_classes
	(cat $<; printf "mfii\tscsi-self-identifying\n") > $@

name_to_major: $(KERNEL_SOURCE)/usr/src/uts/intel/os/name_to_major
	(cat $<; cat $< | sort -n -k2 | tail -1 | \
		while read _name num; do printf "mfii %d\n" $$(($$num + 1)); \
		done) > $@

.PHONY: clean
clean:
	rm -f $(OBJS) mfii

.PHONY: world
world: mfii driver_aliases driver_classes name_to_major

.PHONY: install
install: world
	mkdir -p $(DESTDIR)/usr/kernel/drv/amd64
	cp mfii $(DESTDIR)/usr/kernel/drv/amd64/
	cp mfii.conf $(DESTDIR)/usr/kernel/drv/
	mkdir -p $(DESTDIR)/kernel/drv/amd64
	cp mfii $(DESTDIR)/kernel/drv/amd64/
	cp mfii.conf $(DESTDIR)/kernel/drv/
	mkdir -p $(DESTDIR)/etc
	cp driver_aliases $(DESTDIR)/etc/
	cp driver_classes $(DESTDIR)/etc/
	cp name_to_major $(DESTDIR)/etc/

.PHONY: check
check:
	echo check

.PHONY: manifest
manifest:
	cpp $@ $(MANIFEST_FLAGS) > $(DESTDIR)/$(DESTNAME)

.PHONY:
mancheck_conf:
	cp mancheck.conf $(DESTDIR)/$(DESTNAME)

.PHONY: cscope
cscope:
	find . -type f -name '*.[ch]' > cscope.files
	cscope-fast -bq
