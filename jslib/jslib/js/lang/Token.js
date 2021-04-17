#ifndef INCLUDED_JS_LANG_TOKEN
#define INCLUDED_JS_LANG_TOKEN

#include "js/native/Platform.js" 		// __*__
#include "js/lang.js"
#include "js/lang/Token.h"

(function () { 
	var t = js.lang.Token = function (t,v) { this.t = t; this.v = v; }, 
		tmap = {
			1:"statement", 	2:"statements",	3:"identifier",		4:"literal",
			5:"label",		6:"end-of-file",7:"start-of-file",	8:"function call",		
			9:"array",		10:"object", 	20:"for..in", 		21:"for each..in"
		}, 
		z = t.handlers = { 
			$empty: 	{p:function(t){return ";"},v:"",l:JS_LANG_TOKEN_STATEMENT},
			$block: 	{p:function(t){return "{"+t.b+"}"},v:"b",l:JS_LANG_TOKEN_STATEMENT},
			$var: 		{p:function(t){return "var "+t.vars+";"},v:"vars",l:JS_LANG_TOKEN_STATEMENT},
			$if: 		{p:function(t){return "if "+t.cond+t.thn+(t.els? "else "+t.els :"")},v:"cond thn els",l:JS_LANG_TOKEN_STATEMENT},
			$do: 		{p:function(t){return "do "+t.loop+"while "+t.cond+";"},v:"loop cond",l:JS_LANG_TOKEN_STATEMENT,t:JS_LANG_TOKEN_LOOP}, 
			$while: 	{p:function(t){return "while"+t.cond+t.loop; },v:"cond loop",l:JS_LANG_TOKEN_STATEMENT,t:JS_LANG_TOKEN_LOOP}, 
			$continue: 	{p:function(t){return "continue "+(t.label||"")+";"},v:"label",l:JS_LANG_TOKEN_STATEMENT},
			$array:		{p:function(t){return "["+t.b+"]"},v:"b",t:JS_LANG_TOKEN_LITERAL,l:JS_LANG_TOKEN_EXPR},
			$object:	{p:function(t){return "{"+t.b+"}"},v:"b",t:JS_LANG_TOKEN_LITERAL,l:JS_LANG_TOKEN_EXPR},
			$break: 	{p:function(t){return "break "+(t.label||"")+";"},v:"label",l:JS_LANG_TOKEN_STATEMENT},
			$return:	{p:function(t){return "return "+(t.expr||"")+";"},v:"expr",l:JS_LANG_TOKEN_STATEMENT},
			$throw: 	{p:function(t){return "throw "+t.expr+";"},v:"expr",l:JS_LANG_TOKEN_STATEMENT},
			$with: 		{p:function(t){return "with "+t.expr+t.stmt},v:"expr stmt",l:JS_LANG_TOKEN_STATEMENT},
			$func: 		{p:function(t){return "function "+(t.name||"")+"("+t.a+") {"+t.b+"}"},v:"b",l:JS_LANG_TOKEN_EXPR},
			$try:		{p:function(t){return "try{"+t.b+"}"+(t.c?"catch("+t.cvar+"){"+t.c+"}":"")+(t.f?"finally{"+t.f+"}":"")},v:"b c f",l:JS_LANG_TOKEN_STATEMENT},
			$switch: 	{p:function(t){return "switch "+t.expr+"{"+t.cases+"}"},v:"expr cases",l:JS_LANG_TOKEN_STATEMENT},
			$case: 		{p:function(t){return "case "+t.expr+":"+t.stmts},v:"expr stmts",l:JS_LANG_TOKEN_FRAG},
			$default:	{p:function(t){return "default:"+t.stmts},v:"stmts",l:JS_LANG_TOKEN_FRAG},
			$label: 	{p:function(t){return t.label+": "+t.stmt},v:"label stmt",l:JS_LANG_TOKEN_STATEMENT},
			$expr_stmt:	{p:function(t){return t.expr+";"; },v:"expr",l:JS_LANG_TOKEN_STATEMENT},
			$vdecl:		{p:function(t){return t.v+"="+t.init},v:"init",l:JS_LANG_TOKEN_FRAG},
			$prop: 		{p:function(t){return t.v+":"+t.init},v:"init",l:JS_LANG_TOKEN_FRAG},
			$stmts: 	{p:function(t){return t.join("")},v:"stmts",l:JS_LANG_TOKEN_FRAG}, 
			$pexpr: 	{p:function(t){return "("+t.expr+")"},v:"expr",l:JS_LANG_TOKEN_EXPR},
			$ident: 	{p:function(t){return t.v},v:"",l:JS_LANG_TOKEN_EXPR},
			$call: 		{p:function(t){return t.f+"("+t.a+")"},v:"f a",t:JS_LANG_TOKEN_ARGS,l:JS_LANG_TOKEN_EXPR},
			$bracket:	{p:function(t){return t.l+"["+t.r+"]"},v:"l r",t:JS_LANG_TOKEN_BINARY,l:JS_LANG_TOKEN_EXPR},
			$lit: 		{p:function(t){return t.v},v:"",t:JS_LANG_TOKEN_LITERAL,l:JS_LANG_TOKEN_EXPR},
			$this: 		{p:function(t){return t.v},v:"",l:JS_LANG_TOKEN_EXPR},
			$boolean:	{p:function(t){return t.t},v:"",t:JS_LANG_TOKEN_BOOLEAN},
			$null:		{p:function(t){return t.t},v:"",t:JS_LANG_TOKEN_NULL},
			$binary: 	{p:function(t){return t.l+t.t+t.r},v:"l r",t:JS_LANG_TOKEN_BINARY,l:JS_LANG_TOKEN_EXPR},
			$binary_rl:	{p:function(t){return t.l+t.t+t.r},v:"r l",t:JS_LANG_TOKEN_BINARY,l:JS_LANG_TOKEN_EXPR},
			$binary_kw:	{p:function(t){return t.l+" "+t.t+" "+t.r},v:"l r",t:JS_LANG_TOKEN_BINARY,l:JS_LANG_TOKEN_EXPR},
			$pre: 		{p:function(t){return " "+t.t+t.expr},v:"expr",t:JS_LANG_TOKEN_PREFIX,l:JS_LANG_TOKEN_EXPR},
			$pre_kw: 	{p:function(t){return " "+t.t+" "+t.expr},v:"expr",t:JS_LANG_TOKEN_PREFIX,l:JS_LANG_TOKEN_EXPR},
			$post: 		{p:function(t){return t.expr+t.t+" "},v:"expr",t:JS_LANG_TOKEN_POSTFIX,l:JS_LANG_TOKEN_EXPR}, 
			$new: 		{p:function(t){return " new "+t.f+(t.a?("("+t.a.join(",")+")"):"")},v:"a f",t:JS_LANG_TOKEN_ARGS,l:JS_LANG_TOKEN_EXPR},
			$tie:		{p:function(t){return t.join(",");},v:"",t:JS_LANG_TOKEN_NARY,l:JS_LANG_TOKEN_FRAG},
			$star:		{p:function(t){return t.join("");},v:"",t:JS_LANG_TOKEN_NARY,l:JS_LANG_TOKEN_FRAG},
			$for_each:	{p:function(t){return "for each ("+t.v+" "+t.l+" in "+t.r+")"+t.loop},v:"iter loop",t:JS_LANG_TOKEN_LOOP,l:JS_LANG_TOKEN_STATEMENT},
			$for_in: 	{p:function(t){return "for ("+t.v+" "+t.l+" in "+t.r+")"+t.loop},v:"iter loop",t:JS_LANG_TOKEN_LOOP,l:JS_LANG_TOKEN_STATEMENT},
			
			$for_c: 	{p:function(t){return "for ("+(t.init+";").replace(new RegExp(";;$"),";")+t.cond+";"+t.next+")"+t.loop},t:JS_LANG_TOKEN_LOOP,l:JS_LANG_TOKEN_STATEMENT,
						 v:"expr1 cond mod loop"}
		};	
	for (var i in z) z[i].v = z[i].v.split(/ /);
	t.prototype = { 
		toString : function() { return this.h ? this.h.p(this) : this.v || this.t; },
		type : function() { return tmap[this.t]||this.t; },
	};
	((t.Array=function(h){this.h=h}).prototype = new Array).toString = function() { 
		return this.h.p(this); 
	};
})();
#endif // INCLUDED_JS_LANG_TOKEN vim:ts=4
