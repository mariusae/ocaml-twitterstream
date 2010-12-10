FILES=                                 \
  twitterstream.cma twitterstream.cmxa \
  twitterstream.a twitterstream.cmi

BFILES=$(addprefix _build/lib/,$(FILES))
FLAGS=-use-ocamlfind

.PHONY: all
all:
	ocamlbuild $(FLAGS) -I lib twitterstream.cma twitterstream.cmxa

.PHONY: all
doc:
	ocamlbuild $(FLAGS) -no-links lib/doc.docdir/index.html

.PHONY: install
install: all
	ocamlfind install twitterstream lib/META $(BFILES)

.PHONY: uninstall
uninstall:
	ocamlfind remove twitterstream

.PHONY: reinstall
reinstall: all uninstall install

.PHONY: clean
clean:
	ocamlbuild -clean
