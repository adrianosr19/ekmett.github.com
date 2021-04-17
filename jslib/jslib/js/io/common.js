#ifndef INCLUDED_JS_IO_COMMON
#define INCLUDED_JS_IO_COMMON

#include "js/io.js"
// @class js.io.IOException
// @class js.io.EOFException
(function(){
	const 	i = js.io, 
	    	t = function(e) { return this.e; },
	    	x = i.IOException = function(e) {this.e="IOException: " + e},
	    	y = i.EOFException = function(e) {this.e="EOFException: " + e},
	    	p = x.prototype = y.prototype = { toString: t },
})();
#endif // vim:ts=4
