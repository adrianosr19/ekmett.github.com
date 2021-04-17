#ifndef INCLUDED_JS_LANG_PARSER_PROGRESS
#define INCLUDED_JS_LANG_PARSER_PROGRESS
js.lang.Parser.prototype.progress = function(e,c) { 
	function x(s,n){ return !n?"":x(s+s,parseInt(n/2))+(n%2?s:""); }
	var s = this.src,
		n = "\n",
		f = s.lastIndexOf(n,c)+1,
		l = s.indexOf(n,c),
		m = l==-1?s.length:l,
		p = this.file+": "+this.line+": ";
	return n+p+e+n+p+s.slice(f,m).replace("\t"," ")+n+p+x("-",c-f)+"^\n";
};
#endif // vim:ts=4
