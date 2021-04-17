#ifndef INCLUDED_JS_NATIVE_FUNCTION
#define INCLUDED_JS_NATIVE_FUNCTION
if (!(function(){}).toSource) Function.prototype.toSource = function() { return this.toString(); }
#endif
