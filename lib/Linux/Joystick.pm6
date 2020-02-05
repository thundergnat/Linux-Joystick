use v6.c;
unit class Linux::Joystick:ver<0.0.1>:auth<github:thundergnat>;

use experimental :pack;

# Joysticks generally show up in the /dev/input/ directory as js(n) where n is
# the number assigned by the OS.

sub devices is export {
    my @devices = '/dev/input/'.IO.dir.grep( *.contains('/js') ).sort;
    @devices.append: '/dev/'.IO.dir.grep( *.contains('/js') );
    print 'No ' unless +@devices;
    say "active Joystick devices:";
    .path.say for @devices;
    @devices;
}

class Linux::Joystick {
    has $.device;
    has &.callback is rw = sub { };
    has %.config;
    has %.event;
    has $!js;

    method TWEAK {
        # need a device
        unless $!device and $!device.IO.e {
            note "<$!device> not found.\nNeed to provide a path to an active device, try running" ~
            " devices() to see which joysticks are available, see below.\n";
            devices();
            exit ;
        }

        $!js = $!device.IO.open(:bin).Supply(:8size);
        start react { whenever $!js { $!js.act: { get-js-event(self, $_, self.callback) } } }
        sleep .5; # do a short delay tp allow driver to initialize
    }

    sub get-js-event ($j, $ev, &callback ) {

        # 32 bit timestamp milliseconds. Allows easy checking for "double-click" button presses
        $j.event<timestamp> = $ev.subbuf(0, 4).reverse.unpack('N');

        # 16 bit (signed int16) value of current control
        $j.event.<value> = (my $v = $ev.subbuf(4, 2).unpack('S')) > 32767 ?? -65536 + $v !! $v;

        # Two 8 bit integers, current event: control type, and control ID
        ($j.event.<type>, $j.event.<number>) = $ev.subbuf(6).unpack('CC');

        # Process the event
        given $j.event.<type> +& 3  { # enumeration of control inputs
            when 1 { $j.config.<button>[$j.event.<number>] = $j.event.<value> }
            when 2 { $j.config.<axis>[$j.event.<number>] = $j.event.<value> }
        }
        callback unless $j.event.<type> +& 128; # unless initializing
    }
}


=begin pod

=head1 NAME

Linux::Joystick

=head1 SYNOPSIS

=begin code :lang<perl6>

use Linux::Joystick;

my $joystick = Linux::Joystick.new( :device('/path/to/mydevice'), :callback(&optional-callback) );

=end code

=head1 DESCRIPTION

Linux::Joystick - a simple interface to the most common Linux joystick driver.

Sets up an asynchronous event stream reading events from the joystick in real
time.  Allows you to provide a callback routine which willexecute every time an
event  is received.

Needs to be initilized with a path to a valid, active joystick or joystick like
device. Optionally with take a callable routine to be executed every time an
event  is received.

An exported routine: devices() can be used to find and list available joystick
devices.

Exports two hashes. $joystick.config and $joystick.event.

$joystick.config contains the enumerated inputs and their present value.
Assuming your joystick has 12 buttons and 6 axes (Like a Logitec Extrme 3D for
instance.) The enumerated button values will be in $joystick.config<button>[0]
through $joystick.config<button>[11]. The enumerated axes will be in
$joystick.config<axis>[0] through $joystick.config<button>[5].

You may also access events directly. $joystick.event will hold the values from
the last event processed.

It holds the values:

=item <type>   - the type of joystick event it was: 1 - button, 2 - axis

=item <number> - which input emmitted the event: one of the enumerated buttons or axes

=item <value>  - the value associated with the event: button - 0 or 1, axis - -32767 to 32767

=item <timestamp> - a millisecond granularity 32 bit time stamp. May be used to detect double-clicks or such.

Button values can only be 0 (up) or 1 (pressed). Axis values can (though not
necessarily always do) range from -32767 to 32767. In general, even numbered
axes operate in the vertical (y) axis with smaller numbers being higher up and
larger being further down. Odd numbered axes usually operate in a horizontal (x)
axis. Smaller values to the left, larger to the right.

If you end up tapping a SIGINT signal, the joystick stream won't close until it
sees  a joystick event, the jowstick is unplugged, or you send another terminate
event.

See the example joystick.p6 script to see how that might be done.

=head1 AUTHOR

Stephen Schulze aka thundergnat

=head1 COPYRIGHT AND LICENSE

Copyright 2020 thundergnat

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod