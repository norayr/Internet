DEPEND = github.com/norayr/time

VOC = /opt/voc/bin/voc
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfile_dir_path := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
BUILD := build
DPS := deps
DEPS_PATH := $(mkfile_dir_path)/$(DPS)
BUILD_PATH := $(mkfile_dir_path)/$(BUILD)

# Function to transform GitHub repository URLs to local directory paths
define dep_path
$(DEPS_PATH)/$(1)
endef

# Targets for dependency management
.PHONY: all get_deps build_deps build_this clean

all: get_deps build_deps build_this

get_deps:
	@echo "Fetching and updating dependencies..."
	@mkdir -p $(DEPS_PATH)
	@for dep in $(DEPEND); do \
		dep_dir="$(call dep_path,$$dep)"; \
		if [ ! -d "$$dep_dir" ]; then \
			git clone "https://$$dep.git" "$$dep_dir"; \
		else \
			(cd "$$dep_dir" && git pull); \
		fi; \
	done

build_deps:
	@echo "Building dependencies..."
	@mkdir -p $(BUILD_PATH)
	@for dep in $(DEPEND); do \
		dep_dir="$(call dep_path,$$dep)"; \
		if [ -f "$$dep_dir/GNUmakefile" ] || [ -f "$$dep_dir/Makefile" ]; then \
			$(MAKE) -C "$$dep_dir" -f "$${dep_dir}/GNUmakefile" BUILD=$(BUILD_PATH) || \
			$(MAKE) -C "$$dep_dir" -f "$${dep_dir}/Makefile" BUILD=$(BUILD_PATH); \
		fi; \
	done

build_this:
	@echo "Building this project..."
	cd $(BUILD_PATH) && $(VOC) -s $(mkfile_dir_path)/src/netTypes.Mod
	cd $(BUILD_PATH) && $(VOC) -s $(mkfile_dir_path)/src/netdb.Mod
	cd $(BUILD_PATH) && $(VOC) -s $(mkfile_dir_path)/src/netSockets.Mod
	cd $(BUILD_PATH) && $(VOC) -s $(mkfile_dir_path)/src/Internet.Mod
	cd $(BUILD_PATH) && $(VOC) -s $(mkfile_dir_path)/src/netForker.Mod
	cd $(BUILD_PATH) && $(VOC) -s $(mkfile_dir_path)/src/server.Mod

tests:
	cd $(BUILD_PATH) && $(VOC) $(mkfile_dir_path)/test/testServer.Mod -m
	cd $(BUILD_PATH) && $(VOC) $(mkfile_dir_path)/test/testClient.Mod -m
	
clean:
	@echo "Cleaning build directory..."
	@rm -rf $(BUILD_PATH)

