#!/usr/bin/env python3
"""Wagons électriques de James' Electric Trains Plus construits par la fonderie BP."""
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
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--factorio", required=True, type=Path)
    parser.add_argument("--data", required=True, type=Path)
    parser.add_argument("--variant", choices=["bp", "stc"], default="bp")
    parser.add_argument("--dependency", action="append", type=Path, default=[],
                        help="ZIP de James-Train-Mod et de LSlib_James_Fork "
                             "(plus Smart Train Combinator et flib pour STC)")
    args = parser.parse_args()
    here = Path(__file__).resolve().parent
    root = here.parents[1]
    with tempfile.TemporaryDirectory(prefix="tf-jtm-") as temporary:
        work = Path(temporary)
        build = work / "build"
        build.mkdir()
        shutil.copy2(root / "build.sh", build / "build.sh")
        for name in ["common", "variant-bp", "variant-stc", "graphics", "locale",
                     "LICENSE", "info.json"]:
            (build / name).symlink_to(root / name)
        subprocess.run(["bash", str(build / "build.sh"), "package"], check=True,
                       stdout=subprocess.DEVNULL)
        stc = args.variant == "stc"
        mod_name = "train-foundry-stc" if stc else "train-foundry"
        suffix = "_stc" if stc else ""
        mods = work / "mods"
        scenario = mods / "tf-jtm-test" / "scenarios" / "jtm"
        scenario.mkdir(parents=True)
        package = next((build / "dist").glob(f"{mod_name}_[0-9]*.zip"))
        with zipfile.ZipFile(package) as archive:
            archive.extractall(mods)
        control = mods / package.stem / "control.lua"
        control.write_text(control.read_text() + "\n" + (here / f"inspect{suffix}.lua").read_text())
        for dependency in args.dependency:
            (mods / dependency.name).symlink_to(dependency.resolve())
        shutil.copy2(here / f"control{suffix}.lua", scenario / "control.lua")
        # Les locos hybrides et les wagons électriques sont désactivés par défaut.
        (mods / "tf-jtm-test" / "settings-updates.lua").write_text(
            'for _, n in pairs({ "hybrid-trains", "electric-train-cars",\n'
            '                    "train-tiers", "train-car-tiers" }) do\n'
            '  data.raw["bool-setting"][n].default_value = true\n'
            'end\n')
        write_json(mods / "tf-jtm-test/info.json", {
            "name": "tf-jtm-test", "version": "0.0.1", "title": "JTM test",
            "author": "test", "factorio_version": "2.1",
            "dependencies": [mod_name, "James-Train-Mod"],
        })
        write_json(mods / "mod-list.json", {"mods": [
            {"name": name, "enabled": False} for name in
            ["space-age", "quality", "elevated-rails", "recycler"]]})
        config = work / "config.ini"
        config.write_text(f"[path]\nread-data={args.data.resolve()}\nwrite-data={work / 'write'}\n")
        result = subprocess.run([str(args.factorio.resolve()), "--config", str(config),
            "--mod-directory", str(mods), "--disable-audio", "--test-scenario",
            "tf-jtm-test/jtm"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, timeout=60)
        if result.returncode or "JTM_TEST_OK" not in result.stdout:
            raise RuntimeError(result.stdout)
        print(f"OK {args.variant} : " + ("validation des compositions, loco des modèles "
              "par défaut, construction sans rejet" if stc else
              "loco en tête, en queue, au milieu, deux locos"))


if __name__ == "__main__":
    main()
