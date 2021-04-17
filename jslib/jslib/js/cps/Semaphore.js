#ifndef INCLUDED_JS_LANG_SEMAPHORE
#define INCLUDED_JS_LANG_SEMAPHORE

#include "js/lang.js"

(function(){
	const l=js.cps,s=(l.Semaphore = function (n) { this.n = n||0; }).prototype = new Array;
	s.P_ = function(cc) { 
		if (--appel_h<0) return appel(this,arguments,1);
		if (--this.n<0){
			var t = l.Thread.current;
			this.push(t);
			return t.block_(this,cc);
		}
		return cc();
	};
	s.V = function() { 
		if (++this.n<=0) this.shift().unblock();
	};
	s.wait_ = function(cc) {
		if (--appel_h<0) return appel(this,arguments,1);
		--this.n;
		this.push(l.Thread.current)
		return l.Thread.block_(this.cc);
	};
	s.notify = function() {  // wake one
		++this.n;
		var t = this.shift();
		if (t) t.unblock();
	};
	s.notify_all = function() { // wake all in queue
		this.n+=this.length;
		for (var i=0,l=this.length;i<l;++i) { 
			this[i].unblock();
		}
		this.length = 0;
	};
	s.interrupt = function(t) { 
		++this.n;
		for (var i=0,l=this.length;i<l;++i): { 
			var c = this[i];
			if (c.id == t.id) { 
				this.splice(c.id,1);
				this[i].unblock();
				return;
			}
		}
	};
#ifdef DEBUG
	s.toString = function() { return "Semaphore{ n:"+this.n+", threads: ["+this.join(",")+"]}"; };
#endif
})();

#endif // INCLUDED_JS_LANG_SEMAPHORE vim:ts=4
