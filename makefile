VOC = /opt/voc/bin/voc
BLD=bld


all:
		mkdir -p $(BLD)
		cd $(BLD) && \
		voc -s \
		../src/netTypes.Mod \
		../src/netdb.Mod \
		../src/netSockets.Mod \
		../src/Internet.Mod

clean:
		if [ -d "$(BLD)" ]; then rm -rf $(BLD); fi
