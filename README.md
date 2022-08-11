# DPF-Fadeli

Work-in-progress! It does not build/work yet.  
Final expected readme contents follow after this message.

---

An experiment with Faust Demo Library content as DPF plugins.

Basically glueing a few different projects together:

1. [DPF](https://github.com/DISTRHO/DPF)
2. [faust](https://faust.grame.fr/)
3. [faustpp](https://github.com/jpcima/faustpp)
4. [faust examples](https://faustdoc.grame.fr/examples/reverb/)

Any faust file placed in the `dsp/` directory is automatically added as part of the build.  
The template files in `template/` directory are passed through `faustpp` that converts the faust dsp file into a buildable DPF-based audio plugin.  
Then DPF takes care of the rest, producing LADSPA, LV2, VST2 and VST3 plugins in one go.

While it might be tempting, please do not bother packaging this repository and plugin set.  
It really only serves as a demo and showcase for DPF and faustpp.  
The included faust dsp files are all demo/examples, just to get a starting point and something usable for testing.

Feel free to reuse this repository to build your own set of plugins though.
