#ifndef INCLUDED_JS_IO_ISTREAM
#define INCLUDED_JS_IO_ISTREAM

#include "js/cps/Appel.js"	// APPEL*
#include "js/io.js"			// js.io

// Roughly parallels java.
// @class js.io.IStream

(function(){
	const io=js.io,i=io.IStream = function() { 
	}, p=i.prototype={
		// @method markable
		// @returns a 'truthy' value if we can mark, possibly a number.
		markable: function() { return 0 }, 
		// @method mark
		// @param n the number of characters that may be read before releasing.
		mark: function(n) {} { return null },
		// @method reset
		// @returns true if successful
		reset : function() { return false;},
		// @method ready
		// @returns the number of bytes guaranteed to be available before blocking may be required
		ready: function() { return 0 },
		// @method read
		// @abstract
		// @param l maximum number of characters to read
		// @returns null at EOF, '' if would block, or a string of available characters otherwise.
		read: function(c) { return '' },
		// @method read_
		// @abstract
		// @param c maximum number of characters to read
		// @returns null at EOF, or a string of characters, not to exceed l in length.
		//          blocking if no characters are yet available. If the result is 'truthy' then we found text.
		read_: function(c,cc) { APPEL_expr(cc(null)) }, 
		// @method read_fully_
		// @param c exact number of characters to read
		// @returns a string of c characters or null if EOF is present at the start of the read.
		// @throws js.io.EOFException if the EOF is reached mid-read.
		read_fully_: function(c,cc) { 
			APPEL;
			var r = this.read(c);
			if (r==null||r.length==c) return cc(r); 
			var loop = function() {
				APPEL_expr(this.read_(c-r.length,function(n){
					APPEL; if (n==null) throw new io.EOFException();
					r+=n;
					return r.length<l?loop():cc(r);
				}))
			};
			return loop();
		},
		// @method skip
		// skip up to the next n characters nonblocking.
		// @returns the number of characters skipped, or -1 if at eof.
		skip: function(c) { var v = this.read(c); return v == null ? -1 : v.length; },
		// @method skip_
		// skip the next n characters. blocking if necessary.
		// @continues with the number of characters skipped, or -1 at EOF.
		skip_: function(c,cc) { 
			APPEL;
			var r = this.skip(n);
			if (r<0) cc(r);
			var p = n-r;
			var loop = function() { 
				APPEL_expr(this.read_(p,function(b){
					APPEL_expr(b==null?cc(r):(r+=b.length,loop()));
				}))
			};
			return loop();
		}
	};
})(); // vim:ts=4

#endif
