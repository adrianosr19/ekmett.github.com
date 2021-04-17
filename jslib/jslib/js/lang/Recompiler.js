// CPS Recompiler (C) 2006 Edward Kmett. All Rights Reserved.

#ifndef INCLUDED_JS_LANG_RECOMPILER
#define INCLUDED_JS_LANG_RECOMPILER

#include "js/lang/Parser.js"
#include "js/lang/Recompiler.h"
#include "js/util/DisjointSet.js"

#define mutable_tokens  mt
#define constant_binary cb
#define constant_unary  cu
#define constant_terms  ct
#define expression_like el

(function () { // implementation
var mt={'{':1,'function':1,'this':1,'.':1,'[':1,'+=':1,'-=':1,'*=':1,'/=':1,'%=':1,'<<=':1,'>>=':1,'>>>=':1,'&=':1,'^=':1,'|=':1,'++':1,'--':1,3:1,8:1},
	cb={',':1,'||':1,'&&':1,'|':1,'^':1,'&':1,'==':1,'!=':1,'===':1,'!==':1,'<':1,'<=':1,'>':1,'>=':1,'<<':1,'>>':1,'>>>':1,'+':1,'-':1,'*':1,'/':1,'%':1},
	cu={'typeof':1,'void':1,'+':1,'-':1,'~':1,'!':1,'(':1},
	ct={4:1,'?':1,'true':1,'null':1,'false':1},
	expression_like={expr:1,uexpr:1,mexpr:1,aexpr:1,primary:1,func:1},
	Set=js.util.DisjointSet;

var j = js.lang
	jp = j.Parser,
	jpp = jp.prototype, 
	Token = j.Token,
	Recompiler = j.Recompiler = function(source,mode) {
			this.mode=mode||DEFAULT_MODE;
			jsp.call(this,source);
	}, 
	p = Recompiler.prototype = new jpp;

p.primary = function() { 
	var r = jspp.primary.apply(this,arguments); 
	if (r) r.primary = true; 
	return r; 
};

p.recompile = function(f,ctx) { 
	var tree = this[f](), sentinel={}, s;
	f=f||"parse";
	ctx=ctx||new Context();
	if (!tree) return tree;
	if (expression_like[f]) { 
		var sentinel = {};
		if (!partial_fold(tree,sentinel,"value")) tree = sentinel.value; // DONE!
	} 
	if (tree.t == JS_LANG_TOKEN_STMTS) { 
		var s=tree;
		(tree=new js.Token(JS_LANG_TOKEN_SCRIPT)).body = s;
	}
	recompile(tree,sentinel,"flowgraph",ctx);
		
	return tree;
};

#include "js/lang/Recompiler/CToken.inc"
#include "js/lang/Recompiler/ConstantFolding.inc"
#include "js/lang/Recompiler/Flowgraph.inc" // flatten recompile
#include "js/lang/Recompiler/Context.inc"

function cps_ident(s) {
	return s.match(/_$/)
}
function cps_arg_string(a,v) { 
	a.push(v); 
	var r = a.toString(); 
	a.pop(v); 
	return r 
}
function appel_prologue(c){
	return(c<=1?"if(--appel_h":"if(appel_h-="+(c>500?500:c))+"<0)return appel(this,arguments);"}

})(); // end implementatioon

#endif // INCLUDED_JS_LANG_RECOMPILER vim:ts=4
