#ifndef INCLUDED_JS_IO_BUFFEREDOSTREAM
#define INCLUDED_JS_IO_BUFFEREDOSTREAM

#include "js/cps/Appel.js"
#include "js/native/Array.js"
#include "js/io/OStream.js"

(function(){
	function pump(b) { 
		var i = 0,q=b.q,s;
		while (i<q.length) {
			s=q[i];
			r=b.write(s);
			if (r==null) return;
			b.p -= r;
			if (r<s.length) { 
				q[i] = s.slice(r); break; 
			}
		}
		if (i) q = q.slice(i);
	}
	function pump_(b,cc) {
		APPEL;
		// pump until empty or closed
		// start at zero and run till its gone.
		const q=b.q,loop = function(i) { 
			APPEL_expr(b.stream.write_fully_(q[i],function(n){
				APPEL;
			 	if (n==null) if (i) b.q = q.slice(i); // eof
				else if (i==q.length) { b.p = 0; b.q = []; }
				else { b.p -= q[i].length; return loop(i+1); } 
				return cc();
			}))
		};
		return q.length?loop(0):cc()
	}

	// @class js.io.BufferedOStream
	const io=js.io,o = o.BufferedOStream = function(s,b) { 
		this.stream = s;
		this.q = []
		this.p = 0; // bytes pending
		this.b = 1024; // blocking pump when we have this much in q.
	}, p = o.prototype = {
		flush_: function(cc) { 
			APPEL;
			const b = this;
			pump_(this,function(){
				APPEL;
				if (b.p) throw new io.IOException("incomplete flush"); }
				b.stream.flush_(cc);
			});
		}
		APPEL_expr(cc()) }
		close_: function(cc) { 
			APPEL;
			const b = this;
			this.flush_(function() { b.stream.close_(cc); });
		}
		write : function(s) { 
			const q = this.q;
			q.push(s);
			this.p += s.length;
			pump(this);
			return s.length;
		},
		write_: function(s,cc) {
			APPEL;
			const q = this.q;
			q.push(s);
			if ((this.p += s.length)>this.b) 
				return pump_(this,function(){
					APPEL_expr(cc(s.length))
				});
			else { 
				pump(q);
				return cc(s.length);
			}
		}
	};
	p.write_fully_ = p.write_;
})(); // vim:ts=4

#endif
