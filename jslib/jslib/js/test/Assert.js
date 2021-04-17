#ifndef INCLUDED_JS_TEST_ASSERT
#define INCLUDED_JS_TEST_ASSERT

#include "js/test.js"
#include "js/test/Assert.h"

(function(){
	var a = js.test.Assert = {};
	(a.Error = function(e,file,line,t){
		this.e = e;
		this.file = file;
		this.line = line;
		this.t = t || "assertion";
	}).prototype.toString = function() {
		return this.file+":"+this.line+":" + this.t + " failed '"+this.e+"'\n";
	};
	a.fail = function(e,file,line){ 
		throw new a.Error(e,file,line);
	};
})();

#endif
