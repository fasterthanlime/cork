
OOC ?= rock
OOC_ARGS ?= -v

all: prefix/lib/libnagaqueen.a
	${OOC} ${OOC_ARGS}

clean:
	rm -rf prefix
	${OOC} -x

prefix/lib/libnagaqueen.a: source/nagaqueen/NagaQueen.c
	mkdir -p prefix/lib
	gcc -w -std=gnu99 -c source/nagaqueen/NagaQueen.c -o prefix/lib/libnagaqueen.a

source/nagaqueen/NagaQueen.c:
	mkdir -p source/nagaqueen
	greg ../nagaqueen/grammar/nagaqueen.leg > source/nagaqueen/NagaQueen.c

