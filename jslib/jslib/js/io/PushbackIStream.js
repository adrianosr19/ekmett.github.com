#ifndef INCLUDED_JS_IO_PUSHBACKISTREAM
#define INCLUDED_JS_IO_PUSHBACKISTREAM

#include "js/cps/Appel.js"			// APPEL
#include "js/native/Array.js" 		// [].pop 
#include "js/io.js"					// js.io

(function(){
	// @class js.io.PushbackIStream
	// @implements js.io.IStream
	const io=js.io, b=io.PushbackIStream = function(s) { this.stream = s; this.buffer = ''; }, p=b.prototype=new io.IStream;
	// @method unread
	// @param s string to prepend to the queue.
	p.unread = function(s) { this.buffer = s + this.buffer; };

	// Todo: make this markable by simply buffering everything read in the meantime and maintaining a cursor.
    p.mark = function(n) {},
	p.reset = function(t) { return false; }  // not markable
	p.markable = function() { return 0; }
	p.ready = function() { return this.buffer.length+this.stream.ready() };
	p.read = function(c) {
		var b=this.buffer,n=b.length, r=b;
		if (n)
			if (c<n) {
				r=b.slice(0,c);
				this.buffer=b.slice(c);
			} else this.buffer = '';
		b=this.stream.read(c-r.length);
		return n?r+(b||''):b;
	};
	p.read_ = function(c,cc) { 
		APPEL;
		const r = this.read(c);
		if (c) return r;
		return this.stream.read_(c,cc);
	};
	p.skip = function(c) { 
		var b = this.buffer,n=b.length;
		if (n) this.buffer = b.slice(c);
		if (n<c) { 
			b = this.stream.skip(c-n);
			return b<0?n||-1:n+b;
		} else return c;
	};
	p.skip_ = function(c,cc) { 
		APPEL;
		const s = this.skip(c);
		return (s==-1||s==c) ? s : this.stream.skip_(c-s,function(n){ APPEL_expr(cc(n==-1?s||-1:s+c)) });
	};
})(; 

#endif // vim:ts=4
