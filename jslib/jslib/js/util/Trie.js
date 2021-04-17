// Trie Copyright (C) 2006 by Edward Kmett. 
// Public Domain Code based on Regexp::Trie by Dan Kogai.
#ifndef INCLUDED_JS_UTIL_TRIE
#define INCLUDED_JS_UTIL_TRIE

#include "js/util.js"

(function(){
	function quote(t) { return t.replace(/[?|^&(){}\[\]+\-*\/\.]/g, "\\$&"); };
	function compile_regexp(r) { 
		var l=r.array.length,alt=[],cc=[],c,re,q=0;
		if (!l&&r.__) return null;
		for (var i=0;i<l;++i) { 
			c = r.array[i].chr;
			if (r[c])
				if (re = compile_regexp(r[c])) alt.push(quote(c)+re);
				else cc.push(quote(c));
		}
		q = r.__?1:0;
		var cconly = !alt.length;
		if (cc.length !=0) alt.push(cc.length == 1 ? cc[0] : '['+cc.join('')+']');
		var result = alt.length == 1 ? alt[0] : '(?:' + alt.join('|') + ')';
		if (q) result = cconly ? result + "?" : "(?:"+result+")?";
		return result;
	}

	(js.util.Trie = function() {
		this.count=0;
		this.array = [];
		this.chr = '';
		for (var i=0,l=arguments.length;i<l;++i) this.add(arguments[i]);
	}).prototype = {
		add : function(s) { 
			const a = s.split('');
			var r = this;
			for (var i=0,l=a.length;i<l;++i) { 
				var c=a[i];
				if (!r[c]) {
					r[c]={chr:c,count:0,array:[]};
					r.array.push(r[c]);
				}
				r=r[c];
			}
			r.__ = 1;
			return r;
		},
		regexp : function() { 
			return new RegExp(compile_regexp(this));
		}
	}
})();
#endif // INCLUDED_JS_UTIL_TRIE vim6:ts=4
