// Javascript Atomizer (C) 2006 Edward Kmett. All Rights Reserved.
#ifndef INCLUDED_JS_LANG_ATOMIZER
#define INCLUDED_JS_LANG_ATOMIZER

// Usage: creates an atomized version of a syntax tree.
// call preserve on any source code that must have its interface
// unmodified. Then you can intern all of the implementation source 
// code, and finally atomize the code to obtain code that will 
// comply with the interface from the preserved code, and not conflict
// with the variables in the interned code. You can pre-bake
// atoms by passing them as a hash to the atomizer. The atomizer
// will take ownership of that hash and destructively modify it
// however. The hash should map identifier names onto their new 
// values. The result is still a syntax tree, so you can perform
// further passes on it.

#include "js/native/Platform.js"// __*__, HAS_EXCEPTIONS
#include "js/lang.js"
#include "js/lang/Parser.js" 	// js.lang.Parser
#include "js/lang/Token.js"	 	// js.lang.Token
#include "js/lang/Token/visit.js"

(function (g) {
	function h(s,r) { 
		s=s.split(/ /);
		for (var i=0;i<s.length;++i) r[s[i]]=s[i];
		return r;
	}
	function c(h) { 
		var r = {};
		for (var i in h) { 
			r[i]=h[i];
		}
		return r;
	}
	var has = {}.hasOwnProperty;
	// Todo: true false null should never get here!
	// Todo: approach this list more rigorously
	var da = h("undefined each get set hasOwnProperty window document prototype __proto__ "+
			   "true false null exec match body setTimeout getElementById RegExp String Function Error URIError SyntaxError ReferenceError "+
			   "slice print Array split join push pop arguments getter setter toString toSource toFixed valueOf onload onclick Math sin cos pow log",{});
	var jl=js.lang,$a=function(){},a=jl.Atomizer=function(a){ 
		var o = this.atoms = c(da), u = this.used = {};
		for (var i in a) o[i] = a[i];
		for (var i in o) u[i] = o[i];
		this.i = -1;
	}, p = a.prototype;
	p.intern   = function(t) { intern(t,this); return t};
	p.atomize  = function(t) { intern(t,this); atomize(t,this); return t};
	p.preserve = function(t) { preserve(t,this); return t};
	
	p.resolve = function(t) { 
		if (has.call(this.atoms,t)) return this.atoms[t];
		var r = t.length<3?t:v(++this.i); //t.length<3?t:v(++this.i);
		while (this.used[r] && r != t) r = v(++this.i);
		return this.atoms[t] = this.used[r] = r;
	};
	function preserve(t,a) { 
		switch(t.t) { 
		case JS_LANG_TOKEN_IDENT:
			if (t.t!=JS_LANG_TOKEN_IDENT) 
			if (!has.call(a.atoms,t.v)) a.atoms[t.v]=t.v;
			return null;
		case "function":
			if (t.name) preserve(t.name,a);
		default:
			return t.visit(preserve,a);
		};
	}
	function intern(t,a) {
		switch (t.t) { 
		case JS_LANG_TOKEN_IDENT:
			a.used[t.v]=1;
			return null;
		case "function":
			if (t.name) intern(t.name,a);
		default:
			return t.visit(intern,a);
		};
	}
	function atomize(t,a) { 
		switch (t.t) { 
		case JS_LANG_TOKEN_IDENT:
			var p = has.call(a.atoms,t.v);
			var u = t.v;
			t.v = a.resolve(t.v);
			if (!p) print("//"+u+":"+t.v);
			if (!t.init) return null;
			return t.visit(atomize,a);
		case "function":
			if (t.name) atomize(t.name,a);
		default:
			return t.visit(atomize,a);
		};
	}
	var x='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_$',y=x+'0123456789'
	function v(i) { 
		var a = x.length, b = y.length;
		if (i<a) return x[i];
		i-=a;
		if (i<a*b) return x[i%a]+y[parseInt(i/a)];
		i-=a*b;
		if (i<a*b*b) return x[i%a]+y[parseInt(i/a)%b]+y[parseInt(i/(a*b))];
		throw a.Error("Too many atoms");
	}
})(this);
#endif // vim:ts=4
