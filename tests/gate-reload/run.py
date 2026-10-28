#!/usr/bin/env python3
import argparse
import json
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import time


def write_json(path, value):
    path.write_text(json.dumps(value), encoding="utf-8")


def run():
    parser = argparse.ArgumentParser(description="Test Factorio des portes après rechargement")
    parser.add_argument("--factorio", required=True, type=Path)
    parser.add_argument("--data", required=True, type=Path)
    parser.add_argument("--variant", choices=["bp", "stc"], default="bp")
    parser.add_argument("--dependency", action="append", type=Path, default=[])
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    with tempfile.TemporaryDirectory(prefix="tf-gate-reload-") as temporary:
        work = Path(temporary)
        (work / "write/saves").mkdir(parents=True)
        build = work / "build"
        build.mkdir()
        shutil.copy2(root / "build.sh", build / "build.sh")
        for name in ["common", "variant-bp", "variant-stc", "graphics", "locale",
                     "LICENSE", "info.json"]:
            (build / name).symlink_to(root / name)
        subprocess.run(["bash", str(build / "build.sh"), "package"], check=True)
        mod_name = "train-foundry-stc" if args.variant == "stc" else "train-foundry"
        mods = work / "mods"
        scenario = mods / "tf-gate-test" / "scenarios" / "repro"
        scenario.mkdir(parents=True)
        package = next((build / "dist").glob(f"{mod_name}_[0-9]*.zip"))
        (mods / package.name).symlink_to(package)
        for dependency in args.dependency:
            (mods / dependency.name).symlink_to(dependency.resolve())
        shutil.copy2(root / "tests/gate-reload/control.lua", scenario / "control.lua")
        info = {"name": "tf-gate-test", "version": "0.0.1", "title": "Gate regression",
                "author": "test", "factorio_version": "2.1", "dependencies": [mod_name]}
        fixture_info = mods / "tf-gate-test" / "info.json"
        write_json(fixture_info, info)
        write_json(mods / "mod-list.json", {"mods": [
            {"name": name, "enabled": False} for name in
            ["space-age", "quality", "elevated-rails", "recycler"]]})
        config = work / "config.ini"
        config.write_text(f"[path]\nread-data={args.data.resolve()}\nwrite-data={work / 'write'}\n")
        settings = work / "server-settings.json"
        write_json(settings, {"name": "Gate regression", "description": "Local regression test",
                   "visibility": {"public": False,
                   "lan": False}, "require_user_verification": False,
                   "auto_pause": False, "autosave_interval": 0})
        command = [str(args.factorio.resolve()), "--config", str(config),
                   "--mod-directory", str(mods), "--disable-audio"]
        server_log = work / "server.log"
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
            probe.bind(("127.0.0.1", 0))
            port = probe.getsockname()[1]
        with server_log.open("w") as output:
            server = subprocess.Popen(command + ["--start-server-load-scenario",
                "tf-gate-test/repro", "--server-settings", str(settings),
                "--bind", f"127.0.0.1:{port}"], stdout=output, stderr=subprocess.STDOUT)
            try:
                deadline = time.monotonic() + 30
                while "Saving finished" not in server_log.read_text():
                    if server.poll() is not None or time.monotonic() > deadline:
                        raise RuntimeError(server_log.read_text())
                    time.sleep(0.1)
            finally:
                server.terminate()
                try:
                    server.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    server.kill()
                    server.wait()
        save = work / "write/saves/gate-crossing.zip"
        for changed in [False, True]:
            if changed:
                info["version"] = "0.0.2"
                write_json(fixture_info, info)
            result = subprocess.run(command + ["--test-save", str(save)],
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                    text=True, timeout=30)
            if result.returncode or "GATE_RELOAD_OK" not in result.stdout:
                raise RuntimeError(result.stdout)
            print(f"OK {args.variant}: rechargement " +
                  ("avec changement de configuration" if changed else "simple"))


if __name__ == "__main__":
    run()
