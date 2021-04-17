#include "js/test/Assert.js"
#include "js/test/Simple.js"
plan(2);
assert(1==1);
ok(1);
try { 
assert(1==0);
} catch(e) { 
	ok(e.e == '1==0');
}
