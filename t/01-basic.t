use v6.c;
use Test;
use Proxy::Watched;

plan 42;

my @promises;

# Speed for interval supplies. Increase this (try 1) if wait-for or wait-while tests are failing.
my \speed = 0.1;

{
my $supply-int;
my $watched-int := watch-var(Int,$supply-int);
is $watched-int,Int,"watched-int created";
my $check-int-count = 0;
my $check-int = Promise.new;
bail-out "Cannot continue without working tap" unless ok $supply-int.tap(-> $a { $check-int-count++; $check-int.keep($a) }) ~~ Tap,"watched-int tapped";
$watched-int = 5;
is $watched-int,5,"watched-int is correct";
is $check-int.result,5,"Tap got correct value";
try $watched-int = "String";
ok $! ~~ X::TypeCheck::Binding::Parameter,"Type error when assigning string to watched-int";
is $check-int-count,1,"No extra tap triggered";
}

{
my $supply-int-init;
my $watched-int-init := watch-var(Int,$supply-int-init,:init(7));
isnt $watched-int-init,Int,"watched-int-init is defined";
is $watched-int-init,7,"watched-int-init is 7";
}

{
my $supply-six;
my $watched-six := watch-var(6,$supply-six);
is $watched-six,6,"watched-six created";
my $check-six = Promise.new;
bail-out "Cannot continue without working tap" unless ok $supply-six.tap(-> $a { $check-six.keep($a) }) ~~ Tap,"watched-six tapped";
$watched-six = 5;
is $watched-six,5,"watched-six is correct";
is $check-six.result,5,"Tap got correct value";
}

{
my $supply-any;
my $watched-any := watch-var($supply-any);
is $watched-any,Any,"watched-any created";
my $check-any = Promise.new;
bail-out "Cannot continue without working tap" unless ok $supply-any.tap(-> $a { $check-any.keep($a) }) ~~ Tap,"watched-any tapped";
$watched-any = 5;
is $watched-any,5,"watched-any is correct";
is $check-any.result,5,"Tap got correct value";
}

{
my $supply-any-init;
my $watched-any-init := watch-var($supply-any-init,:init("Hi"));
is $watched-any-init,"Hi","watched-any-init";
}

{
my $waitsupply;
my $waitfor := watch-var($waitsupply);
pass "waitfor created";
my $ok = False;
my $waitfor-fail = @promises.push: Promise.in(speed * 5).then({ unless $ok { flunk "Failed to wait-for"; } });
my $waittick = Supply.interval(speed).tap: -> $a { $waitfor = $a };
$waitsupply.wait-for(3);
$ok = True;
$waittick.close;
pass "waitfor succeeded";
is $waitfor,3,"Check correct value was waited for";
await $waitfor-fail;
}

{
my $joint := watch-var();
pass "joint created";
my $check;
$joint.tap: -> $a { $check = $a };
$joint = 7;
is $joint,7,"Joint value changed correctly";
is $check,7,"Tap updated with correct value";
$joint = "Hi";
is $joint,"Hi","Joint value change to string";
is $check,"Hi","Tap updated with string value";
my $ok = False;
my $joint-fail = @promises.push: Promise.in(speed * 5).then({ unless $ok { flunk "Failed to wait-for joint"; } });
my $jointtick = Supply.interval(speed).tap: -> $a { $joint = $a };
$joint.wait-for(3);
pass "joint wait-for succeeded";
$joint.wait-for(set 3,2);
pass "joint wait-for already-met set succeeded";
$ok = True;
$jointtick.close;
is $joint,3,"Confirm joint value is as waited for";
is $check,3,"Confirm tapped value is as waited for";
await $joint-fail;
}

{
my $joint-typed := watch-var(:type(Int));
ok $joint-typed ~~ Int:U,"joint-typed is Int-ish";
$joint-typed = 7;
is $joint-typed,7,"joint-typed is 7";
try $joint-typed = "String";
ok $! ~~ X::TypeCheck::Binding::Parameter,"Type error when assigning string to joint-typed";
is $joint-typed,7,"joint-typed is still 7";
}

{
my $joint-typed-init := watch-var(:type(Int),:init(7));
is $joint-typed-init,7,"joint-typed-init is 7";
try $joint-typed-init = "String";
ok $! ~~ X::TypeCheck::Binding::Parameter,"Type error when assigning string to joint-typed-init";
is $joint-typed-init,7,"joint-typed-init is still 7";
}

{
my $joint-init-by-type := watch-var(:type(7));
is $joint-init-by-type,7,"joint-init-by-type is 7";
try $joint-init-by-type = "String";
ok $! ~~ X::TypeCheck::Binding::Parameter,"Type error when assigning string to joint-init-by-type";
is $joint-init-by-type,7,"joint-init-by-type is still 7";
}

{
my $joint-any-init := watch-var(:init(7));
is $joint-any-init,7,"joint-any-init is 7";
try $joint-any-init = "String";
nok $! ~~ X::TypeCheck::Binding::Parameter,"No type error when assigning string to joint-any-init";
is $joint-any-init,"String","joint-any-init is now String";
}

await @promises;
done-testing;

# vim:ft=perl6
