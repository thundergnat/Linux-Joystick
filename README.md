NAME
====

Linux::Joystick

SYNOPSIS
========

```perl6
use Linux::Joystick;

my $joystick = Linux::Joystick.new(
    :device('/path/to/mydevice'),
    :callback(&optional-callback)
);
```

DESCRIPTION
===========

Linux::Joystick - a simple interface to the most common Linux joystick driver.

Sets up an asynchronous event stream reading events from the joystick in real time. Allows you to provide a callback routine which will execute every time an event is received.

The callback routine is rewritable and may be changed without restarting the joystick driver.

Needs to be initilized with a path to a valid, active joystick or joystick-like device. (An Xbox controller will work.) Optionally takes a callable routine to be executed every time an event is received.

An exported routine: `devices()` can be used to find and list available joystick devices.

Exports two hashes. `$joystick.config` and `$joystick.event`.

`$joystick.config` contains the enumerated inputs and their present value. Assuming your joystick has 12 buttons and 6 axes (Like a Logitech Extreme 3D for instance.) The enumerated button values will be in `$joystick.config<button>[0]` through `$joystick.config<button>[11]`. The enumerated axes will be in `$joystick.config<axis>[0]` through `$joystick.config<axis>[5]` .

You may also access events directly. `$joystick.event` will hold the values from the last event processed.

It holds the values:

  * `type` - the type of joystick event it was; 1: button, 2: axis

  * `number` - which input emitted the event: one of the enumerated buttons or axes

  * `value` - the value associated with the event; button: 0 or 1, axis: -32767 to 32767

  * `timestamp` - a millisecond granularity 32 bit time stamp. May be used to detect double-clicks or such. Rolls over every 100 or so hours.

Button values can only be 0 (up) or 1 (pressed). Axis values can (though not necessarily always do) range from -32767 to 32767. In general, even numbered axes operate in the vertical (y) axis with smaller numbers being higher up and larger being further down. Odd numbered axes usually operate in a horizontal (x) axis. Smaller values to the left, larger to the right.

If you end up tapping a SIGINT signal, the joystick stream won't close until it sees one more joystick event, the joystick is unplugged, or you send another different terminate event.

See the /examples/joystick.p6 script to see how that might be done.

AUTHOR
======

Stephen Schulze aka thundergnat

COPYRIGHT AND LICENSE
=====================

Copyright 2020 thundergnat

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

