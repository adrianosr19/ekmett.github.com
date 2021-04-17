#ifndef INCLUDED_JS_TEST_ASSERT_H
#define INCLUDED_JS_TEST_ASSERT_H

#define assert(cond) 	void((cond)||js.test.Assert.fail(#cond,__FILE__,__LINE__))
#define pre(cond) 	void((cond)||js.test.Assert.fail(#cond,__FILE__,__LINE__,"pre-condition"))
#define post(cond) 	void((cond)||js.test.Assert.fail(#cond,__FILE__,__LINE__,"post-condition"))

#endif
