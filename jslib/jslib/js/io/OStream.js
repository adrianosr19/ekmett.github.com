#ifndef INCLUDED_JS_IO_OSTREAM
#define INCLUDED_JS_IO_OSTREAM

#include "js/cps/Appel.js"
#include "js/native/Array.js"
#include "js/io.js"

(function(){
	// @class js.io.OStream
	const io=js.io,o = o.OStream = function() {}, p = o.prototype = {
		flush_: function(cc) { APPEL_expr(cc()) }
		close_: function(cc) { APPEL_expr(cc()) }
		// @method write	
		// write noblocking
		// @param b string to write
		// @returns characters written, 0 if would block, null on EOF.
		write : function(s) { return 0 }
		// @method write_
		// write blocking
		// @param b string to write
		// @continues with number of characters written or null on EOF. Never continues with 0.
		write_: function(b,cc) { APPEL_expr(cc(-1)) },
		// @method write_fully_
		// write record blocking. 
		// @param b string to write
		// @continues with number of characters written or null on EOF.
		// @throws io.EOFException if unable to finish writing once started.
		write_fully_ : function(b,cc) { 
			APPEL;
			var p = write(b);
			if (p==null||p==b.length) return cc(p);
			const loop = function() {
				APPEL_expr(this.write_(b.slice(p),function(l){
					APPEL;
					if (l==null) 
						if (p) throw new io.EOFException("Partial write") 
						else return cc(l);
					else return (p+=l)==b.length?cc(p):loop();
				}))
			};
			return loop();
		}
	};
})(); // vim:ts=4

#endif
