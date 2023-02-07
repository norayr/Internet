VOC = /opt/voc/bin/voc
BUILD="build"
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfile_dir_path := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))
DPS = dps

all: get_deps build_deps

get_deps:
		mkdir -p $(DPS)
		if [ -d $(DPS)/time ]; then cd $(DPS)/time; git pull; cd -; else cd $(DPS); git clone https://github.com/norayr/time; cd -; fi

build_deps:		
		mkdir -p $(BUILD)
		cd $(BUILD) && \
		$(VOC) -s \
		$(mkfile_dir_path)/src/netTypes.Mod \
		$(mkfile_dir_path)/src/netdb.Mod \
		$(mkfile_dir_path)/src/netSockets.Mod \
		$(mkfile_dir_path)/src/Internet.Mod \
		$(mkfile_dir_path)/src/netForker.Mod \
		$(mkfile_dir_path)/src/server.Mod \
		$(mkfile_dir_path)/$(DPS)/time/src/time.Mod \
		$(mkfile_dir_path)/tests/testServer.Mod -m
		cd $(BUILD) && \
		$(VOC) $(mkfile_dir_path)/tests/testClient.Mod -m

clean:
		if [ -d "$(BUILD)" ]; then rm -rf $(BUILD); fi
