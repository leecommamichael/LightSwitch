#include <mach/mach.h>
#import <IOKit/IOKitLib.h>
#import <CoreFoundation/CoreFoundation.h>

static double updateInterval = 0.1;
static io_connect_t dataPort = 0;

void updateTimerCallBack(CFRunLoopTimerRef timer, void *info) {
  kern_return_t kr;
  uint32_t outputs = 2;
  uint64_t values[outputs];

  kr = IOConnectCallMethod(dataPort, 0, nil, 0, nil, 0, values, &outputs, nil, 0);
  if (kr == KERN_SUCCESS) {
    printf("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b%8lld %8lld\n", values[0], values[1]);
    return;
  }

  if (kr == kIOReturnBusy) {
    return;
  }

  mach_error("I/O Kit error:", kr);
  exit(kr);
}

int main(void) {
  kern_return_t kr;
  io_service_t serviceObject;
  CFRunLoopTimerRef updateTimer;

  serviceObject = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleLMUController"));
  if (!serviceObject) {
    fprintf(stderr, "failed to find ambient light sensors\n");
    exit(1);
  }

  kr = IOServiceOpen(serviceObject, mach_task_self(), 0, &dataPort);
  IOObjectRelease(serviceObject);
  if (kr != KERN_SUCCESS) {
    mach_error("IOServiceOpen:", kr);
    exit(kr);
  }

  setbuf(stdout, NULL);
  printf("%8ld %8ld", 0L, 0L);
  printf("\n");

  updateTimer = CFRunLoopTimerCreate(kCFAllocatorDefault,
                  CFAbsoluteTimeGetCurrent() + updateInterval, updateInterval,
                  0, 0, updateTimerCallBack, NULL);
  CFRunLoopAddTimer(CFRunLoopGetCurrent(), updateTimer, kCFRunLoopDefaultMode);
  CFRunLoopRun();

  exit(0);
}
