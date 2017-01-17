BUILD_OPTS=-Xlinker -L/usr/lib

SWIFTC=swiftc
SWIFT=swift
ifdef SWIFTPATH
    SWIFTC=$(SWIFTPATH)/bin/swiftc
    SWIFT=$(SWIFTPATH)/bin/swift
endif
OS := $(shell uname)
ifeq ($(OS),Darwin)
    SWIFTC=xcrun -sdk macosx swiftc
		LIBXMLBASE=$(shell xcrun --show-sdk-path)
		BUILD_OPTS=-Xlinker -L/usr/local/lib -Xcc -I/usr/local/include -Xlinker -lusb
endif

all: debug
	
release: CONF_ENV=release 
release: build_;
	
debug: CONF_ENV=debug
debug: build_;
	
build_:
	$(SWIFT) build --configuration $(CONF_ENV) $(BUILD_OPTS)
	
clean:
	$(SWIFT) package clean
	
distclean:
	$(SWIFT) package reset

test:
	$(SWIFT) test $(BUILD_OPTS)
