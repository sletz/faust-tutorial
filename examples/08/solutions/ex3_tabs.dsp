// Exercise 3: a four-channel gain stage, one tab per channel.
channel(i) = vgroup("channel %i", *(hslider("gain", 1, 0, 2, 0.01)));

process = tgroup("channels", par(i, 4, channel(i)));

// check: --list-params
// expect: ^/channels/channel_0/gain
// expect: ^/channels/channel_3/gain
// check: --double -n 1 --in impulse:2 --set channel_2/gain=2
// expect: ^0,0\.0,0\.0,2\.0,0\.0$
