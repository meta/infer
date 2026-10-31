/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

// The last line of this file has no terminator, so every location on it is
// exported through the path that does not ask SourceManager to scan back to
// the start of the line. The columns recorded below are what that path has to
// reproduce.

int add_on_an_earlier_line(int a, int b) { return a + b; }

int use_on_the_last_line(int a, int b) { return add_on_an_earlier_line(a, b); }