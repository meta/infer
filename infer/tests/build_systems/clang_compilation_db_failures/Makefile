# Copyright (c) Facebook, Inc. and its affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

TESTS_DIR = ../..

include $(TESTS_DIR)/base.make

# two of the three files do not compile on purpose: the test checks that infer reports them
INFER_OPTIONS = --keep-going --no-default-checkers --pulse --project-root $(TESTS_DIR)
SOURCES = $(wildcard ../codetoanalyze/clang_compilation_db_failures/*.c)
CLEAN_EXTRA = compile_commands.json console.log issues.test.txt

default: test

compile_commands.json: compile_commands.json.in
	$(QUIET)sed -e 's#%pwd%#$(CURDIR)#g' $< > $@ || $(REMOVE) $@

issues.exp.test: compile_commands.json $(SOURCES) $(MAKEFILE_LIST) $(CLANG_DEPS)
	$(QUIET)$(call silent_on_success,Clang compilation database with failing commands,\
	  $(INFER_BIN) $(INFER_OPTIONS) --compilation-database $< > console.log 2>&1 && \
	  $(INFER_BIN) report -q --issues-tests issues.test.txt && \
	  { grep "compilation commands failed" console.log || true; cat issues.test.txt; } > $@)

.PHONY: print
print: issues.exp.test

.PHONY: test
test: issues.exp.test
	$(QUIET)cd $(TESTS_DIR) && \
	$(call check_no_diff,$(TEST_REL_DIR)/issues.exp,$(TEST_REL_DIR)/issues.exp.test)

.PHONY: replace
replace: issues.exp.test
	cp $< issues.exp

.PHONY: clean
clean:
	$(REMOVE_DIR) infer-out issues.exp.test $(CLEAN_EXTRA)
