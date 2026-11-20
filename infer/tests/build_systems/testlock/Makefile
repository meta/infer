# Copyright (c) Facebook, Inc. and its affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

TESTLOCK = ../../testlock.py

.PHONY: test print replace clean

test:
	@for expected in 0 7; do \
	  actual=0; \
	  $(TESTLOCK) sh -c "exit $$expected" || actual=$$?; \
	  if [ "$$actual" -ne "$$expected" ]; then \
	    printf 'testlock: expected exit %s, got %s\n' "$$expected" "$$actual" >&2; \
	    exit 1; \
	  fi; \
	  printf 'testlock: exit %s preserved\n' "$$expected"; \
	done; \
	actual=0; \
	$(TESTLOCK) sh -c 'kill -TERM $$$$' || actual=$$?; \
	if [ "$$actual" -ne 143 ]; then \
	  printf 'testlock: expected exit 143 after SIGTERM, got %s\n' "$$actual" >&2; \
	  exit 1; \
	fi; \
	printf 'testlock: SIGTERM reported as exit 143\n'

print replace: test

clean:
	@:
