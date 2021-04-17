#ifndef INCLUDED_JS_NATIVE_OBJECT
#define INCLUDED_JS_NATIVE_OBJECT
#include "js/native/Platform.js"
// if HAS_PROTO we can do better
if(!{}.hasOwnProperty) Object.prototype.hasOwnProperty=function(x){return this[x]!={}[x];}; 
if (!{}.toSource) Object.prototype.toSource = function() {
	if (this.marked) return "#marked";
	this.marked = 1;
	var s=[];
	for (var i in this) {
		if (this.hasOwnProperty(i) && i != "marked") {
			switch (typeof(this[i])) { 
			case "undefined": s.push(i+":undefined"); break;
			case "object": s.push(i+":"+(this[i]?this[i].toSource():"null")); break;
			default: s.push(i+":"+this[i].toSource()); break;
			}
		}
	}
	__delete__(this,marked);
	return "{"+s.join(",")+"}";
}
#endif
