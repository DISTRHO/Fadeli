{% block HeaderDescription %}
//------------------------------------------------------------------------------
// This file was generated using the Faust compiler (https://faust.grame.fr),
// and the Faust post-processor (https://github.com/jpcima/faustpp).
//
// Source: {{file_name}}
// Name: {{name}}
// Description: {{description}}
// Author: {{author}}
// Copyright: {{copyright}}
// License: {{license}}
// Version: {{version}}
//------------------------------------------------------------------------------
{% endblock %}

{% block HeaderPrologue %}
{% if not (lv2uri is defined) %}
{{fail("`lv2uri` is undefined.")}}
{% endif %}
{% endblock %}

#pragma once

#define DISTRHO_PLUGIN_NAME {{cstr(name)}}
#define DISTRHO_PLUGIN_URI  {{cstr(lv2uri)}}

#define DISTRHO_PLUGIN_HAS_UI          0
#define DISTRHO_PLUGIN_IS_RT_SAFE      1
#define DISTRHO_PLUGIN_NUM_INPUTS      {{inputs}}
#define DISTRHO_PLUGIN_NUM_OUTPUTS     {{outputs}}

enum Parameters {
    {% for p in active + passive %}kParameter{{p.meta.symbol|default("" ~ loop.index)}},
    {% endfor %}kParameterCount
};

enum Programs {
    kProgramCount
};

enum States {
    kStateCount
};

{% block HeaderEpilogue %}
{% endblock %}
