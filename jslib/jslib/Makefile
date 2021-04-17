# Todo: atomize identifiers
DIRS = js
SRC = $(shell find $(DIRS) $(wildcard *.js) -name "*.js")
HEADERS = $(shell find $(DIRS) $(wildcard *.h) -name "*.h")
EXE = js/lang/Interpreter.o.gz
JSP = $(shell which j)
PERL = $(shell which perl)
TESTS = $(shell find $(DIRS) $(wildcard *.t) -name "*.t")
INC = -I/home/slipwave/src/jslib
CPPOPTS = -nostdinc -ftabstop=4 -x c++
MIN = $(shell which minimize_lines)
PREPROCESS = -DMAKEDEPEND=1
DEFS = 

tests: depend $(TESTS)
	@HARNESS_PERL=$(JSP) $(PERL) -e 'use Test::Harness qw(&runtests $$verbose);$$verbose=0;runtests @ARGV;' $(TESTS) 2>&1 | tee js/test.results

verbose: depend $(TESTS)
	@HARNESS_PERL=$(JSP) $(PERL) -e 'use Test::Harness qw(&runtests $$verbose);$$verbose=1;runtests @ARGV;' $(TESTS) 2>&1 | tee js/test.results

all: depend $(EXE)

%: $.t
	@$(JSP) $@

%.gz: %
	@gzip -f $<

%.o: %.js Makefile
	@#cpp -nostdinc -ftabstop=4 -x c++ $(INC) -P $< | pack-scripts -q -i - -o $@
	@cpp -DPRECOMPILED $(DEFS) $(CPPOPTS) $(INC) $< | sed -e "s/^#/\/\/@line/g" | sed -e "s/^ *//" | $(MIN)> $@

clean:
	@rm -f *.o *.gz *.bak

depend: Makefile.dep

Makefile.dep: $(SRC) $(HEADERS)
	@echo >> Makefile.dep
	@makedepend $(PREPROCESS) $(DEFS) $(INC) -fMakefile.dep -- -- $(SRC) $(HEADERS)
	@rm Makefile.dep.bak

.PHONY: clean depend all
	
ifeq "$(wildcard Makefile.dep)" "Makefile.dep"
include Makefile.dep
endif

