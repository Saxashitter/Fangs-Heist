.SILENT:
.PHONY: build runlinux

MUSIC_PATH := src/Music/

build:
	rm -f build.pk3
	cd src; zip -r9 ../build.pk3 *

runlinux:
	cd ~/.srb2/; ./lsdl2srb2 $(SRB2OPT) -file $(CURDIR)/build.pk3