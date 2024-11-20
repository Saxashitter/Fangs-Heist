.PHONY: zip pak runlinux

zip:
	rm -f build.pk3
	cd src; zip -r9 ../build.pk3 *

pak:
	node PaK3/main.js src/ build.pk3

runlinux:
	cd ~/.srb2/; ./lsdl2srb2 $(SRB2OPT) -file $(CURDIR)/build.pk3