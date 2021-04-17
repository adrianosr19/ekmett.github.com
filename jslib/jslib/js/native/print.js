#ifndef INCLUDED_JS_NATIVE_PRINT
#define INCLUDED_JS_NATIVE_PRINT

// todo: alert and document.write, etc
var print = print || function(x){WScript.StdOut.Write(x.toString()+"\n")};

#endif
