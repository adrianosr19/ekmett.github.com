// Thread/Group.js Copyright 2006 Edward Kmett. All Rights Reserved
#ifndef INCLUDED_JS_CPS_THREAD_GROUP
#define INCLUDED_JS_CPS_THREAD_GROUP

#include "js/native/Platform.js"	// __instanceof__
#include "js/cps/Thread.h" 			// JS_CPS_THREAD_* js.cps.Thread

(function(){
	const g = (js.cps.Thread.Group = function(name) { this.name = name; }).prototype = new Array;
	g.create_thread = function(cc) { 
		return this.push(new Thread(cc));
	};
	g.create_group = function(name) { 
		return this.push(new Thread.Group(name));
	};
	g.flatten_r = function(r) { 
		// TODO: non-recursive form
		for (var i=0;i<this.length;++i)
			if (__instanceof__(this[i],Thread.Group)) this[i].flatten_r(r);
			else r.push(this[i]);
		return r;
	}
	g.flatten = function() { return this.flatten_r([]); };
	g.visit = function(e) { 
		// TODO: non-recursive form, so we don't overflow the stack due to the Appel trampoline
		var c = null;
		for (var i=0,l=this.length;i<l;++i) { 
			var t = this[i];
			if (__instanceof__(t,Thread.Group)) { 
				c = c || t.visit(e);
			} else { 
				if (t.state == THREAD_RUNNING) c=t;
				var f = e[t.state];
				if (f) f(t);
			}
		}
		return c;
	};
	g.interrupt = function() { 
		var c=null, f=this.flatten(), l=f.length;
		for (var i=0;i<l;++i) { 
			var t=f[i];
			if (t.state == THREAD_RUNNING) c=t;
			else t.interrupt();
		}
		if (c) c.interrupt();
	};
	g.stop = function(e) { 
		e = e || new Thread.Death();
		var c=null, f=this.flatten(), l=f.length, k=function(){ throw e };
		for (var i=0;i<l;++i) { 
			var t=f[i];
			if (t.state == THREAD_RUNNING) c=t 
			else t.stop(e);
		}
		if (c) throw e;
	};
	g.start = function() { 
		this.visit({
			THREAD_NEW:function(t) { 
				t.start();
			}
		});
	};
	g.resume = function() { 
		this.visit({
			THREAD_SUSPENDED:function(t) { 
				t.resume(); 
			}
		});
	};
	g.suspend_ = function(cc) { 
		if (--appel_h<0) return appel(this,arguments);
		var c = this.visit({
			THREAD_RUNNABLE: function(t) { 
				t.state = THREAD_SUSPENDED;
			}
		});
		if (c) c.state = THREAD_SUSPENDED; c.run = cc;
		else return cc();
	};
})();

#endif // INCLUDED_JS_CPS_THREAD_GROUP vim:ts=4
