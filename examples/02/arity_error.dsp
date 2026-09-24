// Two outputs cannot feed a single input through ":".
// expect-error
// expect: sequential composition
process = _, _ : _;
