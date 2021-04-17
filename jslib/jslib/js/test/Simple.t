#include "js/test/Simple.js"

plan(6);
ok(1);
ok(1,"named");
ok(1,"named","worked fine");
skip(1);
todo(1);
var p = print;
var print = function(s) { 
	if (s.indexOf("not ok 6")>=0)  p("ok 6 testing_ok # "+s);
}
ok(0);
// vim:ts=4
