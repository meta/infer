/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

package codetoanalyze.java.infer;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.channels.SeekableByteChannel;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;

// Streams returned by the java.nio.file.Files factories (issue #2110)
public class FilesLeaks {

  public void newInputStreamNotClosedAfterReadBad(Path path) throws IOException {
    InputStream stream = Files.newInputStream(path);
    stream.read();
  }

  public void newInputStreamClosedOk(Path path) throws IOException {
    InputStream stream = Files.newInputStream(path);
    try {
      stream.read();
    } finally {
      stream.close();
    }
  }

  public void newInputStreamTryWithResourcesOk(Path path) throws IOException {
    try (InputStream stream = Files.newInputStream(path)) {
      stream.read();
    }
  }

  public InputStream newInputStreamReturnedOk(Path path) throws IOException {
    return Files.newInputStream(path);
  }

  public void newOutputStreamNotClosedAfterWriteBad(Path path) throws IOException {
    OutputStream stream = Files.newOutputStream(path);
    stream.write(1);
  }

  public void newOutputStreamTryWithResourcesOk(Path path) throws IOException {
    try (OutputStream stream = Files.newOutputStream(path)) {
      stream.write(1);
    }
  }

  public void newBufferedReaderNotClosedAfterReadBad(Path path) throws IOException {
    BufferedReader reader = Files.newBufferedReader(path);
    reader.read();
  }

  public void newBufferedReaderTryWithResourcesOk(Path path) throws IOException {
    try (BufferedReader reader = Files.newBufferedReader(path)) {
      reader.readLine();
    }
  }

  public void newBufferedWriterNotClosedAfterWriteBad(Path path) throws IOException {
    BufferedWriter writer = Files.newBufferedWriter(path);
    writer.write(1);
  }

  public void newBufferedWriterTryWithResourcesOk(Path path) throws IOException {
    try (BufferedWriter writer = Files.newBufferedWriter(path)) {
      writer.write(1);
    }
  }

  // Channels from Files.newByteChannel and FileChannel.open are fresh resources. Left unknown,
  // Pulse never allocates them, so not closing the channel is missed.

  public void newByteChannelNotClosedAfterReadBad(Path path) throws IOException {
    SeekableByteChannel channel = Files.newByteChannel(path);
    ByteBuffer buffer = ByteBuffer.allocate(8);
    channel.read(buffer);
  }

  public void newByteChannelClosedOk(Path path) throws IOException {
    SeekableByteChannel channel = Files.newByteChannel(path);
    try {
      ByteBuffer buffer = ByteBuffer.allocate(8);
      channel.read(buffer);
    } finally {
      channel.close();
    }
  }

  public void newByteChannelTryWithResourcesOk(Path path) throws IOException {
    try (SeekableByteChannel channel = Files.newByteChannel(path)) {
      ByteBuffer buffer = ByteBuffer.allocate(8);
      channel.read(buffer);
    }
  }

  public SeekableByteChannel newByteChannelReturnedOk(Path path) throws IOException {
    return Files.newByteChannel(path);
  }

  public void fileChannelOpenNotClosedAfterWriteBad(Path path) throws IOException {
    FileChannel channel = FileChannel.open(path, StandardOpenOption.WRITE);
    ByteBuffer buffer = ByteBuffer.allocate(8);
    channel.write(buffer);
  }

  public void fileChannelOpenTryWithResourcesOk(Path path) throws IOException {
    try (FileChannel channel = FileChannel.open(path, StandardOpenOption.READ)) {
      ByteBuffer buffer = ByteBuffer.allocate(8);
      channel.read(buffer);
    }
  }

  // DirectoryStream from Files.newDirectoryStream holds a directory handle until close().
  // Left unknown, Pulse never allocates it, so not closing the stream is missed.

  public void newDirectoryStreamNotClosedBad(Path dir) throws IOException {
    Files.newDirectoryStream(dir);
  }

  public void newDirectoryStreamNotClosedAfterIteratorBad(Path dir) throws IOException {
    DirectoryStream<Path> stream = Files.newDirectoryStream(dir);
    stream.iterator();
  }

  public void newDirectoryStreamGlobNotClosedBad(Path dir) throws IOException {
    Files.newDirectoryStream(dir, "*.java");
  }

  public void newDirectoryStreamClosedOk(Path dir) throws IOException {
    DirectoryStream<Path> stream = Files.newDirectoryStream(dir);
    stream.close();
  }

  public void newDirectoryStreamTryWithResourcesOk(Path dir) throws IOException {
    try (DirectoryStream<Path> stream = Files.newDirectoryStream(dir)) {
      stream.iterator();
    }
  }

  public DirectoryStream<Path> newDirectoryStreamReturnedOk(Path dir) throws IOException {
    return Files.newDirectoryStream(dir);
  }
}
