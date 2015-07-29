
OOC ?= rock
OOC_ARGS ?= -v

all: prefix/lib/libnagaqueen.a
	${OOC} ${OOC_ARGS}

clean:
	rm -rf prefix
	${OOC} -x

prefix/lib/libnagaqueen.a: source/nagaqueen/NagaQueen.c
	mkdir -p prefix/lib
	gcc -c source/NagaQueen.c -o prefix/lib/libnagaqueen.a

source/nagaqueen/NagaQueen.c:
	mkdir -p source/nagaqueen
	greg ../nagaqueen/grammar/nagaqueen.leg > source/NagaQueen.c

