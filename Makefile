makelib:
	$(MAKE) -C lib/

all: reinstall
#	$(MAKE) -C lib_test
	@echo ""

install: makelib
	$(MAKE) -C lib/ libinstall

clean:
	$(MAKE) -C lib clean
#	$(MAKE) -C lib_test clean

uninstall: makelib
	ocamlfind remove twitterstream

reinstall:
	$(MAKE) uninstall
	$(MAKE) install
