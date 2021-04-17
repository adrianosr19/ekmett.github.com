#include "js/test/Simple.js"
#include "js/net/Uri.js"

var t = {
    '/./foo' : '/foo',
    '/bar/../foo' : '/foo',
    'http://www.slashdot.org/../foo' : 'http://www.slashdot.org/../foo',
	"http://slipwave.com/test/../foo.cgi?query=param#frag" : "http://slipwave.com/foo.cgi?query=param#frag"
};

var tests = 0;
for (var i in t) { 
	tests++;
}

plan(tests);
for (var i in t) {
    try {
        var r = new js.net.Uri(i);
	var n = r.normalize().toString();
	ok(n==t[i],undefined,n+'<=>'+t[i]);
    } catch(e) {
        ok(false,undefined,e+": Failed with "+ t[i]);
    }
}

// vim:ts=4
