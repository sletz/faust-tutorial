# make check                    check every program of the tutorial (C++ faust and faustprobe)
# make check DIR=examples/04    one chapter only
FAUST ?= faust
FAUSTPROBE ?= ../faust-rs/target/release/faustprobe
FAUSTLIBRARIES ?= ../../faustlibraries
DIR ?=

.PHONY: check
check:
	FAUST=$(FAUST) FAUSTPROBE=$(FAUSTPROBE) FAUSTLIBRARIES=$(FAUSTLIBRARIES) python3 scripts/check.py $(DIR)
