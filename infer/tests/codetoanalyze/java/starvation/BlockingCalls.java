/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import android.os.IBinder;
import android.os.IInterface;
import android.os.RemoteException;
import android.os.SystemClock;
import android.support.annotation.UiThread;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

class BlockingCalls {
  Semaphore sem;
  BlockingQueue<Object> queue;
  CountDownLatch latch;

  // ---- TP CONTROL: already modelled, must keep reporting ----
  @UiThread
  void controlLatchAwaitBad() throws InterruptedException {
    latch.await();
  }

  // ---- 1. Semaphore ----
  @UiThread
  void semAcquireBad() throws InterruptedException {
    sem.acquire();
  }

  @UiThread
  void semAcquireUninterruptiblyBad() {
    sem.acquireUninterruptibly();
  }

  // bounded: must stay silent
  @UiThread
  void semTryAcquireTimeoutOk() throws InterruptedException {
    sem.tryAcquire(1, TimeUnit.MILLISECONDS);
  }

  @UiThread
  void semTryAcquireOk() {
    sem.tryAcquire();
  }

  // ---- 2. BlockingQueue ----
  @UiThread
  void queueTakeBad() throws InterruptedException {
    queue.take();
  }

  @UiThread
  void queuePutBad(Object o) throws InterruptedException {
    queue.put(o);
  }

  // bounded: must stay silent
  @UiThread
  void queuePollTimeoutOk() throws InterruptedException {
    queue.poll(1, TimeUnit.MILLISECONDS);
  }

  @UiThread
  void queueOfferTimeoutOk(Object o) throws InterruptedException {
    queue.offer(o, 1, TimeUnit.MILLISECONDS);
  }

  @UiThread
  void queueOfferOk(Object o) {
    queue.offer(o);
  }

  // ---- 3. SystemClock.sleep ----
  @UiThread
  void systemClockSleepBad() {
    SystemClock.sleep(100);
  }

  // ---- 4. synchronous AIDL / binder IPC ----
  interface IFoo extends IInterface {
    void bar() throws RemoteException;

    void onewayBaz() throws RemoteException;
  }

  // the AIDL-generated proxy: a real one forwards to IBinder.transact
  static class FooProxy implements IFoo {
    IBinder mRemote;

    public IBinder asBinder() {
      return mRemote;
    }

    public void bar() throws RemoteException {
      mRemote.transact(1, null, null, 0); // reply expected: synchronous
    }

    public void onewayBaz() throws RemoteException {
      mRemote.transact(2, null, null, 1); // FLAG_ONEWAY: does not block
    }
  }

  IFoo foo;

  // called through the interface, with the proxy body available
  @UiThread
  void aidlThroughProxyBad() throws RemoteException {
    FooProxy p = new FooProxy();
    p.bar();
  }

  // Called through the interface type only. Whether this blocks is decided by the
  // FLAG_ONEWAY argument the generated proxy passes to transact, and with no proxy
  // body here there is nothing to read it from: a oneway method has the same Java
  // signature as a blocking one, so the interface alone cannot tell them apart.
  @UiThread
  void FN_aidlThroughInterface() throws RemoteException {
    foo.bar();
  }

  // oneway: must stay silent
  @UiThread
  void aidlOnewayThroughProxyOk() throws RemoteException {
    FooProxy p = new FooProxy();
    p.onewayBaz();
  }

  @UiThread
  void aidlOnewayThroughInterfaceOk() throws RemoteException {
    foo.onewayBaz();
  }

  // ---- off the UI thread: all silent ----
  void semAcquireOffUiOk() throws InterruptedException {
    sem.acquire();
  }

  void queueTakeOffUiOk() throws InterruptedException {
    queue.take();
  }

  void systemClockSleepOffUiOk() {
    SystemClock.sleep(100);
  }
}
