#ifndef INCLUDED_JS_TEST_SIMPLE
#define INCLUDED_JS_TEST_SIMPLE

function plan(n) { 
	print("1.."+n);
	plan.count = n;
}
plan.id = 0;
plan.count = 0;

function ok(b,n,r) { 
	print(
		(b?"":"not ")+
		"ok "+(++plan.id)+
		(n?" "+n:"") + 
		(r?" # "+r:"")
	);
	if (plan.id == plan.count) print("END");
}

function skip(n,r) { 
	print(
		"ok "+(++plan.id)+
		(n?" "+n:"") +
		" # skipped" + 
		(r? " "+r:"")
	);
	if (plan.id == plan.count) print("END");
}

function todo(n,r) { 
	print(
		"not ok "+(++plan.id)+
		(n?" "+n:"") +
		" # TODO "+r
	);
	if (plan.id == plan.count) print("END");
}

#endif // vim:ts=4
