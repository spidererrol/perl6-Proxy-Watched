NAME
====

Proxy::Watched - Provides a proxy with a supply that emits whenever the proxy is updated.

SYNOPSIS
========

```perl6
use Proxy::Watched;

my $watched := watch-var();
$watched.tap: *.say;
$watched = "Say this!";

Supply.interval(1).tap: -> $i { $watched = $i };
$watched.wait-for(3);

my $monitor;
my $monitored := watch-var($monitor);
$monitor.tap: *.say;
$monitored = "Say this!";

my $typed-monitor;
my $typed-watched := watch-var(Str,$monitor);
$typed-monitor.tap: *.say;
$typed-watched = "Must be a Str";

my $init-monitor;
my $init-watched := watch-var("Initial Value",$monitor);
$init-monitor.tap: *.say;
$init-watched = "Say this!";
```

DESCRIPTION
===========

Proxy::Watched provides the watch-var method which provides a [Proxy](Proxy) and also a Monitor.

The Monitor allows you to [tap](Supply/method tap) the value of the [Proxy](Proxy) to get updated whenever it is updated.

EXPORTED FUNCTION
=================

This module exports just one function but it has many different forms.

watch-var()
-----------

With no parameters this returns a Proxy which overloads the contained value to provide the method provided by Monitor below. Unlike the separate Monitors this variable does not "does" the role Tappable.

It allows you to call tap, wait-for, or wait-while on the value itself, but if that might conflict with any normal use of the value or you don't want those methods to escape as you pass the values around then use one of the other variants below.

WARNING: You cannot use a wait-for(Junction) or wait-while(Junction) with this form! Use the form with a separate Monitor object instead.

```perl6
my $watched := watch-var();
$watched.tap: *.say;
$watched = "Say this!";
```

watch-var(:type(Type),:init(Value))
-----------------------------------

This produces a overloaded proxy a above, but with a restricted type (required) and optionally an initial value.

```perl6
my $watched := watch-var(:type(Int));
$watched.tap: *.say;
$watched = 45;

my $watched-init := watch-var(:type(Int),:init(0 but "Hello!"));
say $watched-init;

my $lazy := watch-var(:type(7)); # Same as :type(Int),:init(7)
```

watch-var(:init(Value))
-----------------------

This provides an initialised, overloaded proxy without resticting the type.

```perl6
my $watched := watch-var(:init(7));
$watched.tap: *.say;
$watched = "Warn"; # Valid.
```

watch-var($monitor,:$init)
--------------------------

With just one parameter you should pass in a variable which will be assigned with the Monitor. The Proxy to be monitored is returned. This means the values are kept as-is rather than being extended with the extra methods. If :$init is specified, sets the initial value of the Proxy to that. No type is enforced on the monitor.

```perl6
my $monitor;
my $monitored := watch-var($monitor);
$monitor.tap: *.say;
$monitored = "Say this!";
```

watch-var(::Type,$monitor,:$init)
---------------------------------

The $monitor parameter is updated with the Monitor, and the returned Proxy is limited to the given Type. If :$init is specified then the Proxy will be set to that value initially.

```perl6
my $typed-monitor;
my $typed-watched := watch-var(Str,$monitor);
$typed-monitor.tap: *.say;
$typed-watched = "Must be a Str";
```

watch-var(::Type $init,$monitor)
--------------------------------

Shorthand for watch-var($init,$monitor,:$init);

class Monitor
=============

This is the class which gives access to the "Watched" part of the variable.

method tap
----------

    method tap(&emit,:&done,:&quit,:&tap --> Tap);

See [Supply/tap](Supply/tap). This method is just the tap method on the Supply for the watched variable.

method wait-for
---------------

    method wait-for($value);
    method wait-for(Setty $values);

In sink (void) context this method will wait until the watched variable is the same as the value (smartmatch) or one of the values in the set (associative).

In scalar context it will return a promise which will be kept when the above condition is met.

This method may return / keep the promise straight away if the watched variable already meets the condition.

method wait-while
-----------------

    method wait-while($value);
    method wait-while(Setty $values);

This is basically the opposite of wait-for as it will wait until the watched variable does not match any of the given values.

AUTHOR
======

Timothy Hinchcliffe <gitprojects.qm@spidererrol.co.uk>

COPYRIGHT AND LICENSE
=====================

Copyright 2019 Timothy Hinchcliffe

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

