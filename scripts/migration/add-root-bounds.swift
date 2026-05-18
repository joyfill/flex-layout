import Foundation

let repo = "/Users/vishnudutt/layout-test"
let resources = "\(repo)/Sources/JoyDOMSampleSpecs/Resources"
let manifestPath = "\(resources)/manifest.json"
let sections = ["textbehavior", "typography"]

func readJSON(_ path: String) -> Any {
    let data = try! Data(contentsOf: URL(fileURLWithPath: path))
    return try! JSONSerialization.jsonObject(with: data, options: [.mutableContainers, .mutableLeaves])
}

func writeJSON(_ obj: Any, to path: String) {
    let data = try! JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted])
    var s = String(data: data, encoding: .utf8)!
    if !s.hasSuffix("\n") { s += "\n" }
    try! s.write(toFile: path, atomically: true, encoding: .utf8)
}

let manifestObj = readJSON(manifestPath) as! [String: Any]
let samples = manifestObj["samples"] as! [[String: Any]]
var manifestMap: [String: [String: Any]] = [:]
for s in samples {
    if let file = s["file"] as? String {
        manifestMap[file] = (s["snapshot"] as? [String: Any]) ?? [:]
    }
}

struct Stats {
    var total = 0, edited = 0, alreadyBounded = 0, responsive = 0, idAdded = 0, missingManifest = 0
}
var perSection: [String: Stats] = [:]

let fm = FileManager.default

func enumerate(_ dir: String) -> [String] {
    var result: [String] = []
    if let e = fm.enumerator(atPath: dir) {
        while let f = e.nextObject() as? String {
            if f.hasSuffix(".json") {
                result.append("\(dir)/\(f)")
            }
        }
    }
    result.sort()
    return result
}

for section in sections {
    var st = Stats()
    let sectionDir = "\(resources)/\(section)"
    for absPath in enumerate(sectionDir) {
        let rel = String(absPath.dropFirst(resources.count + 1))
        st.total += 1
        guard let snapshot = manifestMap[rel] else {
            st.missingManifest += 1
            FileHandle.standardError.write("  [skip:no-manifest] \(rel)\n".data(using: .utf8)!)
            continue
        }

        let stem = ((rel as NSString).lastPathComponent as NSString).deletingPathExtension
        let sample = readJSON(absPath) as! NSMutableDictionary
        let breakpoints = (sample["breakpoints"] as? [Any]) ?? []
        if stem == "responsive" || !breakpoints.isEmpty {
            st.responsive += 1
            continue
        }

        let layout = (sample["layout"] as? NSMutableDictionary) ?? NSMutableDictionary()
        var propsAny = layout["props"]
        var props = (propsAny as? NSMutableDictionary) ?? NSMutableDictionary()
        var rootId = props["id"] as? String
        var idAdded = false
        if rootId == nil || rootId!.isEmpty {
            rootId = "root"
            let newProps = NSMutableDictionary()
            newProps["id"] = "root"
            for (k, v) in props {
                if let ks = k as? String, ks != "id" {
                    newProps[ks] = v
                }
            }
            props = newProps
            // Rebuild layout dict with key order: type, props, then others, children last
            let oldKeys: [String] = layout.allKeys.compactMap { $0 as? String }
            var orderedKeys: [String] = []
            if oldKeys.contains("type") { orderedKeys.append("type") }
            orderedKeys.append("props")
            for k in oldKeys where k != "type" && k != "props" && k != "children" { orderedKeys.append(k) }
            if oldKeys.contains("children") { orderedKeys.append("children") }
            let snapshotVals: [(String, Any)] = orderedKeys.compactMap { k in
                if k == "props" { return (k, props) }
                if let v = layout[k] { return (k, v) }
                return nil
            }
            layout.removeAllObjects()
            for (k, v) in snapshotVals { layout[k] = v }
            sample["layout"] = layout
            idAdded = true
            st.idAdded += 1
            propsAny = props
        }

        let selector = "#\(rootId!)"
        var style = (sample["style"] as? NSMutableDictionary)
        if style == nil {
            style = NSMutableDictionary()
            // Insert style before breakpoints/layout — rebuild sample
            let oldKeys: [String] = sample.allKeys.compactMap { $0 as? String }
            var orderedKeys: [String] = []
            if oldKeys.contains("version") { orderedKeys.append("version") }
            orderedKeys.append("style")
            for k in oldKeys where k != "version" && k != "style" { orderedKeys.append(k) }
            let snapshotVals: [(String, Any)] = orderedKeys.compactMap { k in
                if k == "style" { return (k, style!) }
                if let v = sample[k] { return (k, v) }
                return nil
            }
            sample.removeAllObjects()
            for (k, v) in snapshotVals { sample[k] = v }
        }
        var rule = (style![selector] as? NSMutableDictionary)
        if rule == nil {
            rule = NSMutableDictionary()
            style![selector] = rule!
        }
        let hasW = rule!["width"] != nil
        let hasH = rule!["height"] != nil
        if hasW && hasH && !idAdded {
            st.alreadyBounded += 1
            continue
        }

        let vw = (snapshot["viewportWidth"] as? Int) ?? 360
        let vh = (snapshot["height"] as? Int) ?? 80

        let newRule = NSMutableDictionary()
        if !hasW {
            let w = NSMutableDictionary()
            w["value"] = vw
            w["unit"] = "px"
            newRule["width"] = w
        } else {
            newRule["width"] = rule!["width"]
        }
        if !hasH {
            let h = NSMutableDictionary()
            h["value"] = vh
            h["unit"] = "px"
            newRule["height"] = h
        } else {
            newRule["height"] = rule!["height"]
        }
        for (k, v) in rule! {
            if let ks = k as? String, ks != "width" && ks != "height" {
                newRule[ks] = v
            }
        }
        style![selector] = newRule

        writeJSON(sample, to: absPath)
        st.edited += 1
    }
    perSection[section] = st
}

print("\n=== Summary ===")
print(String(format: "%-14@ %6@ %7@ %11@ %11@ %9@ %10@",
             "Section" as NSString, "Total" as NSString, "Edited" as NSString,
             "AlrBounded" as NSString, "Responsive" as NSString,
             "IDAdded" as NSString, "NoManifest" as NSString))
for section in sections {
    let st = perSection[section]!
    print(String(format: "%-14@ %6d %7d %11d %11d %9d %10d",
                 section as NSString, st.total, st.edited, st.alreadyBounded, st.responsive, st.idAdded, st.missingManifest))
}
