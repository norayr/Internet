VOC = voc
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

build_deps:
	mkdir -p $(BUILD)

buildThis:
	cd $(BUILD) && $(VOC) -s $(mkfile_dir_path)/src/unixNet.Mod
	cd $(BUILD) && $(VOC) -s $(mkfile_dir_path)/src/Kernel.Mod
	cd $(BUILD) && $(VOC) -s $(mkfile_dir_path)/src/Sockets.Mod
	cd $(BUILD) && $(VOC) -s $(mkfile_dir_path)/src/DNS.Mod
	cd $(BUILD) && $(VOC) -s $(mkfile_dir_path)/src/Internet.Mod
	cd $(BUILD) && $(VOC) -s $(mkfile_dir_path)/src/netForker.Mod
	cd $(BUILD) && $(VOC) -s $(mkfile_dir_path)/src/server.Mod
	# Native Oberon compatibility
	cd $(BUILD) && $(VOC) -s $(mkfile_dir_path)/src/native/NetSystem.Mod

# the first wrappers of the C socket calls, deprecated: Sockets replaces them
deprecated:
	cd $(BUILD) && $(VOC) -s $(mkfile_dir_path)/src/deprecated/netTypes.Mod
	cd $(BUILD) && $(VOC) -s $(mkfile_dir_path)/src/deprecated/netdb.Mod
	cd $(BUILD) && $(VOC) -s $(mkfile_dir_path)/src/deprecated/netSockets.Mod

tests:
	cd $(BUILD) && $(VOC) $(mkfile_dir_path)/test/testServer.Mod -m
	cd $(BUILD) && $(VOC) $(mkfile_dir_path)/test/testClient.Mod -m
	cd $(BUILD) && $(VOC) $(mkfile_dir_path)/test/testSockets.Mod -m
	@cd $(BUILD) && { timeout 20 ./testServer > testServer.log 2>&1 & sp=$$!; sleep 1; \
	  timeout 10 ./testClient | tee testClient.log; wait $$sp; \
	  grep -q "Affirmative, Dave" testClient.log && grep -q "received message: 'bye'" testServer.log \
	  && echo "testServer, testClient: ok" || { echo "testServer, testClient: FAIL"; exit 1; }; }
	cd $(BUILD) && $(VOC) $(mkfile_dir_path)/test/native/testNetSystem.Mod -m
	cd $(BUILD) && ./testNetSystem $(NET)

clean:
	if [ -d "$(BUILD)" ]; then rm -rf $(BLD); fi

