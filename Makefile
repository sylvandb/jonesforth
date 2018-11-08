# $Id: Makefile,v 1.9 2007-10-22 18:53:12 rich Exp $

#BUILD_ID_NONE := -Wl,--build-id=none 
BUILD_ID_NONE := 

SHELL	:= /bin/bash

# Alain Kalker writes:
# Newer Linux kernels have a feature which allows to protect an area of low
# virtual memory from userspace allocation (configured by
# CONFIG_DEFAULT_MMAP_MIN_ADDR), which can help reduce the impact of kernel
# NULL pointer bugs.
# Get (or change) the current value by reading (or writing)
#   /proc/sys/vm/mmap_min_addr
# On my system, `cat /proc/sys/vm/mmap_min_addr` returns 4096, so I updated the
# linker options to `-Wl,-Ttext,1000` (note: the address must be specified in
# hex!), and everything works well.
# Rich Jones writes:
# Note that we do assume the text starts at address zero.
# [but I don't see a dependency]
# https://rwmj.wordpress.com/2010/08/07/jonesforth-git-repository/
TEXT	:= $(shell printf '%04x' $(shell cat /proc/sys/vm/mmap_min_addr))

all:	jonesforth

jonesforth: jonesforth.S
	gcc -m32 -nostdlib -static -Wl,-Ttext,$(TEXT) $(BUILD_ID_NONE) -o $@ $<

run:
	cat jonesforth.f $(PROG) - | ./jonesforth

clean:
	rm -f jonesforth perf_dupdrop *~ core .test_*

# Tests.

TESTS	:= $(patsubst %.f,%.test,$(wildcard test_*.f))

test check: $(TESTS)

test_%.test: test_%.f jonesforth
	@echo -n "$< ... "
	@rm -f .$@
	@cat <(echo ': TEST-MODE ;') jonesforth.f $< <(echo 'TEST') | \
	  ./jonesforth 2>&1 | \
	  sed 's/DSP=[0-9]*//g' > .$@
	@diff -u .$@ $<.out
	@rm -f .$@
	@echo "ok"

# Performance.

perf_dupdrop: perf_dupdrop.c
	gcc -O3 -Wall -Werror -o $@ $<

run_perf_dupdrop: jonesforth
	cat <(echo ': TEST-MODE ;') jonesforth.f perf_dupdrop.f | ./jonesforth

.SUFFIXES: .f .test
.PHONY: test check run run_perf_dupdrop

remote:
	scp jonesforth.S jonesforth.f rjones@oirase:Desktop/
	ssh rjones@oirase sh -c '"rm -f Desktop/jonesforth; \
	  gcc -m32 -nostdlib -static -Wl,-Ttext,0 -o Desktop/jonesforth Desktop/jonesforth.S; \
	  cat Desktop/jonesforth.f - | Desktop/jonesforth arg1 arg2 arg3"'
