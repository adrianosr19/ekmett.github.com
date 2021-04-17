#ifndef INCLUDED_JS_LANG_TOKEN_TREE
#define INCLUDED_JS_LANG_TOKEN_TREE

#include "js/lang/Parser.js"
#include "js/lang/Token.js"
(function(t){ // t = js.lang.Token
	var p = t.prototype,a=t.Array.prototype;
	p.tree_r = function(_1,_2,_3,role) { 
		var r = _2+role+":"+this.type(), i=0,v=this.h.v,l=v.length;
		if (this.v && this.v != this.type()) r += "/"+this.v;
		r = r+"\n";
		for (;i<l;++i)
			if (this[v[i]])
				if (i<l-1) r += this[v[i]].tree_r(_1+"|  ",_1+'+--',_1+'   ',v[i]);
				else r += this[v[i]].tree_r(_1+"   ",_1+"`--",_1+'   ',v[i]);
		return r;
	};
	a.tree_r = function(_1,_2,_3,role) {
		var r = _2+role+"(array)"+tmap[this.h.t]+"\n",i=0,v=this,l=this.length;
		for (;i<l;++i) 
			if (i<l-1) r += v[i].tree_r(_1+"|  ",_1+'+--',_1+'   ',i);
			else r += v[i].tree_r(_1+"   ",_1+"`--",_1+'   ',i);
		return r;
	};
	p.tree = a.tree = function() { return this.tree_r('','','',''); };
})(js.lang.Token);
#endif // INCLUDED_JS_LANG_TOKEN_TREE vim:ts=4
