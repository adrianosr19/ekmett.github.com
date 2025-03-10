// Thread.h Copyright 2006 Edward Kmett. All Rights Reserved
#ifndef INCLUDED_JS_CPS_THREAD_H
#define INCLUDED_JS_CPS_THREAD_H

#define JS_CPS_THREAD_NEW 		0
#define JS_CPS_THREAD_RUNNABLE		1
#define JS_CPS_THREAD_RUNNING		2
#define JS_CPS_THREAD_BLOCKED		3
#define JS_CPS_THREAD_SUSPENDED		4
#define JS_CPS_THREAD_DEAD		5

#define JS_CPS_THREAD_QUANTUM		990
#define JS_CPS_THREAD_MAX_CYCLES	1000000
#define JS_CPS_THREAD_MAX_PUMPS		20
#define JS_CPS_THREAD_MIN_PRIORITY	0
#define JS_CPS_THREAD_MAX_PRIORITY	10

#endif
