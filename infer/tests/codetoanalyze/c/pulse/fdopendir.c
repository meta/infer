/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#include <dirent.h>
#include <fcntl.h>
#include <unistd.h>

// the stream returned by fdopendir() owns the descriptor, and closedir()
// releases it, so there is nothing left to close here
int fdopendirClosed_ok() {
  int fd = open("mydir", O_RDONLY);
  if (fd < 0) {
    return -1;
  }
  DIR* dir = fdopendir(fd);
  if (!dir) {
    close(fd);
    return -1;
  }
  closedir(dir);
  return 0;
}

// the new owner of the descriptor is dropped without being closed
int fdopendirNotClosed_bad() {
  int fd = open("mydir", O_RDONLY);
  if (fd < 0) {
    return -1;
  }
  DIR* dir = fdopendir(fd);
  if (!dir) {
    close(fd);
    return -1;
  }
  return 0;
}

// fdopendir() failed, so the descriptor is still the caller's to close
int fdopendirFailed_bad() {
  int fd = open("mydir", O_RDONLY);
  if (fd < 0) {
    return -1;
  }
  DIR* dir = fdopendir(fd);
  if (!dir) {
    return -1;
  }
  closedir(dir);
  return 0;
}

// no stream is involved at all
int fdopendirDescriptorLeaked_bad() {
  int fd = open("mydir", O_RDONLY);
  if (fd < 0) {
    return -1;
  }
  return 0;
}
