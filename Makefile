#!/usr/bin/make -f
# Makefile for DISTRHO Plugins #
# ---------------------------- #
# Created by falkTX
#

include dpf/Makefile.base.mk

all: dsp

# ---------------------------------------------------------------------------------------------------------------------
# dsp target, finding all faust dsp files to convert into plugin code

DSP_FILES = $(subst dsp/,,$(subst .dsp,,$(wildcard dsp/*.dsp)))

PLUGIN_FILES  = $(DSP_FILES:%=build/%/Plugin.cpp)
PLUGIN_FILES += $(DSP_FILES:%=build/%/Plugin.hpp)

dsp: $(PLUGIN_FILES)

# ---------------------------------------------------------------------------------------------------------------------
# faustpp target, building it ourselves if not available from the system

ifeq ($(shell command -v faustpp 1>/dev/null && echo true),true)
FAUSTPP_TARGET =
FAUSTPP_EXEC = faustpp
else
FAUSTPP_TARGET = build/faustpp/faustpp$(APP_EXT)
FAUSTPP_EXEC = $(CURDIR)/$(FAUSTPP_TARGET)
endif

faustpp: $(FAUSTPP_TARGET)

# ---------------------------------------------------------------------------------------------------------------------

clean:
	rm -rf bin build

# ---------------------------------------------------------------------------------------------------------------------
# rules for faust dsp to plugin code conversion

CONVERT_DASHES = $(shell echo $(1) | tr - _)

build/%/Plugin.cpp: dsp/%.dsp faustpp
	mkdir -p build/$*
	$(FAUSTPP_EXEC) -DIdentifier=$(call CONVERT_DASHES,$*) -a faustpp/architectures/generic.cpp $< > $@

build/%/Plugin.hpp: dsp/%.dsp faustpp
	mkdir -p build/$*
	$(FAUSTPP_EXEC) -DIdentifier=$(call CONVERT_DASHES,$*) -a faustpp/architectures/generic.hpp $< > $@

# ---------------------------------------------------------------------------------------------------------------------
# rules for custom faustpp build

CMAKE_ARGS  = -G 'Unix Makefiles'
ifeq ($(DEBUG),true)
CMAKE_ARGS += -DCMAKE_BUILD_TYPE=Debug
else
CMAKE_ARGS += -DCMAKE_BUILD_TYPE=Release
endif
ifeq ($(WINDOWS),true)
CMAKE_ARGS += -DCMAKE_SYSTEM_NAME=Windows
# -DCMAKE_CROSSCOMPILING=ON
endif

faustpp/CMakeLists.txt:
	git clone --recursive https://github.com/falkTX/faustpp.git --depth=1 -b use-internal=boost

build/faustpp/Makefile: faustpp/CMakeLists.txt
	cmake -Bbuild/faustpp -Sfaustpp -DFAUSTPP_USE_INTERNAL_BOOST=ON $(CMAKE_ARGS)

build/faustpp/faustpp$(APP_EXT): build/faustpp/Makefile
	$(MAKE) -C build/faustpp

# ---------------------------------------------------------------------------------------------------------------------

.PHONY: dsp faustpp
