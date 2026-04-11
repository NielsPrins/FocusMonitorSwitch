//go:build darwin

package main

// #cgo darwin LDFLAGS: -framework ApplicationServices -framework AppKit -framework Foundation
// #include "bridge.h"
import "C"

import (
	"runtime"
	"time"
)

func init() {
	runtime.LockOSThread()
}

func main() {
	go func() {
		var lastDisplay uint32
		for {
			currentDisplay := uint32(C.GetMouseDisplayID())

			if lastDisplay != 0 && currentDisplay != lastDisplay {
				pid := C.GetActiveAppPidOnDisplay(C.uint(currentDisplay))

				if int(pid) > 0 {
					C.FocusAppByPid(pid)
				}
			}

			lastDisplay = currentDisplay
			time.Sleep(50 * time.Millisecond)
		}
	}()

	C.RunMainLoop()
}
