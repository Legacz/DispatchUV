# DispatchUV

Swift GCD Dispatch API on top of libuv

The idea is that one simulates relevant aspects of the
[Swift Dispatch API](https://developer.apple.com/reference/dispatch)
on top of 
[libuv](http://libuv.org).

Why would you do this?
One reason would be that the libdispatch included in the Swift 3 Linux release
[crashes on you](https://github.com/helje5/linux-gcd-issue).

Well, seriously, libuv is field proven on Linux. May be better for server level
workloads, though time will tell.

Status: Very early. Toy stuff.
