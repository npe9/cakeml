CP ?= cp
CC ?= gcc
SKIPGCC?=F
CAKECC64 = cake
CAKECC32 = cake32
CAKE_PREFIX ?= cake_
PATH_PREFIX ?= .
CAKE_FLAGS ?=
FLAGS ?= -g -o
BMS = $(wildcard *.sml)
CAKECC ?= $(CAKECC64)
BM_PROGS = $(patsubst %.sml,$(CAKE_PREFIX)%,$(BMS))

ASM_PROGS = $(patsubst %.sml,%.S,$(BMS))

all: benchmarks

compiler : cake.S basis_ffi.c
	$(CC) $< basis_ffi.c $(FLAGS) $(CAKECC64)

compiler32 : cake32.S basis_ffi.c
	$(CC) $< basis_ffi.c $(FLAGS) $(CAKECC32)

benchmarks : $(BM_PROGS)

$(CAKE_PREFIX)% : %.sml
ifeq ($(SKIPGCC),F)
	./$(CAKECC) $(CAKE_FLAGS) < $(basename $<).sml > $(basename $<).S
	$(CC) $(basename $<).S basis_ffi.c $(FLAGS) $(PATH_PREFIX)/$@
else
	./$(CAKECC) $(CAKE_FLAGS) < $(basename $<).sml > $(PATH_PREFIX)/$(basename $<).S
endif

clean:
	rm $(BM_PROGS) $(ASM_PROGS)
