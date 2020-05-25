
device?=vivoactive4s

.PHONY: all
all: build/app-${device}.prg

sdk:
	$(error Need to run "ln -s <sdk_dir> sdk")

developer_key.der:
	$(error Need to run "ln -s <key_file> developer_key.der")

build:
	mkdir -p $@

build/app-%.prg: build icons fonts \
		monkey.jungle sdk developer_key.der \
		$(shell find source) $(shell find resources)
	sdk/bin/monkeyc --jungles monkey.jungle --output "$@" --private-key developer_key.der --device $* --warn

release:
	mkdir -p $@

release/app.iq: release icons fonts \
		monkey.jungle sdk developer_key.der \
		$(shell find source) $(shell find resources)
	sdk/bin/monkeyc --jungles monkey.jungle --output "$@" --private-key developer_key.der --release --package-app --warn

release/app-debug.iq: release icons fonts \
		monkey.jungle sdk developer_key.der \
		$(shell find source) $(shell find resources)
	sdk/bin/monkeyc --jungles monkey.jungle --output "$@" --private-key developer_key.der --package-app --warn

release/app-%.prg: release icons fonts \
		monkey.jungle sdk developer_key.der \
		$(shell find source) $(shell find resources)
	sdk/bin/monkeyc --jungles monkey.jungle --output "$@" --private-key developer_key.der --device $* --warn --release

.PHONY: clean
clean:
	rm -rf build release

.PHONY: run
run: build/app-${device}.prg
	./run.sh "$<" ${device}

.PHONY: fonts
fonts: resources/fonts/icon_font_72.png

.PRECIOUS: resources/fonts/icon_font_%.png
resources/fonts/icon_font_%.png: support/icon_font.tar support/make_font.py
	python support/make_font.py -t support/icon_font.tar -o resources/fonts $*

support/icon_font.tar: support/icon_font.svg
	$(error Use inkscape to open support/icon_font.svg and save as .tar)

.PHONY: icons
icons: resources/drawables/launcher_icon.png

resources/drawables/launcher_icon.png: support/launcher_icon.svg
	inkscape --export-filename="$@" -w 30 -h 30 "$<"
