#ifndef INCLUDED_JS_MATH_PERLIN
#define INCLUDED_JS_MATH_PERLIN
// classic Ken Perlin bias and gain functions
// Todo: noise and turbulence?
#include "js/math.js"

#define LOG_HALF -0.6931471805599453

with (Math) (function(){
	const p = js.math.Perlin = {};

	p.bias = function (a, b) {
	    if (b == 0.5) return a;
	    if (a<0.001) return 0;
	    if (a>0.999) return 1;
	    if (b<0.001) return 0;
	    if (b>0.999) return 1;
	    return pow(a, log(b)/LOG_HALF);
	};

	p.gain = function (a, b) {
	    if (b == 0.5) return a;
	    if (a<0.001) return 0;
	    if (a>0.999) return 1;
	    b = max(0.001, min(.999, b));
	    var p = log(1-b)/ LOG_HALF;
	    return a < 0.5 ? (pow(2 * a, p) / 2) : 1 - (pow(2 * (1 - a), p) / 2);
	};
})();


#undef LOG_HALF

#endif
