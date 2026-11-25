import importlib;
glob uninstall: any;

with entry {
    uninstall = importlib.import_module("memu.hosts.scheduling.windows").uninstall;
}

glob __all__ = ["cleanup", "install", "status", "uninstall", "verify"];
