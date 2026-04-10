## 0.8.0















* **BREAKING**: public header no longer auto-includes mulle-dlfcn — callers must include/provide dl symbols themselves
* removed bundled dlfcn-win32 and internal mulle-dlfcn sources; projects must supply platform dl implementation or dependency
* enforce `MULLE__CORE__ALL__LOAD_BUILD` at compile time — builds without this macro now fail
