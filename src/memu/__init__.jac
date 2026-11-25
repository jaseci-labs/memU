import from importlib.metadata { PackageNotFoundError, version }
glob MemUService = MemoryService,
     __version__: any;

with entry {
    try {
        __version__ = version("memu-cli");
    } except PackageNotFoundError {
        __version__ = "0+unknown";
    }
}

glob __all__ = ["MemUService", "MemoryService", "__version__"];
