VOC = /opt/voc/bin/voc
BUILD="build"
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfile_dir_path := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))

all:
		mkdir -p $(BUILD)
		cd $(BUILD) && \
		voc -s \
		$(mkfile_dir_path)/src/netTypes.Mod \
		$(mkfile_dir_path)/src/netdb.Mod \
		$(mkfile_dir_path)/src/netSockets.Mod \
		$(mkfile_dir_path)/src/Internet.Mod \
		$(mkfile_dir_path)/src/netForker.Mod \
		$(mkfile_dir_path)/src/server.Mod \
		$(mkfile_dir_path)/Time/src/time.Mod \
		$(mkfile_dir_path)/tst/testServer.Mod -m
		cd $(BUILD) && \
		voc $(mkfile_dir_path)/tst/testClient.Mod -m

clean:
		if [ -d "$(BUILD)" ]; then rm -rf $(BUILD); fi
