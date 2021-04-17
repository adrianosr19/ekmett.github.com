// Timer (C) 2006 Edward Kmett. All Rights Reserved.
// Used to share a single setTimeout between a very large number of timers
#ifndef INCLUDED_JS_UTIL_TIMER
#define INCLUDED_JS_UTIL_TIMER

#ifndef PLATFORM_BROWSER
#ifndef MAKEDEPEND
#error "js.util.Timer requires a browser"
#endif
#endif

#include "js/util.js"
#include "js/util/Heap.js"

(function(){
	const u=js.util,t= u.Timer = new u.Heap(function($1,$2){return $1.p<$2.p});
	// private
	var timer = null;
	function now() {
		return new Date().getTime();
	}
	function tick() { 
		var w = now(), n=this.top();
		do { 
			if (!n.c) n.f();
			if (n.e) {
				n.p+=n.e;
				this.heapify(1);
			} else { 
				this.pop();
			}
			if (!(n=this.top())) return;
		} while(n.p<=w);
		t=n.p-now();
		this.timer = window.setTimeout(tick,t>0?t:1);
	}
	// member func on individual timers returned.
	function clear(){ 
		this.c=1; 
	}

	// public
	t.reset = function(k,f,ms) {
		// Todo: search for key?
	};
	t.clear_all	= function() { 
		if (this.treap.top()) window.clearTimeout(this.timer);
		this.heap.make_empty();
	};
	t.at = function(f,when,e) { 
		const n = now(), when=when||n, t = Timer.top(),ms=when-now;
		if (!t) {
			this.timer = window.setTimeout(tick,ms);
		} else if (when<t.p) {
			window.clearTimeout(this.timer);
			this.timer = window.setTimeout(tick,ms);
		} 
		// return an opaque timer object with a clear method.
		const r = {f:f,e:e,c:0,p:when,e:k,clear:clear};
		Timer.push(r);
		return r;
	},
	t.set = function(k,f,ms,delta) { 
		return this.at(k,f,now()+ms,delta);
	},
	t.time = function(f) { 
		const s = now();
		f();
		const t = now();
		return t-s;
	}
})();

#endif // vim6:ts=4
