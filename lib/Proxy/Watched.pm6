use v6.c;
unit module Proxy::Watched:ver<0.0.1>:auth<github:spidererrol>;


=begin pod

=head1 NAME

Proxy::Watched - Provides a proxy with a supply that emits whenever the proxy is updated.

=head1 SYNOPSIS

=begin code :lang<perl6>

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

=end code

=head1 DESCRIPTION

Proxy::Watched provides the watch-var method which provides a L<Proxy> and also a Monitor.

The Monitor allows you to L<tap|Supply/method tap> the value of the L<Proxy> to get updated whenever it is updated.

=head1 EXPORTED FUNCTION

This module exports just one function but it has many different forms.

=head2 watch-var()

With no parameters this returns a Proxy which overloads the contained value to provide the method provided by Monitor
below. Unlike the separate Monitors this variable does not "does" the role Tappable.

It allows you to call tap, wait-for, or wait-while on the value itself, but if that might conflict with any normal
use of the value or you don't want those methods to escape as you pass the values around then use one of the other
non-overloaded variants below.

=begin code :lang<perl6>

my $watched := watch-var();
$watched.tap: *.say;
$watched = "Say this!";

=end code

=head2 watch-var(:type(Type)!,:init(Value))

This produces a overloaded proxy a above, but with a restricted type (required) and optionally an initial value.
Note that :type can be a definite value in which case the type of the value will be used and the value will be used as the
default initial value.

=begin code :lang<perl6>

my $watched := watch-var(:type(Int));
$watched.tap: *.say;
$watched = 45;

my $watched-init := watch-var(:type(Int),:init(0 but "Hello!"));
say $watched-init;

my $lazy := watch-var(:type(7)); # Same as :type(Int),:init(7)

=end code

=head2 watch-var(:init(Value)!)

This provides an initialised, overloaded proxy without resticting the type.

=begin code :lang<perl6>

my $watched := watch-var(:init(7));
$watched.tap: *.say;
$watched = "Stringy"; # Valid.

=end code

=head2 watch-var($monitor,:$init)

With just one parameter you should pass in a variable which will be assigned with the Monitor. The Proxy to be monitored
is returned. This means the values are kept as-is rather than being extended with the extra methods.
If :$init is specified, sets the initial value of the Proxy to that. No type is enforced on the monitor.

=begin code :lang<perl6>

my $monitor;
my $monitored := watch-var($monitor);
$monitor.tap: *.say;
$monitored = "Say this!";

=end code

=head2 watch-var(::Type,$monitor,:$init)

The $monitor parameter is updated with the Monitor, and the returned Proxy is limited to the given Type. If :$init is
specified then the Proxy will be set to that value initially.

=begin code :lang<perl6>

my $typed-monitor;
my $typed-watched := watch-var(Str,$monitor);
$typed-monitor.tap: *.say;
$typed-watched = "Must be a Str";

=end code

=head2 watch-var(::Type $init,$monitor)

Shorthand for watch-var($init,$monitor,:$init);

=head1 class Monitor

This is the class which gives access to the "Watched" part of the variable.

=head2 method tap

    method tap(&emit,:&done,:&quit,:&tap --> Tap);

See L<Supply/tap>. This method is just the tap method on the Supply for the watched variable.

=head2 method wait-for

    method wait-for($value);
    method wait-for(Setty $values);

In sink (void) context this method will wait until the watched variable is the same as the value (smartmatch) or one of
the values in the set (associative).

In scalar context it will return a promise which will be kept when the above condition is met.

This method may return / keep the promise straight away if the watched variable already meets the condition.

=head2 method wait-while

    method wait-while($value);
    method wait-while(Setty $values);

This is basically the opposite of wait-for as it will wait until the watched variable does not match any of the given
values.

=end pod

class Monitor does Tappable {
    has Supply $!source handles <live sane serial tap>;
    has $!watched;
    submethod BUILD(:$!source!,:$watched! is raw) { $!watched := $watched }
    method !wait-build(&cond) {
        my $promise = Promise.new;
        my $rpromise;
        self.tap(-> $a { $promise.keep if cond($a) },tap=> -> $t { $rpromise = $promise.then({ $t.close; True }) });
        $promise.keep if cond($!watched);
        return $rpromise does role { method sink { await $rpromise } };
    }
    multi method wait-for($value) {
        self!wait-build(* ~~ $value);
    }
    multi method wait-for(Junction $value) { # This needs to be specified otherwise the Junction will be auto-threaded.
        self!wait-build(* ~~ $value);
    }
    multi method wait-for(Setty $values) {
        self!wait-build(-> $a { $values{$a} });
    }
    multi method wait-while($value) {
        self!wait-build(-> $a { ! ( $a ~~ $value ) });
    }
    multi method wait-while(Junction $value) { # This needs to be specified otherwise the Junction will be auto-threaded.
        self!wait-build(-> $a { ! ( $a ~~ $value ) });
    }
    multi method wait-while(Setty $values) {
        self!wait-build(-> $a { ! $values{$a} });
    }
}

proto sub watch-var(|) is rw is export {*}

multi sub watch-var(::T $type, $monitor is rw, T :$init = $type) {
    my Supplier $sup .= new;
    my T $value = $init;
    $monitor = Monitor.new(source=>$sup.Supply,watched=>$value);
    Proxy.new(
        FETCH => method () { $value },
        STORE => method (T $new) { $value = $new; $sup.emit($new); },
    )
}

multi sub watch-var($monitor is rw, :$init!) {
    my Supplier $sup .= new;
    my $value = $init;
    $monitor = Monitor.new(source=>$sup.Supply,watched=>$value);
    Proxy.new(
        FETCH => method () { $value },
        STORE => method ($new) { $value = $new; $sup.emit($new); },
    )
}

multi sub watch-var($monitor is rw) {
    watch-var(Any,$monitor)
}

sub build($value,$monitor) {
    $value but role :: {
        method tap(&emit,*%more) { $monitor.tap(&emit,|%more) }
        multi method wait-for(Any: $value) { $monitor.wait-for($value) } # This covers Setty just fine.
        multi method wait-for(Any: Junction $value) { $monitor.wait-for($value) } # This needs a special because Junction isn't an Any.
        multi method wait-while(Any: $value) { $monitor.wait-while($value) }
        multi method wait-while(Any: Junction $value) { $monitor.wait-while($value) } # This needs a special because Junction isn't an Any.
    }
}

multi sub watch-var() {
    my Supplier $sup .= new;
    my $value;
    my $monitor = Monitor.new(source=>$sup.Supply,watched=>$value);
    Proxy.new(
        FETCH => method () { build $value,$monitor },
        STORE => method ($new) { $value = $new; $sup.emit($new); },
    )
    
}

multi sub watch-var(::T :$type!,T :$init = $type) {
    my Supplier $sup .= new;
    my T $value = $init;
    my $monitor = Monitor.new(source=>$sup.Supply,watched=>$value);
    Proxy.new(
        FETCH => method () { build $value,$monitor },
        STORE => method (T $new) { $value = $new; $sup.emit($new); },
    )
    
}

multi sub watch-var(:$init!) {
    my Supplier $sup .= new;
    my $value = $init;
    my $monitor = Monitor.new(source=>$sup.Supply,watched=>$value);
    Proxy.new(
        FETCH => method () { build $value,$monitor },
        STORE => method ($new) { $value = $new; $sup.emit($new); },
    )
    
}

=begin pod

=head1 AUTHOR

Timothy Hinchcliffe <gitprojects.qm@spidererrol.co.uk>

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Timothy Hinchcliffe

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
