HC       = ghc
SOFTWARE = remorse
VERSION  = 1.0
ALLFILES = remorse.hs Makefile README

remorse: remorse.hs
	$(HC) -o remorse remorse.hs

clean:
	rm -f remorse remorse.o remorse.hi Main.hi

srcDist: $(ALLFILES)
	mkdir $(SOFTWARE)-$(VERSION)
	cp $(ALLFILES) $(SOFTWARE)-$(VERSION)
	tar zcf $(SOFTWARE)-$(VERSION).tar.gz $(SOFTWARE)-$(VERSION)
	rm -r $(SOFTWARE)-$(VERSION)
