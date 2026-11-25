"""Read a background worker's startup snapshot without exposing its output."""

import from __future__ { annotations }

import math;

import re;

import time;

import from pathlib { Path }

import from typing { Any }

"""Read one worker's admission/result snapshot without waiting for its pipeline."""
def memorize_status(path: Path) -> dict[str, Any];
