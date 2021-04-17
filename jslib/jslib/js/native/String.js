#ifndef INCLUDED_JS_NATIVE_STRING
#define INCLUDED_JS_NATIVE_STRING

// todo finish
if (!"".toSource) String.prototype.toSource = function() { return '"'+this.toString()+'"'; }

#endif
