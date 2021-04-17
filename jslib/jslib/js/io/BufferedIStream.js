#ifndef INCLUDED_JS_IO_BUFFEREDISTREAM
#define INCLUDED_JS_IO_BUFFEREDISTREAM

#include "js/native/Platform.js"	// const
#include "js/cps/Appel.js"			// APPEL
#include "js/native/Array.js" 		// [].pop [].slice
#include "js/io.js"					// js.io

(function(){
	function dq(b) { 
		const u = b.ma!=null?b.mi:b.i,q=b.q;
		if (b.i) { q = q.slice(u); b.i-=u;b.mi -=u } // q.shift(u)
	}
	var guid=0;
	const io=js.io,
		// @class js.io.BufferedIStream
		// @implements js.io.IStream
		b=io.BufferedIStream = function(s) { 
			this.stream = s;
			this.q = []; // chunk vector
			this.mi = this.i = 0;  // current chunk
			this.mj = this.j = 0;  // pos in chunk
			this.a = 0;  		   // ready
			this.ma = null;		
			this.mn = null;
		},
		p=b.prototype=new io.IStreamFilter;

	p.read = function(c) {
		var r = this.stream.read(),q=this.q;
		if (r) {
			q.push(r);
			this.a += r.length;
			if (this.ma!=null) {
				this.ma += r.length;
				if (this.mn && this.ma > this.mn) this.ma = null;
			}
		} else if (!this.a) return r;
		c=c||this.a;
		var i = this.i, j = this.j, s = q[i].slice(j);
		while(s.length<c&&++i<q.length) s += q[i].slice(0,j=c-s.length);
		var r = s.length<c?s.length:c,	// chars read
			u = s.length>c?s.length-c:0 // chars to undo
		this.i=i;this.j=j-u;this.a-=r;
		dq(this);
		return s.slice(0,r);
	},
	p.read_ = function(c,cc) {
		APPEL;
		const r = this.read(c);
		return r==0?this.stream.read_(c,cc):cc(r); // if must block, block, otherwise return available.
	},
	p.mark = function(n) {
		this.mi = this.i;
		this.ma = this.a;
		this.mj = this.j;
		this.mn = n ? this.a + n : null;
	},
	p.reset = function() {
		if (this.ma!=null) {
			this.a = this.ma;
			this.i = this.mi;
			this.j = this.mj;
		}
	},
	p.ready = function() { return this.a+this.stream.ready() };
	p.skip = function(c) { 
		var a = this.a,s=0,q=this.q,_=this.stream;
		if (a<=c) {
			this.i = q.length;
			this.j = this.a = 0;
			const b = _.skip(c-a);
			return b<0?a||-1:a+b;
		} else { 
			// consume what we must
			var i = this.i,j=this.j;
			while(s<c&&++i<q.length) s += q[i].slice(0,j=c-s).length;
			const r = s<c?s:c,  // chars read
				  u = s>c?s-c:0 // chars to undo
			this.i=i;this.j=j-u;this.a-=r;
			dq(this);
			return r;
		}
	};
	p.skip_ = function(c,cc) { 
		APPEL;
		const s = this.skip(c);
		return (s==-1||s==c) ? s : this.stream.skip_(c-s,function(n){ APPEL_expr(cc(n==-1?s||-1:s+c)) });
	};
})(; 

#endif // vim:ts=4
