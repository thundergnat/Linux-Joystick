use v6.c;
use Test;
use Linux::Joystick;

if '/dev/input/'.IO.e {
    pass devices();
}

done-testing;
