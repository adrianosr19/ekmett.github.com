#ifndef INCLUDED_JS_UTIL_DISJOINTSET
#define INCLUDED_JS_UTIL_DISJOINTSET

#include "js/util.js"

(function(){
	const p=(js.util.DisjointSet=function(){}).prototype=new Array;
	p.alloc=function(){this[this.length]=-1;return this.length++;};
	p.make=function(x){this[x]=-1};
	p.find=function(x){return this[x]<0?x:this[x]=this.find(this[x])};
	p.union=function(x,y){
		x=this.find(x);y=this.find(y);
		if(this[x]<this[y]){this[y]+=this[x];this[x]=y;}
		else{this[x]+=this[y];this[y]=x;}
	};
})();

#endif // INCLUDED_JS_UTIL_DISJOINTSET vim:ts=4
