OS := $(if $(filter Windows_NT,$(OS)),Windows_NT,$(shell uname -s))
ifeq ($(OS),Windows_NT)
include make-windows.mk
else ifeq ($(OS),Linux)
include make-linux.mk
else ifeq ($(OS),Darwin)
include make-mac.mk
endif
