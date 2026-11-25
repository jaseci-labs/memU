import builtins;

import from jaclang.comptime { target }

import ctypes;

import subprocess;

import sys;

import time;

import from contextlib { ExitStack }

import from ctypes { wintypes }

glob _JOB_OBJECT_BASIC_PROCESS_ID_LIST: any = 3;

glob _JOB_OBJECT_EXTENDED_LIMIT_INFORMATION: any = 9;

glob _JOB_OBJECT_LIMIT_ACTIVE_PROCESS: any = 8;

glob _JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE: any = 8192;

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

def _last_error -> OSError;

obj WindowsExtractionJob {
    has _handle: any,
        _kernel32: any;

    def init;
    def assign(process: subprocess.Popen[bytes]);

    def _process_ids -> list[int];

    def _open_members(resources: ExitStack) -> list[int];

    def _close_handle(handle: int);
    def close;

    def __repr__ -> str;

    def __eq__(other: any) -> bool;

    def __hash__ -> int;
}
