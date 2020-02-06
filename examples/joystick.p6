#!/usr/bin/env perl6

use Linux::Joystick;
use Terminal::ANSIColor; # Color!

# send a more adament signal when SIGINT is already tapped
use NativeCall;
sub kill(int64 $pid, int16 $signal) is native { * }
sub outtahere { kill($*PID, 1) }; # SIGHUP


my $js = Linux::Joystick.new( :device(devices[0]), :callback(&update) );

# clean up on exit, reset ANSI, clear screen, reshow cursor
signal(SIGINT).tap: { print "\e[0m", "\n" xx 50, "\e[H\e[J\e[?25h"; outtahere }

my ($rows, $cols) = qx/stty size/.words; # get the terminal size

my $xhair = '╺╋╸'; # terminal crosshair
my $axis  = '█';   # bar graph block

# generate text IDs for the buttons
my @btext = (^$js.config<button>).map: { sprintf( "%2d", $_) };

# configure the button colors (blue for off, green for on)
my @button = @btext.map: {color('bold white on_blue ') ~ $_ ~ color('reset')};

# set up some axis variables
my ($x, $y, $z) = ($rows/2).floor, ($cols/2).floor, 0;

# hide the cursor
print "\e[?25l";

# initial update
update;

# Main loop, operates independently of the joystick event loop
loop {
    once say " Joystick has {$js.config<axis>.elems} axes and {$js.config<button>.elems} buttons";
    sleep 1;
    ($rows, $cols) = qx/stty size/.words;
}


# callback routine run for every joystick event.
sub update {
    given $js.event<type> {
        when 1 { # button event
            given $js.event<value> { # adjust the colors to match button state
                when 0 { @button[$js.event<number>] = color('bold white on_blue ') ~ @btext[$js.event<number>] ~ color('reset') }
                when 1 { @button[$js.event<number>] = color('bold white on_green') ~ @btext[$js.event<number>] ~ color('reset') }
            }
        }
        when 2 { # axis events
            given $js.event<number> { # scale the axis events to fit our terinal boundaries
                when 0 { $y = ($cols / 2 + $js.event<value> / 32767 * $cols / 2).Int max 1 }
                when 1 { $x = ($rows / 2 + $js.event<value> / 32767 * $rows / 2).Int max 2 }
                when 2 { $z = ($js.event<value> / 32767 * 100).Int }
                default { } # only using the first 3 axes, ignore any others
            }
            # The "crosshair" is 3 characters wide, limit how close to an edge it can get.
            $x min= $rows - 1;
            $y min= $cols - 1;
        }
    }

    # clear screen, move to upper left
    print "\e[H\e[J\e[1;1H";

    # print button and axis states
    print "  ", join "  ", flat @button, "Axis 0: $x", "Axis 1: $y" , "Axis 2: $z%\n";

    # scale the bar graph and print it
    my $bar = ($z / 100 * $cols / 2).floor;
    if $bar < 0 {
        print ' ' x ($bar + $cols / 2).floor, color('bold green') ~ $axis x -$bar ~ color('reset');
    } else {
        print ' ' x $cols / 2, color('bold green') ~ $axis x $bar ~ color('reset');
    }

    # move to the coordinates and print the crosshair
    print "\e[{$x};{$y}H", color('bold yellow') ~ $xhair ~ color('reset');
}
