// Exercise 3: map applies a function to every element of a list.
map(f, (x, xs)) = f(x), map(f, xs);
map(f, x) = f(x);

process = map(*(2), (1, 2, 3)), map(\(v).(v * v), (4, 5));

// check: --double -n 1 --in zero
// expect: ^0,2\.0,4\.0,6\.0,16\.0,25\.0$
