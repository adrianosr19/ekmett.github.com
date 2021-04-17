#ifndef INCLUDED_JS_NATIVE_BOOLEAN
#define INCLUDED_JS_NATIVE_BOOLEAN
if (!(true).toSource) Boolean.prototype.toSource = function() { return this.toString(); }
#endif
