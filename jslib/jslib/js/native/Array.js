#ifndef INCLUDED_JS_NATIVE_ARRAY
#define INCLUDED_JS_NATIVE_ARRAY
#include "js/native/Platform.js"
#include "js/native/Array/push.js"
#include "js/native/Array/join.js"
if (![].toSource) Array.prototype.toSource = function() { 
	if (typeof(this.marked)!="undefined") return "_";
	this.marked = 1;
	var s = [];
	for  (var i=0;i<this.length;++i) { 
		switch (typeof(this[i])) { 
		case "undefined": 	s.push("undefined");
		case "object": 		s.push(this[i]?this[i].toSource():"null");
		default: 		s.push(this[i].toSource());
		};
	}
	__delete__(this,marked);
	return "["+s.join(",")+"]";
};
#endif
