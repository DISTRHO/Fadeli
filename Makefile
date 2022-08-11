#!/usr/bin/make -f
# Makefile for DISTRHO Plugins #
# ---------------------------- #
# Created by falkTX
#

include dpf/Makefile.base.mk

all: plugins

# plugin list comes from whatever faust dsp files we have around
PLUGINS = $(subst dsp/,,$(subst .dsp,,$(wildcard dsp/*.dsp)))

# ---------------------------------------------------------------------------------------------------------------------
# clean target, removes any build artifacts

clean:
	rm -rf bin build

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
# gen target, converting all faust dsp files into plugin code

PLUGIN_TEMPLATE_FILES  = $(subst template/,,$(wildcard template/*.*))
PLUGIN_GENERATED_FILES = $(foreach f,$(PLUGIN_TEMPLATE_FILES),$(PLUGINS:%=build/%/$(f)))

gen: $(PLUGIN_GENERATED_FILES)

# ---------------------------------------------------------------------------------------------------------------------
# plugins target, for actual building the plugin stuff after it has been generated

define PLUGIN_BUILD
	$(MAKE) ladspa lv2_dsp vst2 vst3 -C build/$(1) -f $(CURDIR)/dpf/Makefile.plugins.mk NAME=fadeli-$(1) FILES_DSP=Plugin.cpp

endef

plugins: gen
	$(foreach p,$(PLUGINS),$(call PLUGIN_BUILD,$(p)))

# ---------------------------------------------------------------------------------------------------------------------
# rules for faust dsp to plugin code conversion

AS_LABEL   = $(shell echo $(1) | tr - _)
AS_LV2_URI = urn:fadeli:$(1)

FAUSTPP_ARGS = -Dlabel=$(call AS_LABEL,$*) -Dlv2uri=$(call AS_LV2_URI,$*)

build/%/DistrhoPluginInfo.h: dsp/%.dsp faustpp
	mkdir -p build/$*
	$(FAUSTPP_EXEC) $(FAUSTPP_ARGS) -a template/DistrhoPluginInfo.h $< -o $@

build/%/Plugin.cpp: dsp/%.dsp faustpp
	mkdir -p build/$*
	$(FAUSTPP_EXEC) $(FAUSTPP_ARGS) -a template/Plugin.cpp $< -o $@

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

.PHONY: faustpp
