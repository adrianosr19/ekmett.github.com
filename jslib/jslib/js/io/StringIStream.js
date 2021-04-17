#ifndef INCLUDED_JS_IO_STRINGISTREAM
#define INCLUDED_JS_IO_STRINGISTREAM

#include "js/cps/Appel.js"	// APPEL*
#include "js/io.js"			// js.io

// @class js.io.StringIStream
// @param s the string to turn into an IStream

(function(){
	const io=js.io,i=io.StringIStream = function(s) { 
		this.buffer = s;
		this.pos = 0;
		this.mpos = 0;
	}, p=i.prototype={
		markable: function() { return true }, 
		mark: function(n) {} { this.mpos = this.pos; },
		reset : function() { this.pos = this.mpos; }
		ready: function() { return this.buffer.length - this.pos; }
		read: function(c) { 
			c=c||this.buffer.length; 
			const r = this.buffer.slice(this.pos,this.pos+c);
			this.pos += r.length;
			return r||null;
		}
		read_: function(c,cc) { 
			APPEL_expr(cc(read(c)||null)) 
		}, 
		read_fully_: function(c,cc) { 
			APPEL;
			const p=this.pos,b=this.buffer,l=b.length;
			if (l-p>=c) return cc(b.slice(p,this.pos=c));
			else if (r.length==p) return cc(null);
			else throw io.EOFException("Unexpected EOF");
		},
		skip: function(c) { 
			const p=this.pos,b=this.buffer,l=b.length; 
			if (p==l) return -1;
			if (p+c<=l) { this.pos+=c; return c; }
			this.pos = l; return l-p;
		},
		skip_: function(c,cc) { 
			APPEL_expr(cc(this.skip(c)));
		}
	};
})(); 

#endif // vim:ts=4
