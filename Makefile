CC ?= gcc
CFLAGS += -std=c99 -Wall -O3
LDFLAGS += -lm
MAKE ?= make
PREFIX ?= /usr/local
MOZJPEG_PREFIX ?= /usr/local/Cellar/mozjpeg/3.0

UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

ifeq ($(UNAME_S),Linux)
	# Linux (e.g. Ubuntu)
	CFLAGS += -I$(MOZJPEG_PREFIX)/include
	ifeq ($(UNAME_M),x86_64)
		LIBJPEG = $(MOZJPEG_PREFIX)/lib64/libjpeg.a
	else
		LIBJPEG = $(MOZJPEG_PREFIX)/lib/libjpeg.a
	endif
else
	ifeq ($(UNAME_S),Darwin)
		# Mac OS X
		LIBJPEG = $(MOZJPEG_PREFIX)/lib/libjpeg.a
		CFLAGS += -I$(MOZJPEG_PREFIX)/include
	else
		# Windows
		LIBJPEG = ../mozjpeg/libjpeg.a
		CFLAGS += -I../mozjpeg
		MAKE = mingw32-make
	endif
endif

LIBIQA=src/iqa/build/release/libiqa.a

all: jpeg-recompress jpeg-compare jpeg-hash

$(LIBIQA):
	cd src/iqa; RELEASE=1 $(MAKE)

jpeg-recompress: jpeg-recompress.c src/lodepng.o src/util.o src/edit.o src/smallfry.o src/commander.o $(LIBIQA)
	$(CC) $(CFLAGS) -o $@ $^ $(LIBJPEG) $(LDFLAGS)

jpeg-compare: jpeg-compare.c src/lodepng.o src/util.o src/hash.o src/edit.o src/commander.o $(LIBIQA)
	$(CC) $(CFLAGS) -o $@ $^ $(LIBJPEG) $(LDFLAGS)

jpeg-hash: jpeg-hash.c src/lodepng.o src/util.o src/hash.o src/commander.o
	$(CC) $(CFLAGS) -o $@ $^ $(LIBJPEG) $(LDFLAGS)

%.o: %.c %.h
	$(CC) $(CFLAGS) -c -o $@ $<

test: test.c src/lodepng.o src/util.o src/edit.o src/hash.o
	$(CC) $(CFLAGS) -o $@ $^ $(LIBJPEG) $(LDFLAGS)
	./test

install: all
	mkdir -p $(PREFIX)/bin
	cp jpeg-archive $(PREFIX)/bin/
	cp jpeg-recompress $(PREFIX)/bin/
	cp jpeg-compare $(PREFIX)/bin/
	cp jpeg-hash $(PREFIX)/bin/

clean:
	rm -rf jpeg-recompress jpeg-compare jpeg-hash test src/*.o src/iqa/build
