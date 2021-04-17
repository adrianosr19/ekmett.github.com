#ifndef INCLUDED_JS_NATIVE_PLATFORM_H
#define INCLUDED_JS_NATIVE_PLATFORM_H

#define JSLIB_URL "http://slipwave.info/jslib/"

#ifndef MSIE
#define HAS_PROTO // Safari, KJS, Netscape 4+, Mozilla and Firefox support the non-ECMA __proto__ property
#endif

#ifdef MAC
#ifdef MSIE
#define OLD_BROWSER
#endif
#endif

#ifdef OLD_BROWSER

#define __delete__(o,i) 	(typeof(o[i])=="undefined"?false:(o[i]=undefined,true))
#define __in__(i,o)		(typeof(o[i])!="undefined")
#define __throw__(e)		return new js.InterpretedException(e)

#define FAKE_DELETE
#define FAKE_IN
#define NO_EXCEPTIONS

#ifdef HAS_PROTO
#define FAKE_INSTANCEOF
#else
#define NO_INSTANCEOF
#endif


#else //!OLD_BROWSER

#define __throw__(e)		throw e
#define __delete__(o,i) 	delete o[i]
#define __instanceof__(o,c)	o instanceof c
#define __in__(i,o)		i in o

#define HAS_EXCEPTIONS
#define HAS_DELETE
#define HAS_INSTANCEOF
#define HAS_IN

#endif //!OLD_BROWSER

#ifndef HAS_CONST
#define const var
#endif

#endif // INCLUDED_PLATFORM_H
