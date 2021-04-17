#ifndef INCLUDED_JS_UTIL_TREAP
#define INCLUDED_JS_UTIL_TREAP

// Treap (c) 2006. Edward Kmett. All Rights Reserved.
// See R. Seidel and C. R. Aragon. Randomized Search Trees. Algorithmica, 16(4/5):464-497, 1996.
// Todo: Finish removing recursion, multiple insertion/removal is not supported.
// ~5k insertions/second on a current PC.

#include "js/util.js"

(function() { 
	const $ = js.util.Treap = function (c,p) { 
		this.c = c||function (x){return x};
		this.p = p||Math.random;
		this.root = $.Null;
	}, N = $.N = function (k,p,d,l,r) { 
		this.k = k;//key
		this.p = p;//priority
		this.d = d;//data
		this.l = l;//left
		this.r = r;//right
	}
	N.prototype = {
		find : function(k) { 
			var n = this;
			do { 
				if (n._) return n;
				else if (n.k>k) n=n.l;
				else if (n.k<k) n=n.r;
				else return n; // or sentinel
			} while(1);
		},
		min : function() { 
			var n = this;
			if (!n._) while (!n.l._) n=n.l;
			return n;
		},
		max : function() { 
			var n = this;
			if (!n._) while (!n.r._) n=n.r;
			return n;
		},
		insert : function(n) { 
			var t=this;
			if (n.k<t.k) {
				t.l = t.l.insert(n);
				if (t.l.p<t.p) t=t.rol();
			} else if (n.k>t.k) { 
				t.r = t.r.insert(n);
				if (t.r.p<t.p) t=t.ror();
			}
			return t;
		},
		remove : function(k) { 
			var t = this;
			do { 
					if (k<t.k) t.l = t.l.remove(k);
					else if (k>t.k) t.r = t.r.remove(k);
					else { 
						if (t.l.p<t.r.p) t = t.rol();
						else t = t.ror();
						return t;
					}
			} while(1);
		},
		rol : function() { 
			var that = this.l;
			this.l = that.r;
			that.r = this;
			return that;
		},
		ror : function() { 
			var that = this.r;
			this.r = that.l;
			that.l = this;
			return that;
		},
		flatten_r : function(r) { 
			this.l.flatten(r);
			r.push(this.d);
			this.r.flatten(r);
			return r;
		},
		each : function(f) { 
			var s=[],t=this;
			do { 
				if (!t._) { 
					s.push(t);
					t=t.l;
				} else {
					if(t=s.pop()) { 
						f(t.d);
						t=t.r;
					} else break;
				}
			} while(1);
		},
		flatten : function(r) { 
			var s=[],t=this;
			do { 
				if (!t._) { 
					s.push(t);
					t=t.l;
				} else {
					if(t=s.pop()) { 
						r.push(t.d);
						t=t.r;
					} else break;
				}
			} while(1);
			return r;
		},
#ifdef DEBUG
		view : function(_1,_2,_3) { 
			return this.l.view(_1+"    ",_1+",---",_1+"|   ") +
				   _2 + this.k.toString() + " "+this.p.toFixed(2) + "\n" +
				   this.r.view(_3+"|   ",_3+"`---",_3+"    ");
		}
#endif
	};

	const _ = $.Null = new N(null,Infinity,undefined);
	_.l = _.r = _;
	_._ = 1;
	_.insert = function(n) { return n };
	_.remove = _.find = function(k) { return this };
	_.flatten = _.each = function(r) {}
	_.view = function(_1,_2,_3) {return ""}; //_2+"(_)\n" }
	_.min = function() { return this; };
	_.max = function() { return this; };

	$.prototype = {
		insert : function(d,k,p) { 
			var l = arguments.length;
			k = l>1?k:this.c(d);
			p = l>2?p:this.p(d);
			this.root = this.root.insert(new N(k,p,d,_,_))
		},
		remove : function(k) { this.root = this.root.remove(k) },

		make_empty : function() { this.root = _ },
		is_empty : function() { return this.root._?true:false },

		find : function(k) { return this.root.find(k).d },
		contains : function(k) { return !this.root.find(k)._ },

		toArray : function() { return this.root.flatten([]) },
		toArray_r : function() { return this.root.flatten_r([]) },
		toString : function(k) { return this.root.view("","","") },

		min : function(){return this.root.min().d},
		max : function(){return this.root.max().d},

		top : function() { return this.root.d },

		pop : function() { 
			var t,r=t=this.root;
			if (t.l.p<t.r.p) t=t.rol()
			else t=t.ror();
			this.root=t;
			return r.d;
		},
		push_down : function(dp) { 
			var t,r=t=this.root;
			if (t.l.p<t.r.p) t=t.rol()
			else t=t.ror();
			r.p+=dp;
			return this.root = t.insert(r);
		},
		each : function(f) { 
			this.root.each(f);
		}
		top_node : function() { return this.root },
		pop_node : function() { 
			var t,r=t=this.root;
			if (t.l.p<t.r.p) t=t.rol()
			else t=t.ror();
			this.root=t;
			return r;
		}
	};
	$.Iter = function(treap) { 
		var s=[],t=treap.root;
		this.next = function() { 
			r = null;
			do { 
				if (!t._) { 
					s.push(t);
					t=t.l;
				} else {
					if(t=s.pop()) { 
						r=t.d;
						t=t.r;
					}
					break;
				}
			} while(1);
			return r;
		},
		this.has_more = function() { return this.s.length; },
	}
})();


#endif // INCLUDED_JS_UTIL_TREAP vim:ts=4
