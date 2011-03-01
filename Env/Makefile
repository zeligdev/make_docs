DIR := $(shell echo `mktemp -d tex_XXXX`)
CONF = order.conf
DEST = zelig.tex

all:
	sh sweave.sh $(DIR)
	perl build_doc.pl dir=$(DIR) conf=$(CONF) dest=$(DEST)
