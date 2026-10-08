# Copyright (c) Facebook, Inc. and its affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

TESTS_DIR = ../..

CLANG_OPTIONS = -x c++ -std=c++17 -c
INFER_OPTIONS = --liveness-only --debug-exceptions --project-root $(TESTS_DIR)

# test that the error messages are good
INFERPRINT_OPTIONS = --issues-tests-fields file,procedure,line,bug_type,qualifier --issues-tests

SOURCES = $(wildcard *.cpp)

include $(TESTS_DIR)/clang.make

infer-out/report.json: $(MAKEFILE_LIST)
