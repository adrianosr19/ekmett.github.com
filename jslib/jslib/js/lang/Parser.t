#include "js/lang/Parser.js"

print("1..1");
var o = new js.lang.Parser(js.lang.Parser.toSource()).parse().toString();
print("ok 1");
print("END")

// vim:ts=4
