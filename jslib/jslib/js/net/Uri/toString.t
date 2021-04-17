#include "js/test/Simple.js"
#include "js/net/Uri.js"

var t = [
    'http://user:pass@host:90/path1/path2?query=param#frag',
    'http://www.slashdot.org/',
    'http://www.slashdot.org?foo',
    'http://www.slashdot.org:80/',
    'this/is/relative.html',
    'this/is/relative.cgi?param=foobar',
    'mailto:ekmett@gmail.com'
];

plan(t.length);
for (var i=0;i<t.length;++i) {
    try {
        var r = new js.net.Uri(t[i]);
        ok(t[i]==r.toString());
    } catch(e) {
        ok(false,undefined,e+": Failed with "+ t[i]);
    }
}
