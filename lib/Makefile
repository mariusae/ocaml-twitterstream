ANNOTATE = yes
SOURCES = \
  twitterstream_status.mli twitterstream_status.ml \
  twitterstream_stream.mli twitterstream_stream.ml

PACKS = lwt json-wheel curl

LIB_PACK_NAME = twitterstream
RESULT = twitterstream
LIBINSTALL_FILES = \
  META twitterstream.cma twitterstream.cmxa \
  twitterstream.a twitterstream.cmi

.PHONY: all
all: pack-byte-code pack-native-code twitterstream.cma twitterstream.cmxa
	@ :

OCAMLMAKEFILE=../OCamlMakefile
include $(OCAMLMAKEFILE)
