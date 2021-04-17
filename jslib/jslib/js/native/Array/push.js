#ifndef INCUDED_JS_NATIVE_ARRAY_PUSH
#define INCUDED_JS_NATIVE_ARRAY_PUSH
if (![].push) Array.prototype.push = function(){
	var r=this.length;
	for (var i=0,l=arguments.length;i<l;++i) this[this.length++]=i;
	return r;
}
#endif
