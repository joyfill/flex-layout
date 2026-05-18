#!/usr/bin/env python3
"""Merge manifest snapshot width+height into layout-root style rule for non-responsive
textbehavior/typography samples."""
import json
import os
import sys
from collections import OrderedDict

REPO = "/Users/vishnudutt/layout-test"
RESOURCES = os.path.join(REPO, "Sources/JoyDOMSampleSpecs/Resources")
MANIFEST_PATH = os.path.join(RESOURCES, "manifest.json")
SECTIONS = ["textbehavior", "typography"]


def load_manifest():
    with open(MANIFEST_PATH) as f:
        data = json.load(f)
    m = {}
    for entry in data.get("samples", []):
        m[entry["file"]] = entry.get("snapshot", {}) or {}
    return m


def process_sample(rel_path, abs_path, snapshot, stats):
    stem = os.path.splitext(os.path.basename(abs_path))[0]
    with open(abs_path) as f:
        sample = json.load(f, object_pairs_hook=OrderedDict)

    breakpoints = sample.get("breakpoints") or []
    if stem == "responsive" or len(breakpoints) > 0:
        stats["responsive"] += 1
        return False

    layout = sample.get("layout") or {}
    props = layout.get("props") or {}
    root_id = props.get("id")
    id_added = False
    if not root_id:
        root_id = "root"
        if "props" not in layout:
            new_layout = OrderedDict()
            inserted = False
            for k, v in layout.items():
                if k == "children" and not inserted:
                    new_layout["props"] = OrderedDict([("id", "root")])
                    inserted = True
                new_layout[k] = v
            if not inserted:
                new_layout["props"] = OrderedDict([("id", "root")])
            sample["layout"] = new_layout
            layout = new_layout
        else:
            new_props = OrderedDict([("id", "root")])
            for k, v in props.items():
                if k != "id":
                    new_props[k] = v
            layout["props"] = new_props
        id_added = True
        stats["id_added"] += 1

    selector = f"#{root_id}"
    style = sample.get("style")
    if style is None:
        style = OrderedDict()
        sample["style"] = style
    rule = style.get(selector)
    if rule is None:
        rule = OrderedDict()
        style[selector] = rule

    has_w = "width" in rule
    has_h = "height" in rule
    if has_w and has_h and not id_added:
        stats["already_bounded"] += 1
        return False

    vw = snapshot.get("viewportWidth", 360)
    vh = snapshot.get("height", 80)

    if not has_w:
        rule["width"] = OrderedDict([("value", vw), ("unit", "px")])
    if not has_h:
        rule["height"] = OrderedDict([("value", vh), ("unit", "px")])

    ordered = OrderedDict()
    for key in ("width", "height"):
        if key in rule:
            ordered[key] = rule[key]
    for k, v in rule.items():
        if k not in ordered:
            ordered[k] = v
    style[selector] = ordered

    with open(abs_path, "w") as f:
        json.dump(sample, f, indent=2)
        f.write("\n")

    stats["edited"] += 1
    return True


def main():
    manifest = load_manifest()
    overall = {}
    for section in SECTIONS:
        section_dir = os.path.join(RESOURCES, section)
        stats = {"edited": 0, "already_bounded": 0, "responsive": 0,
                 "id_added": 0, "missing_manifest": 0, "total": 0}
        for root, _, files in os.walk(section_dir):
            for name in sorted(files):
                if not name.endswith(".json"):
                    continue
                abs_path = os.path.join(root, name)
                rel = os.path.relpath(abs_path, RESOURCES)
                stats["total"] += 1
                if rel not in manifest:
                    stats["missing_manifest"] += 1
                    print(f"  [skip:no-manifest] {rel}", file=sys.stderr)
                    continue
                snapshot = manifest[rel]
                process_sample(rel, abs_path, snapshot, stats)
        overall[section] = stats

    print("\n=== Summary ===")
    fmt = "{:<14} {:>6} {:>7} {:>11} {:>11} {:>9} {:>10}"
    print(fmt.format("Section", "Total", "Edited", "AlrBounded", "Responsive", "IDAdded", "NoManifest"))
    for s, st in overall.items():
        print(fmt.format(s, st["total"], st["edited"], st["already_bounded"],
                         st["responsive"], st["id_added"], st["missing_manifest"]))


if __name__ == "__main__":
    main()
