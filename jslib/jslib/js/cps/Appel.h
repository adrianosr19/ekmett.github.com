// Appel.h (C) 2006 Edward Kmett. All Rights Reserved.
#ifndef INCLUDED_JS_CPS_APPEL_H
#define INCLUDED_JS_CPS_APPEL_H

#define APPEL   		if (--appel_h<0) return appel(this,arguments)
#define APPEL_n(c)		if (appel_h-=c<0) return appel(this,argumets)
#define APPEL_expr(x)		return --appel_h<0?appel(this,arguments):x
#define APPEL_n_expr(c,x)	return appel_h-=c<0?appel(this,arguments):x

#endif
