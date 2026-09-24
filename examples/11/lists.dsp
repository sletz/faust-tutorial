// A parallel composition is a list: (a, b, c) is a, (b, c). A pattern
// (x, xs) takes the first element and the rest. Gräf's serial turns a list
// of blocks into their sequence; count and rev are two more examples.
serial((x, xs)) = x : serial(xs);
serial(x) = x;

count((x, xs)) = 1 + count(xs);
count(x) = 1;

rev((x, xs)) = rev(xs), x;
rev(x) = x;

process = serial((*(2), +(1), *(10))), count((7, 8, 9)), rev((1, 2, 3, 4));

// serial gives ((x * 2) + 1) * 10.
// check: --double -n 1 --in dc
// expect: ^0,30\.0,3\.0,4\.0,3\.0,2\.0,1\.0$
