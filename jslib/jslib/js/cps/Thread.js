// Thread.js Copyright 2006 Edward Kmett. All Rights Reserved
#ifndef INCLUDED_JS_CPS_THREAD
#define INCLUDED_JS_CPS_THREAD

// Todo: remove reliance upon exceptions and just return the answer

#include "js/native/Platform.js"// __instanceof__
#include "js/cps.js"			// js.cps
#include "js/cps/Appel.js"		// APPEL*
#include "js/cps/Thread.h"		// JS_CPS_THREAD_*
#include "js/cps/Semaphore.js"  // js.cps.Semaphore
#include "js/util/Timer.js"		// js.util.Timer

(function() {
	const j=js.cps,t=j.Thread=function(k){ 
		this.run = k;
		this.id = ++t._id;
		this.root = this;
		this.name = "Thread_"+this.id;
		this.exit_condition = new j.Semaphore();
	};

	t.event_thread = t.current = new t(function(){
		throw new t.Error("Event-Sentinel Thread was run directly")
	});

	t.current.state = JS_CPS_THREAD_RUNNING;
	t.current.name = "Event-Sentinel Thread";

	t.queue = [];
	t.id = function() { return t.current.id; };

	t.Death = function() {};
	t.Death.prototype.toString = function() { return "Thread.Death"; }
	t.Error = function(m) { this.message = m; }
	t.Error.prototype.toString = function() { return "Thread.Error: " + this.message; };
	t.Interrupted = function(m) { this.message = m; };
	t.Interrupted.prototype = function() { return "Thread.Interrupted: " + this.message; };

	t.Yield = function(t,a) { this.run = function() { return a.callee.apply(t,a); } };
	t.Yield.prototype = function() { return "Thread.Yield"; };

	const q = t.queue, timer = js.util.Timer;

	t.prototype = {
		// mutable
		state: JS_CPS_THREAD_NEW,
		interrupted: false,
		priority: 5,
	    onerror_: function(e,k) { 
			try { 
				window.onerror(e); 
			} finally { 
				return null; 
			}
		},
		toString: function() { return this.name; },
		resume: function() { 
			switch (this.state) { 
			case JS_CPS_THREAD_SUSPENDED: 
				this.state = JS_CPS_THREAD_RUNNABLE; 
				q.push(this);
				break;
			default: throw new t.Error("resuming an unblocked thread");
			};
		},
		start: function() { 
			switch (this.state) { 
			case JS_CPS_THREAD_NEW : 
				this.state = JS_CPS_THREAD_RUNNABLE; 
				q.push(this); 
				return null;
			default: throw new t.Error("starting an already running thread");
			};
		},
		block_: function(sem,cc) {
			APPEL;
			switch (this.state) { 
			case JS_CPS_THREAD_RUNNING:
				this.run = cc;
				this.sem = sem;
				this.state = JS_CPS_THREAD_BLOCKED;
				return null;
			case JS_CPS_THREAD_RUNNABLE:
				this.sem = sem;
				this.state = JS_CPS_THREAD_BLOCKED;
				return cc();
			default: throw new t.Error("blocking a non-running thread");
			};
		},
		suspend_: function(cc) { 
			APPEL;
			switch (this.state) { 
			case JS_CPS_THREAD_RUNNING: 
				this.run = cc; 
				this.state = JS_CPS_THREAD_SUSPENDED;
				return null;
			case JS_CPS_THREAD_RUNNABLE: 
				this.state = JS_CPS_THREAD_SUSPENDED; 
				return cc();
			default: throw new t.Error("suspending a non-running thread");
			};
		},
		stop: function(e) { 
			e = e || new t.Death();
			switch (this.state) { 
			case JS_CPS_THREAD_RUNNING: throw e;
			case JS_CPS_THREAD_BLOCKED: 
				this.run = function() { throw e}; 
				this.sem.interrupt(this); 
				break;
			default: 
				this.run = function() {throw e}; break;
			};
		},
		interrupt: function() { 
			switch (this.state) { 
			case JS_CPS_THREAD_BLOCKED: 
				this.interrupted = false; 
				this.run = function() { throw new t.InterruptedException()}; 
				this.sem.interrupt(this);
				break;
			default: this.interrupted = true;
			};
		},
		interrupted: function() { 
			const r=this.interrupted;
			this.interrupted = false; 
			return r;
		},
		is_alive: function() { 
			return this.state != JS_CPS_THREAD_NEW && this.state != JS_CPS_THREAD_DEAD;
		},
		join_: function(cc) { 
			APPEL;
			switch (this.state) { 
			case JS_CPS_THREAD_RUNNING: throw new t.Error("Attempting to join a thread with itself");
			case JS_CPS_THREAD_DEAD: return cc();
			default: return this.exit_condition.wait_(cc);
			};
		}
	};

	t.sleep_ = function(ms,cc) { 
		const c = t.current;
		timer.set(function() { t.resume(); },ms);
		return t.suspend_(cc);
	};
	t.suspend_ = function(cc) { return t.current.suspend_(cc); };

	const can_pump = JS_CPS_THREAD_MAX_PUMPS;

	function yield(t,a) { 
		throw new t.Yield(t,a);
	};
	t.LAZY_POLICY = function lazy(t,a) { 
		return new t(function(){return a.callee.apply(t,a);}).start();
	};
	t.EAGER_POLICY = function eager(t,a) { // pump once
		if (!can_pump--) return (appel=lazy)(t,a); 
		appel_h = JS_CPS_THREAD_QUANTUM;
		appel = yield;
		var t = t.current,c = t.current = new t(); 	
		t.state = JS_CPS_THREAD_RUNNABLE;
		c.state = JS_CPS_THREAD_RUNNING;
		try { 
			c.run();
		} catch (e) { 
			if (__instanceof(e,t.Yield)) { 
				c.run = e.run;
				c.state = JS_CPS_THREAD_RUNNABLE;
				q.push(c);
			} else if (__instanceof__(e,t.Death)) { 
				c.state = JS_CPS_THREAD_DEAD;
				c.exit_condition.notify_all();
			} else { 
				c.run = function() { c.onerror_(c.onerror_.next,e,c.tail); }
				c.state = JS_CPS_THREAD_RUNNABLE;
				q.push(c);
			}
		} finally { 
			appel = t.policy;
			appel_h = 0;
			t.current = t;
			t.state = JS_CPS_THREAD_RUNNING;
		}
		return null;
	};

	q.pump = function pump() { 
		try { 
			appel = yield;
			var t = t.current; // event-sentinel
			while (can_pump--) { 
				var c = t.current = q.shift();
				appel_h = JS_CPS_THREAD_QUANTUM;
				c.state = JS_CPS_THREAD_RUNNING;
				try { 
					c.run();
				} catch (e) {
					if (__instanceof(e,t.Yield)){ 
						c.run = e.run;
						c.state = JS_CPS_THREAD_RUNNABLE;
						q.push(c);
					} else if (__instanceof(e,t.Death)) { 
						c.state = JS_CPS_THREAD_DEAD;
						c.exit_condition.notify_all();
					} else { 
						c.run = function() { c.onerror_(c.onerror_.next,e,c.tail); }
						c.state = JS_CPS_THREAD_RUNNABLE;
						q.push(c);
					}
				}
			} 
		} finally { 
			if (q.length) q.timer = timer.set(pump,1);
			else q.push = push_start;
			can_pump = pump_count;
			appel_h = 0;
			appel = t.policy;
			t.current = t; // event-sentinel
		}
		return null;
	};

	const push = [].push;
	const push_start = q.push = function() { 
		var r = push.apply(this,arguments);
		this.push = push;
		return pump();
		//q.timer = timer.set(pump,1); return null;
	};

})();

var appel_h = 0, appel = Thread.policy = Thread.EAGER_POLICY;

#endif // INCLUDED_JS_CPS_THREAD vim:ts=4
