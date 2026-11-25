import builtins;

import from jaclang.comptime { target }

import ctypes;

import subprocess;

import sys;

import time;

import from contextlib { ExitStack }

import from ctypes { wintypes }

glob _JOB_OBJECT_BASIC_PROCESS_ID_LIST: any = 3,
     _JOB_OBJECT_EXTENDED_LIMIT_INFORMATION: any = 9,
     _JOB_OBJECT_LIMIT_ACTIVE_PROCESS: any = 8,
     _JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE: any = 8192;

class _BasicLimitInformation(ctypes.Structure) {
    static has _fields_: any = (
        ("PerProcessUserTimeLimit", ctypes.c_int64),
        ("PerJobUserTimeLimit", ctypes.c_int64),
        ("LimitFlags", ctypes.c_uint32),
        ("MinimumWorkingSetSize", ctypes.c_size_t),
        ("MaximumWorkingSetSize", ctypes.c_size_t),
        ("ActiveProcessLimit", ctypes.c_uint32),
        ("Affinity", ctypes.c_size_t),
        ("PriorityClass", ctypes.c_uint32),
        ("SchedulingClass", ctypes.c_uint32),
    );
}

class _IoCounters(ctypes.Structure) {
    static has _fields_: any = (
        ("ReadOperationCount", ctypes.c_uint64),
        ("WriteOperationCount", ctypes.c_uint64),
        ("OtherOperationCount", ctypes.c_uint64),
        ("ReadTransferCount", ctypes.c_uint64),
        ("WriteTransferCount", ctypes.c_uint64),
        ("OtherTransferCount", ctypes.c_uint64),
    );
}

class _ExtendedLimitInformation(ctypes.Structure) {
    static has _fields_: any = (
        ("BasicLimitInformation", _BasicLimitInformation),
        ("IoInfo", _IoCounters),
        ("ProcessMemoryLimit", ctypes.c_size_t),
        ("JobMemoryLimit", ctypes.c_size_t),
        ("PeakProcessMemoryUsed", ctypes.c_size_t),
        ("PeakJobMemoryUsed", ctypes.c_size_t),
    );
}

def _last_error -> OSError {
    comptime if target().os == "windows" {
        return ctypes.WinError(ctypes.get_last_error());
    }
    return OSError("Windows extraction jobs are unavailable on this platform");
}

obj WindowsExtractionJob {
    has _handle: any,
        _kernel32: any;

    def init {
        self._handle = None;
        comptime if target().os != "windows" {
            raise _last_error();
        }

        self._kernel32 = ctypes.WinDLL("kernel32", use_last_error=True);
        self._kernel32.CreateJobObjectW.argtypes = [ctypes.c_void_p, wintypes.LPCWSTR];
        self._kernel32.CreateJobObjectW.restype = wintypes.HANDLE;
        self._kernel32.SetInformationJobObject.argtypes = [
            wintypes.HANDLE,
            ctypes.c_int,
            ctypes.c_void_p,
            wintypes.DWORD,
        ];
        self._kernel32.SetInformationJobObject.restype = wintypes.BOOL;
        self._kernel32.AssignProcessToJobObject.argtypes = [wintypes.HANDLE, wintypes.HANDLE];
        self._kernel32.AssignProcessToJobObject.restype = wintypes.BOOL;
        self._kernel32.TerminateJobObject.argtypes = [wintypes.HANDLE, wintypes.UINT];
        self._kernel32.TerminateJobObject.restype = wintypes.BOOL;
        self._kernel32.QueryInformationJobObject.argtypes = [
            wintypes.HANDLE,
            ctypes.c_int,
            ctypes.c_void_p,
            wintypes.DWORD,
            ctypes.c_void_p,
        ];
        self._kernel32.QueryInformationJobObject.restype = wintypes.BOOL;
        self._kernel32.OpenProcess.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD];
        self._kernel32.OpenProcess.restype = wintypes.HANDLE;
        self._kernel32.IsProcessInJob.argtypes = [
            wintypes.HANDLE,
            wintypes.HANDLE,
            ctypes.POINTER(wintypes.BOOL),
        ];
        self._kernel32.IsProcessInJob.restype = wintypes.BOOL;
        self._kernel32.WaitForSingleObject.argtypes = [wintypes.HANDLE, wintypes.DWORD];
        self._kernel32.WaitForSingleObject.restype = wintypes.DWORD;
        self._kernel32.CloseHandle.argtypes = [wintypes.HANDLE];
        self._kernel32.CloseHandle.restype = wintypes.BOOL;
        self._handle = self._kernel32.CreateJobObjectW(None, None);
        if not self._handle {
            raise _last_error();
        }
        limits: any = _ExtendedLimitInformation();
        limits.BasicLimitInformation.LimitFlags = _JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
        if not self._kernel32.SetInformationJobObject(
            self._handle,
            _JOB_OBJECT_EXTENDED_LIMIT_INFORMATION,
            ctypes.byref(limits),
            ctypes.sizeof(limits),
        ) {
            error: any = _last_error();
            self.close();
            raise error;
        }
    }

    def assign(process: subprocess.Popen[bytes]) {
        if self._handle is None {
            msg: any = "extraction job is closed";
            raise OSError(msg);
        }
        process_handle: any = process._handle;
        if not self._kernel32.AssignProcessToJobObject(self._handle, process_handle) {
            raise _last_error();
        }
    }

    def _process_ids -> list[int] {
        capacity: any = 16;
        while True {
            buffer: any = ctypes.create_string_buffer(
                8 + capacity * ctypes.sizeof(ctypes.c_size_t)
            );
            if self._kernel32.QueryInformationJobObject(
                self._handle, _JOB_OBJECT_BASIC_PROCESS_ID_LIST, buffer, ctypes.sizeof(buffer), None
            ) {
                count: any = wintypes.DWORD.from_buffer(buffer, 4).value;
                return [int(pid) for pid in (ctypes.c_size_t * count).from_buffer(buffer, 8)];
            }
            error: any = _last_error();
            if getattr(error, "winerror", None) != 234 {
                raise error;
            }
            capacity = max(capacity * 2, wintypes.DWORD.from_buffer(buffer).value);
        }
    }

    def _open_members(resources: ExitStack) -> list[int] {
        handles: any = [];
        for pid in self._process_ids() {
            handle: any = self._kernel32.OpenProcess(1048576 | 4096, False, pid);
            if not handle {
                error: any = _last_error();
                if getattr(error, "winerror", None) == 87 {
                    continue;
                }
                raise error;
            }
            resources.callback(self._close_handle, handle);
            member: any = wintypes.BOOL();
            if not self._kernel32.IsProcessInJob(handle, self._handle, ctypes.byref(member)) {
                raise _last_error();
            }
            if member.value {
                handles.append(handle);
            }
        }
        return handles;
    }

    def _close_handle(handle: int) {
        if not self._kernel32.CloseHandle(handle) {
            raise _last_error();
        }
    }

    def close {
        if self._handle is None {
            return;
        }
        try {
            resources: any;
            with ExitStack() as resources {
                limits: any = _ExtendedLimitInformation();
                limits.BasicLimitInformation.LimitFlags = _JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
                    | _JOB_OBJECT_LIMIT_ACTIVE_PROCESS;
                if not self._kernel32.SetInformationJobObject(
                    self._handle,
                    _JOB_OBJECT_EXTENDED_LIMIT_INFORMATION,
                    ctypes.byref(limits),
                    ctypes.sizeof(limits),
                ) {
                    raise _last_error();
                }
                handles: any = self._open_members(resources);
                if not self._kernel32.TerminateJobObject(self._handle, 1) {
                    raise _last_error();
                }
                deadline: any = time.monotonic() + 2;
                for handle in handles {
                    remaining_ms: any = max(0, `int((deadline - time.monotonic()) * 1000));
                    result: any = self._kernel32.WaitForSingleObject(handle, remaining_ms);
                    if result == 258 {
                        raise TimeoutError("extraction Job members did not exit within 2 seconds");
                    }
                    if result != 0 {
                        raise _last_error();
                    }
                }
            }
        } finally {
            self._close_handle(self._handle);
            self._handle = None;
        }
    }

    def __repr__ -> str {
        return (getattr(builtins.object, "__repr__") as any)(self);
    }

    def __eq__(other: any) -> bool {
        return self is other;
    }

    def __hash__ -> int {
        return id(self);
    }
}
