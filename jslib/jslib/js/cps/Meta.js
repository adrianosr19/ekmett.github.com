// Meta.js (C) 2006 Edward Kmett. All Rights Reserved.
#ifndef INCLUDED_JS_CPS_META
#define INCLUDED_JS_CPS_META

// basic meta-continuations for simple repeatedly performed operations.

#include "js/cps.js"	   // js.cps
#include "js/cps/Appel.js" // APPEL

js.cps.Meta = {
	plus:function(n,cc) { return function(k) { APPEL; return cc(k+n)}},
	times:function(n,cc) { return function(k) { APPEL; return cc(k*n)}},
	or_n:function(n,cc) { return function(k) { APPEL; return cc(k||n)}},
	or:function(n,cc) { return function(k) { APPEL; return cc(n||k)}},
	and_n:function(n,cc) { return function(k) { APPEL; return cc(k&&n)}},
	and:function(n,cc) { return function(k) { APPEL; return cc(n&&k)}}
};

#endif // INCLUDED_JS_CPS_META vim:ts=4
