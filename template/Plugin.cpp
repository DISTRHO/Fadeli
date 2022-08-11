{% block HeaderDescription %}
//------------------------------------------------------------------------------
// This file was generated using the Faust compiler (https://faust.grame.fr),
// and the Faust post-processor (https://github.com/jpcima/faustpp).
//
// Source: {{file_name}}
// Name: {{name}}
// Author: {{author}}
// Copyright: {{copyright}}
// License: {{license}}
// Version: {{version}}
//------------------------------------------------------------------------------
{% endblock %}

#include "DistrhoPlugin.hpp"
#include "extra/ScopedPointer.hpp"

// --------------------------------------------------------------------------------------------------------------------

// inline code when possible
#define FAUSTPP_VIRTUAL inline

// make everything available directly
#define FAUSTPP_PRIVATE public
#define FAUSTPP_PROTECTED public

// match distrho namespace
#define FAUSTPP_BEGIN_NAMESPACE START_NAMESPACE_DISTRHO
#define FAUSTPP_END_NAMESPACE END_NAMESPACE_DISTRHO

// --------------------------------------------------------------------------------------------------------------------

START_NAMESPACE_DISTRHO

template <class T> inline T min(T a, T b) { return (a < b) ? a : b; }
template <class T> inline T max(T a, T b) { return (a > b) ? a : b; }

class dsp {
public:
    virtual ~dsp() {}
};

class Meta {
public:
    // dummy
    void declare(...) {}
};

class UI {
public:
    // dummy
    void openHorizontalBox(...) {}
    void openVerticalBox(...) {}
    void closeBox(...) {}
    void declare(...) {}
    void addButton(...) {}
    void addCheckButton(...) {}
    void addVerticalSlider(...) {}
    void addHorizontalSlider(...) {}
    void addVerticalBargraph(...) {}
    void addHorizontalBargraph(...) {}
};

END_NAMESPACE_DISTRHO

// --------------------------------------------------------------------------------------------------------------------

{% block ImplementationFaustCode %}
{{class_code}}
{% endblock %}

// --------------------------------------------------------------------------------------------------------------------

START_NAMESPACE_DISTRHO

// --------------------------------------------------------------------------------------------------------------------

class FadeliPlugin : public Plugin
{
    ScopedPointer<mydsp> dsp;

public:
    FadeliPlugin()
        : Plugin(kParameterCount, kProgramCount, kStateCount)
    {
        dsp = new mydsp;
        dsp->init(getSampleRate());
    }

protected:
   /* -----------------------------------------------------------------------------------------------------------------
    * Information */

   /**
      Get the plugin label.
      This label is a short restricted name consisting of only _, a-z, A-Z and 0-9 characters.
    */
    const char* getLabel() const override
    {
        return "{{label}}";
    }

   /**
      Get an extensive comment/description about the plugin.
    */
    const char* getDescription() const override
    {
        return "{{description}}";
    }

   /**
      Get the plugin author/maker.
    */
    const char* getMaker() const override
    {
        return "DISTRHO";
    }

   /**
      Get the plugin homepage.
    */
    const char* getHomePage() const override
    {
        return "https://github.com/DISTRHO/Fadeli";
    }

   /**
      Get the plugin license name (a single line of text).
      For commercial plugins this should return some short copyright information.
    */
    const char* getLicense() const override
    {
        return "{{license}}";
    }

   /**
      Get the plugin version, in hexadecimal.
    */
    uint32_t getVersion() const override
    {
        return d_version(0, 0, 0);
    }

   /**
      Get the plugin unique Id.
      This value is used by LADSPA, DSSI and VST plugin formats.
    */
    int64_t getUniqueId() const override
    {
        return d_cconst('d', 'F', 'i', 'H');
    }

   /* -----------------------------------------------------------------------------------------------------------------
    * Init */

   /**
      Initialize the audio port @a index.@n
      This function will be called once, shortly after the plugin is created.
    */
    void initAudioPort(bool input, uint32_t index, AudioPort& port) override
    {
        /* make assumptions related to IO.
         * 1 audio port means mono, 2 means stereo.
         */
        {% if inputs == outputs %}
            {% if inputs == 1 %}port.groupId = kPortGroupMono;{% endif %}
            {% if inputs == 2 %}port.groupId = kPortGroupStereo;{% endif %}
        {% else %}
            {% if inputs == 1 %}
        if (input) port.groupId = kPortGroupMono;
            {% endif %}
            {% if inputs == 2 %}
        if (input) port.groupId = kPortGroupStereo;
            {% endif %}
            {% if outputs == 1 %}
        if (!input) port.groupId = kPortGroupMono;
            {% endif %}
            {% if outputs == 2 %}
        if (!input) port.groupId = kPortGroupStereo;
            {% endif %}
        {% endif %}

        // everything else is as default
        Plugin::initAudioPort(input, index, port);
    }

   /**
      Initialize the parameter @a index.
      This function will be called once, shortly after the plugin is created.
    */
    void initParameter(uint32_t index, Parameter& param) override
    {
        switch (index)
        {
        {% for p in active %}case kParameter{{p.meta.symbol|default("" ~ loop.index)}}:
            param.hints = 0
            {% if p.type == "button" or p.meta.trigger is defined %}|kParameterIsTrigger|kParameterIsInteger{% endif %}
            {% if p.type == "checkbox" or p.meta.boolean is defined %}|kParameterIsBoolean|kParameterIsInteger{% endif %}
            {% if p.meta.integer is defined %}|kParameterIsInteger{% endif %}
            {% if p.scale == "log" %}|kParameterIsLogarithmic{% endif %}
            ;
            param.name = {{cstr(p.label)}};
            param.unit = {{cstr(p.unit)}};
            param.symbol = {{cstr(cid(p.meta.symbol|default(p.label)))}};
            param.shortName = {{cstr(p.meta.abbrev|default(""))}};
            param.ranges.def = {{p.init}};
            param.ranges.min = {{p.min}};
            param.ranges.max = {{p.max}};
            break;
        {% endfor %}
        {% for p in passive %}case kParameter{{p.meta.symbol|default("" ~ loop.index)}}:
            param.hints = kParameterIsOutput
            {% if p.meta.integer is defined %}|kParameterIsInteger{% endif %}
            {% if p.scale == "log" %}|kParameterIsLogarithmic{% endif %}
            ;
            param.name = {{cstr(p.label)}};
            param.unit = {{cstr(p.unit)}};
            param.symbol = {{cstr(cid(p.meta.symbol|default(p.label)))}};
            param.shortName = {{cstr(p.meta.abbrev|default(""))}};
            param.ranges.def = {{p.init}};
            param.ranges.min = {{p.min}};
            param.ranges.max = {{p.max}};
            break;
        {% endfor %}
        }
    }

   /* -----------------------------------------------------------------------------------------------------------------
    * Internal data */

   /**
      Get the current value of a parameter.
      The host may call this function from any context, including realtime processing.
      We have no parameters in this plugin example, so we do nothing with the function.
    */
    float getParameterValue(uint32_t index) const override
    {
        switch (index)
        {
        {% for p in active + passive %}case kParameter{{p.meta.symbol|default("" ~ loop.index)}}:
            return dsp->{{p.var}};
        {% endfor %}
        default:
            return 0.0f;
        }
    }

   /**
      Change a parameter value.@n
      The host may call this function from any context, including realtime processing.

      This function will only be called for parameter inputs.
      Since we have no parameters inputs in this example, so we do nothing with the function.
    */
    void setParameterValue(uint32_t index, float value) override
    {
        switch (index)
        {
        {% for p in active + passive %}case kParameter{{p.meta.symbol|default("" ~ loop.index)}}:
            dsp->{{p.var}} = value;
            break;
        {% endfor %}
        }
    }

   /* -----------------------------------------------------------------------------------------------------------------
    * Audio/MIDI Processing */

   /**
      Run/process function for plugins without MIDI input.
      @note Some parameters might be null if there are no audio inputs or outputs.
    */
    void run(const float** inputs, float** outputs, uint32_t frames) override
    {
        dsp->compute(frames, (float**)inputs, outputs);
    }

    // ----------------------------------------------------------------------------------------------------------------

   /**
      Set our plugin class as non-copyable and add a leak detector just in case.
    */
    DISTRHO_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(FadeliPlugin)
};

/* --------------------------------------------------------------------------------------------------------------------
 * Plugin entry point, called by DPF to create a new plugin instance. */

Plugin* createPlugin()
{
    return new FadeliPlugin();
}

// --------------------------------------------------------------------------------------------------------------------

END_NAMESPACE_DISTRHO
