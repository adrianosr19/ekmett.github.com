#ifndef INCLUDED_JS_NATIVE_ARRAY_JOIN
#define INCLUDED_JS_NATIVE_ARRAY_JOIN
if (![].join) Array.prototype.join = function join(s)  { 
        if (typeof(s) != 'string') s = s.toString();
        var r = '',i=0,l=this.length-1;
        while(i<l) r+=this[i++].toString()+s;
        return i<this.length ? r+this[i].toString() : r;
}
#endif // vim:ts=4
