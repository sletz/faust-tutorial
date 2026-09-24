// Exercise 3: a library-wide switch, like debug.lib's DEBUG. The meters of
// this environment are shown when SHOW is 1 and compiled away when it is 0,
// the choice being made by pattern matching on the constant.
meters = environment {
    SHOW = 1;
    level(x) = show(SHOW, x)
    with {
        show(0, x) = x;
        show(1, x) = attach(x, abs(x) : hbargraph("level", 0, 1));
    };
};

process = _ <: meters.level, meters[SHOW = 0;].level;

// One bargraph only: the second meter is compiled away.
// check: --list-params
// expect: /ex3_switch/level +bargraph
// cpp-expect: addHorizontalBargraph
