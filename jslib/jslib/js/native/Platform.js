#ifndef INCLUDED_JS_NATIVE_PLATFORM
#define INCLUDED_JS_NATIVE_PLATFORM

#include "js/native/Platform.h"

#ifdef FAKE_INSTANCEOF
function __instanceof__(o, c) {
	while (o!= null) {
		if (o==c.prototype) return true
		o= o.__proto__;
	}
	return false;
}
#endif

#endif // vim:ts=4
