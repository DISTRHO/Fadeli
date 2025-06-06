#!/usr/bin/make -f
# Makefile for DISTRHO Plugins #
# ---------------------------- #
# Created by falkTX
#

include dpf/Makefile.base.mk

all: plugins

# plugin list comes from whatever faust dsp files we have around
PLUGINS = $(subst dsp/,,$(subst .dsp,,$(wildcard dsp/*.dsp)))

# define project version, globally set the same for all generated plugins
VERSION_MAJOR = 0
VERSION_MINOR = 0
VERSION_MICRO = 1

# ---------------------------------------------------------------------------------------------------------------------
# clean target, removes any build artifacts

clean:
	rm -rf bin build

# ---------------------------------------------------------------------------------------------------------------------
# faustpp target, building it ourselves if not available from the system

ifneq ($(CROSS_COMPILING),true)
APP_EXT =
endif

ifeq ($(shell command -v faustpp 1>/dev/null && echo true),true)
FAUSTPP_TARGET =
FAUSTPP_EXEC = faustpp
else
FAUSTPP_TARGET = build/faustpp/faustpp$(APP_EXT)
FAUSTPP_EXEC = $(CURDIR)/$(FAUSTPP_TARGET)
endif

faustpp:

# never rebuild faustpp
ifneq ($(FAUSTPP_TARGET),)
ifeq ($(wildcard $(FAUSTPP_TARGET)),)
faustpp: $(FAUSTPP_TARGET)
.PHONY: faustpp
endif
endif

# ---------------------------------------------------------------------------------------------------------------------
# list of plugin source code files to generate, converted from faust dsp files

PLUGIN_TEMPLATE_FILES   = $(subst template/,,$(wildcard template/*.*))
PLUGIN_GENERATED_FILES  = $(foreach f,$(PLUGIN_TEMPLATE_FILES),$(PLUGINS:%=build/fadeli-%/$(f)))
PLUGIN_GENERATED_FILES += $(PLUGINS:%=bin/fadeli-%.lv2/manifest.ttl)
PLUGIN_GENERATED_FILES += $(PLUGINS:%=bin/fadeli-%.lv2/plugin.ttl)

gen: $(PLUGIN_GENERATED_FILES)

# ---------------------------------------------------------------------------------------------------------------------
# plugins target, for actual building the plugin stuff after its source code has been generated

define PLUGIN_BUILD
	$(MAKE) ladspa lv2_dsp vst2 vst3 clap au -C build/fadeli-$(1) -f $(CURDIR)/dpf/Makefile.plugins.mk APP_EXT=$(APP_EXT) NAME=fadeli-$(1) FILES_DSP=Plugin.cpp

endef

plugins: $(PLUGIN_GENERATED_FILES)
	+$(foreach p,$(PLUGINS),$(call PLUGIN_BUILD,$(p)))

# ---------------------------------------------------------------------------------------------------------------------
# rules for faust dsp to plugin code conversion

AS_LABEL   = $(shell echo $(1) | tr - _)
AS_LV2_URI = urn:fadeli:$(1)
AS_CLAP_ID = studio.kx.distrho.fadeli.$(1)

# FIXME replace with a custom nice regex
AS_UNIQUE_ID = $(shell echo $(1) | base64 | cut -c 1-4)

FAUSTPP_ARGS = \
	-Dbinary_name="fadeli-$(1)" \
	-Dbrand="DISTRHO" \
	-Dclapid="$(call AS_CLAP_ID,$(1))" \
	-Duniqueid="$(call AS_UNIQUE_ID,$(1))" \
	-Dhomepage="https://github.com/DISTRHO/Fadeli" \
	-Dlabel="$(call AS_LABEL,$(1))" \
	-Dlicense="ISC" \
	-Dlicenseurl="http://spdx.org/licenses/ISC.html" \
	-Dlibext="$(LIB_EXT)" \
	-Dlv2uri="$(call AS_LV2_URI,$(1))" \
	-Dversion_major=$(VERSION_MAJOR) \
	-Dversion_minor=$(VERSION_MINOR) \
	-Dversion_micro=$(VERSION_MICRO)

bin/fadeli-%.lv2/manifest.ttl: dsp/%.dsp template/LV2/manifest.ttl faustpp
	mkdir -p bin/fadeli-$*.lv2
	$(FAUSTPP_EXEC) $(call FAUSTPP_ARGS,$*) -a template/LV2/manifest.ttl $< -o $@

bin/fadeli-%.lv2/plugin.ttl: dsp/%.dsp template/LV2/plugin.ttl faustpp
	mkdir -p bin/fadeli-$*.lv2
	$(FAUSTPP_EXEC) $(call FAUSTPP_ARGS,$*) -a template/LV2/plugin.ttl $< -o $@

build/fadeli-%/DistrhoPluginInfo.h: dsp/%.dsp template/DistrhoPluginInfo.h faustpp
	mkdir -p build/fadeli-$*
	$(FAUSTPP_EXEC) $(call FAUSTPP_ARGS,$*) -a template/DistrhoPluginInfo.h $< -o $@

build/fadeli-%/Plugin.cpp: dsp/%.dsp template/Plugin.cpp faustpp
	mkdir -p build/fadeli-$*
	$(FAUSTPP_EXEC) $(call FAUSTPP_ARGS,$*) -a template/Plugin.cpp $< -o $@

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
endif

faustpp/CMakeLists.txt:
	git clone --recursive https://github.com/falkTX/faustpp.git --depth=1 -b use-internal=boost

build/faustpp/Makefile: faustpp/CMakeLists.txt
	cmake -Bbuild/faustpp -Sfaustpp -DFAUSTPP_USE_INTERNAL_BOOST=ON $(CMAKE_ARGS)

$(FAUSTPP_TARGET): build/faustpp/Makefile
	$(MAKE) -C build/faustpp

# ---------------------------------------------------------------------------------------------------------------------
