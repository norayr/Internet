.POSIX:

DEPS     = norayr/time

GITHUB   = https://github.com/

ROOTDIR  = $$PWD

all: ${DEPS}
	@if [ ! -d build ]; then \
		mkdir build;     \
	fi
	cd build; voc -s ${ROOTDIR}/../src/netTypes.Mod       \
			 ${ROOTDIR}/../src/netdb.Mod          \
			 ${ROOTDIR}/../src/netSockets.Mod     \
			 ${ROOTDIR}/../src/Internet.Mod       \
			 ${ROOTDIR}/../src/netForker.Mod      \
			 ${ROOTDIR}/../src/server.Mod         \
			 ${ROOTDIR}/../deps/time/src/time.Mod \
			 ${ROOTDIR}/../tst/testServer.Mod -m
	cd build; voc    ${ROOTDIR}/../tst/testClient.Mod -m

${DEPS}:
	@for i in $@; do                                          \
		if [ -d deps/$${i#*/} ]; then                     \
			printf "Updating %s: " $${i#*/};          \
			git -C deps/$${i#*/} pull --ff-only       \
				${GITHUB}$$i > /dev/null 2>&1     \
				&& echo done                      \
				|| (echo failed && exit 1);       \
		else                                              \
			printf "Fetching %s: " $${i#*/};          \
			git clone ${GITHUB}$$i deps/$${i#*/}      \
				> /dev/null 2>&1                  \
				&& echo done                      \
				|| (echo failed && exit 1);       \
		fi                                                \
	done

clean:
	rm -rf build deps

.PHONY: deps
