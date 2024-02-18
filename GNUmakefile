DEPEND = github.com/norayr/time
VOC = /opt/voc/bin/voc
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfile_dir_path := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
ifndef BUILD
BUILD="build"
endif
build_dir_path := $(mkfile_dir_path)/$(BUILD)
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))
BLD := $(mkfile_dir_path)/build
DPD  =  deps
ifndef DPS
DPS := $(mkfile_dir_path)/$(DPD)
endif
all: get_deps build_deps buildThis

get_deps:
	mkdir -p $(DPS)
	if [ -d $(DPS)/time ]; then cd $(DPS)/time; git pull; cd -; else cd $(DPS); git clone https://github.com/norayr/time; cd -; fi

build_deps:
	mkdir -p $(BUILD)
	cd $(BUILD)
	make -f $(DPS)/time/GNUmakefile BUILD=$(BUILD)

buildThis:
	cd $(BUILD) && $(VOC) -s $(mkfile_dir_path)/src/netTypes.Mod
	cd $(BUILD) && $(VOC) -s $(mkfile_dir_path)/src/netdb.Mod
	cd $(BUILD) && $(VOC) -s $(mkfile_dir_path)/src/netSockets.Mod
	cd $(BUILD) && $(VOC) -s $(mkfile_dir_path)/src/Internet.Mod
	cd $(BUILD) && $(VOC) -s $(mkfile_dir_path)/src/netForker.Mod
	cd $(BUILD) && $(VOC) -s $(mkfile_dir_path)/src/server.Mod

tests:
	cd $(BUILD) && $(VOC) $(mkfile_dir_path)/test/testServer.Mod -m
	cd $(BUILD) && $(VOC) $(mkfile_dir_path)/test/testClient.Mod -m

clean:
	if [ -d "$(BUILD)" ]; then rm -rf $(BLD); fi

