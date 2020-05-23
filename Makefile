
device?=vivoactive4s

.PHONY: all
all: build/app-${device}.prg

sdk:
	$(error Need to run "ln -s <sdk_dir> sdk")

developer_key.der:
	$(error Need to run "ln -s <key_file> developer_key.der")

build:
	mkdir -p $@

build/app-%.prg: build icons \
		monkey.jungle sdk developer_key.der \
		$(shell find source) $(shell find resources)
	sdk/bin/monkeyc --jungles monkey.jungle --output "$@" --private-key developer_key.der --device $* --warn

release:
	mkdir -p $@

release/app.iq: release icons \
		monkey.jungle sdk developer_key.der \
		$(shell find source) $(shell find resources)
	sdk/bin/monkeyc --jungles monkey.jungle --output "$@" --private-key developer_key.der --release --package-app --warn

release/app-debug.iq: release icons \
		monkey.jungle sdk developer_key.der \
		$(shell find source) $(shell find resources)
	sdk/bin/monkeyc --jungles monkey.jungle --output "$@" --private-key developer_key.der --package-app --warn

release/app-%.prg: release icons \
		monkey.jungle sdk developer_key.der \
		$(shell find source) $(shell find resources)
	sdk/bin/monkeyc --jungles monkey.jungle --output "$@" --private-key developer_key.der --device $* --warn --release

.PHONY: clean
clean:
	rm -rf build release

.PHONY: run
run: build/app-${device}.prg
	./run.sh "$<" ${device}

.PHONY: icons
icons: resources/drawables/launcher_icon.png

resources/drawables/launcher_icon.png: support/launcher_icon.svg
	inkscape --export-filename="$@" -w 30 -h 30 "$<"
