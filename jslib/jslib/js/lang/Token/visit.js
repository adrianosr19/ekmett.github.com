// Javascript Parser (C) 2006 Edward Kmett. All Rights Reserved.
#ifndef INCLUDED_JS_TOKEN_VISIT
#define INCLUDED_JS_TOKEN_VISIT

#include "js/lang/Token.h"

(function(t){ // t=js.lang.Token
	t.prototype.visit=function(f,d){ 
		if (!this.h) {
			print(this.toSource());
			return null;
		}
		var r=null,v=this.h.v,l=v.length,i=0;
		for (;i<l;++i) r=r||this[v[i]]&&f(this[v[i]],d,this,v[i]);
		return r;
	};
	t.Array.prototype.visit=function(f,d){
		var r=null,i=0,l=this.length;
		for (;i<l;++i) r=r||this[i]&&f(this[i],d,this,i);
		return r;
	};
})(js.lang.Token);
#endif // INCLUDED_JS_TOKEN_VISIT vim:ts=4
