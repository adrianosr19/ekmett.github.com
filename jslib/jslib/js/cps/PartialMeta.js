// PartialMeta.js (C) 2006 Edward Kmett. All Rights Reserved.
#ifndef INCLUDED_JS_CPS_PARTIALMETA
#define INCLUDED_JS_CPS_PARTIALMETA

// impure forms of js.cps.Meta methods that can be used when there
// is no risk of someone reissuing a previous continuation that involves them.
// or when we really do want to maintain a common variable between multiple partial continuations.

#include "js/cps.js"	   // js.cps
#include "js/cps/Appel.js" // APPEL

(function() { 
	function meta(m,n,f){f.$$m=m;f.$$n=n;return f} 

	const p = js.cps.PartialMeta = {
		plus:function(n,cc) { 
			if (cc.$$m==p.plus) {cc.$$n+=n;return cc} 
			return meta(p.plus,n,function _(k) { APPEL; return cc(k+_.$$n); });
		},
		times:function(n,cc) {
			if (cc.$$m==p.times){cc.$$n*=n;return cc}
			return meta(p.times,n,function _(k) { APPEL; return cc(k+_$$n); });
		}
	};

})();

#endif // INCLUDED_JS_CPS_PARTIALMETA vim:ts=4
