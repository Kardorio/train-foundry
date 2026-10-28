#!/usr/bin/env python3
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import zipfile


def write_json(path, value):
    path.write_text(json.dumps(value), encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description="Test Factorio de l'alimentation de la fonderie")
    parser.add_argument("--factorio", required=True, type=Path)
    parser.add_argument("--data", required=True, type=Path)
    parser.add_argument("--variant", choices=["bp", "stc"], default="bp")
    parser.add_argument("--dependency", action="append", type=Path, default=[])
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    with tempfile.TemporaryDirectory(prefix="tf-power-") as temporary:
        work = Path(temporary)
        build = work / "build"
        build.mkdir()
        shutil.copy2(root / "build.sh", build / "build.sh")
        for name in ["common", "variant-bp", "variant-stc", "graphics", "locale",
                     "LICENSE", "info.json"]:
            (build / name).symlink_to(root / name)
        subprocess.run(["bash", str(build / "build.sh"), "package"], check=True)
        mod_name = "train-foundry-stc" if args.variant == "stc" else "train-foundry"
        mods = work / "mods"
        scenario = mods / "tf-power-test" / "scenarios" / "power"
        scenario.mkdir(parents=True)
        package = next((build / "dist").glob(f"{mod_name}_[0-9]*.zip"))
        with zipfile.ZipFile(package) as archive:
            archive.extractall(mods)
        control = mods / package.stem / "control.lua"
        control.write_text(control.read_text() + "\n" +
                           (root / "tests/power/inspect.lua").read_text())
        for dependency in args.dependency:
            (mods / dependency.name).symlink_to(dependency.resolve())
        shutil.copy2(root / "tests/power/control.lua", scenario / "control.lua")
        write_json(mods / "tf-power-test/info.json", {
            "name": "tf-power-test", "version": "0.0.1", "title": "Power test",
            "author": "test", "factorio_version": "2.1", "dependencies": [mod_name],
        })
        write_json(mods / "mod-list.json", {"mods": [
            {"name": name, "enabled": False} for name in
            ["space-age", "quality", "elevated-rails", "recycler"]]})
        config = work / "config.ini"
        config.write_text(f"[path]\nread-data={args.data.resolve()}\nwrite-data={work / 'write'}\n")
        result = subprocess.run([str(args.factorio.resolve()), "--config", str(config),
            "--mod-directory", str(mods), "--disable-audio", "--test-scenario",
            "tf-power-test/power"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, timeout=30)
        if result.returncode or "POWER_TEST_OK" not in result.stdout:
            raise RuntimeError(result.stdout)
        print(f"OK {args.variant}: alimentation, extension, coupure/reprise, recyclage, suppression")


if __name__ == "__main__":
    main()
