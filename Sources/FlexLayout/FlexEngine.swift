import SwiftUI

// MARK: - FlexItemInput

/// Pure-value description of one flex item, decoupled from SwiftUI's LayoutSubview.
/// Used by FlexEngine so the algorithm can be exercised in unit tests without a
/// live SwiftUI view hierarchy.
struct FlexItemInput {
    /// Returns the item's natural size for a given layout proposal.
    var measure: (ProposedViewSize) -> CGSize
    var grow:          CGFloat
    var shrink:        CGFloat
    var basis:         FlexBasis
    var alignSelf:     AlignSelf
    var order:         Int
    var zIndex:        Int
    var position:      FlexPosition
    var explicitWidth: FlexSize
    var explicitHeight: FlexSize
    var top:           CGFloat?
    var bottom:        CGFloat?
    var leading:       CGFloat?
    var trailing:      CGFloat?

    init(
        measure:        @escaping (ProposedViewSize) -> CGSize,
        grow:           CGFloat      = 0,
        shrink:         CGFloat      = 1,
        basis:          FlexBasis    = .auto,
        alignSelf:      AlignSelf    = .auto,
        order:          Int          = 0,
        zIndex:         Int          = 0,
        position:       FlexPosition = .relative,
        explicitWidth:  FlexSize     = .auto,
        explicitHeight: FlexSize     = .auto,
        top:            CGFloat?     = nil,
        bottom:         CGFloat?     = nil,
        leading:        CGFloat?     = nil,
        trailing:       CGFloat?     = nil
    ) {
        self.measure        = measure
        self.grow           = grow
        self.shrink         = shrink
        self.basis          = basis
        self.alignSelf      = alignSelf
        self.order          = order
        self.zIndex         = zIndex
        self.position       = position
        self.explicitWidth  = explicitWidth
        self.explicitHeight = explicitHeight
        self.top            = top
        self.bottom         = bottom
        self.leading        = leading
        self.trailing       = trailing
    }

    /// Convenience for a fixed-size item — the most common form in unit tests.
    static func fixed(
        _ size: CGSize,
        grow:      CGFloat      = 0,
        shrink:    CGFloat      = 1,
        basis:     FlexBasis    = .auto,
        alignSelf: AlignSelf    = .auto,
        order:     Int          = 0,
        zIndex:    Int          = 0,
        position:  FlexPosition = .relative,
        top:       CGFloat?     = nil,
        bottom:    CGFloat?     = nil,
        leading:   CGFloat?     = nil,
        trailing:  CGFloat?     = nil
    ) -> FlexItemInput {
        FlexItemInput(
            measure:  { _ in size },
            grow:     grow,  shrink: shrink, basis: basis,
            alignSelf: alignSelf, order: order, zIndex: zIndex, position: position,
            top: top, bottom: bottom, leading: leading, trailing: trailing
        )
    }

    /// Convenience for a fixed-size item expressed as (width, height).
    static func fixed(
        width: CGFloat, height: CGFloat,
        grow:      CGFloat      = 0,
        shrink:    CGFloat      = 1,
        basis:     FlexBasis    = .auto,
        alignSelf: AlignSelf    = .auto,
        order:     Int          = 0,
        zIndex:    Int          = 0,
        position:  FlexPosition = .relative,
        top:       CGFloat?     = nil,
        bottom:    CGFloat?     = nil,
        leading:   CGFloat?     = nil,
        trailing:  CGFloat?     = nil
    ) -> FlexItemInput {
        .fixed(CGSize(width: width, height: height),
               grow: grow, shrink: shrink, basis: basis,
               alignSelf: alignSelf, order: order, zIndex: zIndex, position: position,
               top: top, bottom: bottom, leading: leading, trailing: trailing)
    }

    /// A view that fills whatever is proposed on both axes (like `Color` in SwiftUI).
    static func fill(
        grow:      CGFloat      = 0,
        shrink:    CGFloat      = 1,
        basis:     FlexBasis    = .auto,
        alignSelf: AlignSelf    = .auto,
        order:     Int          = 0,
        zIndex:    Int          = 0
    ) -> FlexItemInput {
        FlexItemInput(
            measure: { p in CGSize(width: p.width ?? 0, height: p.height ?? 0) },
            grow: grow, shrink: shrink, basis: basis,
            alignSelf: alignSelf, order: order, zIndex: zIndex
        )
    }
}

// MARK: - FlexSolution

/// Result of one FlexEngine layout pass.
struct FlexSolution {
    /// Frame of each item, indexed by input order, relative to the container origin (0,0).
    var frames: [CGRect]
    /// The proposal to use when placing each item (same index as frames).
    var proposals: [ProposedViewSize]
    /// Final size of the flex container (including padding).
    var containerSize: CGSize
}

// MARK: - Internal layout types (shared with FlexLayout)

struct RawFlexItem {
    var inputIndex:         Int
    var basisMain:          CGFloat
    var grow:               CGFloat
    var shrink:             CGFloat
    var effectiveAlignSelf: AlignSelf
    var explicitCrossSize:  CGFloat?
    var zIndex:             Int
    var top:                CGFloat?
    var bottom:             CGFloat?
    var leading:            CGFloat?
    var trailing:           CGFloat?
}

struct ComputedFlexItem {
    var inputIndex:  Int
    var mainSize:    CGFloat
    var crossSize:   CGFloat
    var mainOffset:  CGFloat
    var crossOffset: CGFloat
    var ascent:      CGFloat
    var zIndex:      Int
    var isAbsolute:  Bool     = false
    var absTop:      CGFloat? = nil
    var absBottom:   CGFloat? = nil
    var absLeading:  CGFloat? = nil
    var absTrailing: CGFloat? = nil
}

struct ComputedFlexLine {
    var items:       [ComputedFlexItem]
    var crossSize:   CGFloat
    var crossOffset: CGFloat
}

// MARK: - FlexEngine

/// Pure flex algorithm. All methods are static so the engine has no stored state.
/// FlexLayout is a thin SwiftUI wrapper that converts Subviews → [FlexItemInput]
/// and delegates to FlexEngine.
enum FlexEngine {

    // MARK: - Public entry point

    /// Compute the full layout for `inputs` inside a container of size `proposal`.
    ///
    /// Returns frames for every item, indexed by input order, relative to (0,0).
    static func solve(
        config:   FlexContainerConfig,
        inputs:   [FlexItemInput],
        proposal: ProposedViewSize
    ) -> FlexSolution {
        guard !inputs.isEmpty else {
            return FlexSolution(frames: [], proposals: [], containerSize: .zero)
        }

        let pad = config.padding
        let innerProposal = ProposedViewSize(
            width:  proposal.width.map  { max(0, $0 - pad.leading - pad.trailing) },
            height: proposal.height.map { max(0, $0 - pad.top    - pad.bottom   ) }
        )

        let (innerSize, lines, absoluteItems) =
            computeRawLayout(config: config, inputs: inputs, proposal: innerProposal)

        let containerSize = CGSize(
            width:  innerSize.width  + pad.leading + pad.trailing,
            height: innerSize.height + pad.top     + pad.bottom
        )

        var frames    = [CGRect](repeating: .zero, count: inputs.count)
        var proposals = [ProposedViewSize](repeating: .unspecified, count: inputs.count)

        let isRow    = config.direction.isRow
        let innerW   = innerSize.width
        let innerH   = innerSize.height

        // In-flow items
        for line in lines {
            for item in line.items {
                let w = isRow ? item.mainSize  : item.crossSize
                let h = isRow ? item.crossSize : item.mainSize
                let x: CGFloat
                let y: CGFloat
                if isRow {
                    x = pad.leading + item.mainOffset
                    y = pad.top     + line.crossOffset + item.crossOffset
                } else {
                    x = pad.leading + line.crossOffset + item.crossOffset
                    y = pad.top     + item.mainOffset
                }
                frames[item.inputIndex]    = CGRect(x: x, y: y, width: w, height: h)
                proposals[item.inputIndex] = ProposedViewSize(width: w, height: h)
            }
        }

        // Absolute items
        for absItem in absoluteItems {
            let finalW: CGFloat
            let finalH: CGFloat
            if isRow {
                finalW = (absItem.absLeading != nil && absItem.absTrailing != nil)
                    ? max(0, innerW - absItem.absLeading! - absItem.absTrailing!)
                    : absItem.mainSize
                finalH = (absItem.absTop != nil && absItem.absBottom != nil)
                    ? max(0, innerH - absItem.absTop! - absItem.absBottom!)
                    : absItem.crossSize
            } else {
                finalW = (absItem.absLeading != nil && absItem.absTrailing != nil)
                    ? max(0, innerW - absItem.absLeading! - absItem.absTrailing!)
                    : absItem.crossSize
                finalH = (absItem.absTop != nil && absItem.absBottom != nil)
                    ? max(0, innerH - absItem.absTop! - absItem.absBottom!)
                    : absItem.mainSize
            }

            let x: CGFloat
            if let l = absItem.absLeading        { x = pad.leading + l }
            else if let r = absItem.absTrailing   { x = pad.leading + innerW - r - finalW }
            else                                  { x = pad.leading }

            let y: CGFloat
            if let t = absItem.absTop             { y = pad.top + t }
            else if let b = absItem.absBottom     { y = pad.top + innerH - b - finalH }
            else                                  { y = pad.top }

            frames[absItem.inputIndex]    = CGRect(x: x, y: y, width: finalW, height: finalH)
            proposals[absItem.inputIndex] = ProposedViewSize(width: finalW, height: finalH)
        }

        return FlexSolution(frames: frames, proposals: proposals, containerSize: containerSize)
    }

    // MARK: - Raw layout (used by FlexLayout's sizeThatFits / placeSubviews cache)

    static func computeRawLayout(
        config:   FlexContainerConfig,
        inputs:   [FlexItemInput],
        proposal: ProposedViewSize
    ) -> (size: CGSize, lines: [ComputedFlexLine], absoluteItems: [ComputedFlexItem]) {

        let isRow    = config.direction.isRow
        let mainGap  = config.mainAxisGap
        let crossGap = config.crossAxisGap

        let mainConstraint  = (isRow ? proposal.width  : proposal.height)
            .flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
        let crossConstraint = (isRow ? proposal.height : proposal.width)
            .flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }

        // ── Step 1: Sort by CSS `order` ──────────────────────────────────────
        let sortedIndices = inputs.indices.sorted { inputs[$0].order < inputs[$1].order }

        // ── Step 1b: Partition flow vs absolute ──────────────────────────────
        var flowIndices:     [Int] = []
        var absoluteIndices: [Int] = []
        for idx in sortedIndices {
            if inputs[idx].position == .absolute {
                absoluteIndices.append(idx)
            } else {
                flowIndices.append(idx)
            }
        }

        // ── Step 2: Resolve flex-basis for flow items ─────────────────────────
        let rawItems: [RawFlexItem] = flowIndices.map { idx in
            let input       = inputs[idx]
            let rawAlignSelf = input.alignSelf
            let effectiveAlignSelf = rawAlignSelf == .auto
                ? AlignSelf(from: config.alignItems)
                : rawAlignSelf

            let mainSize   = isRow ? input.explicitWidth  : input.explicitHeight
            let crossSize  = isRow ? input.explicitHeight : input.explicitWidth
            let mainRes    = resolveFlexSizeEx(mainSize,  container: mainConstraint)
            let crossRes   = resolveFlexSizeEx(crossSize, container: crossConstraint)

            let mainExplicit: CGFloat? = {
                if case .value(let v) = mainRes { return v }
                return nil
            }()
            var crossExplicit: CGFloat?
            switch crossRes {
            case .value(let v):
                crossExplicit = v
            case .minContent:
                let p: ProposedViewSize = isRow
                    ? ProposedViewSize(width: nil, height: 0)
                    : ProposedViewSize(width: 0, height: nil)
                let sz = input.measure(p)
                crossExplicit = isRow ? sz.height : sz.width
            case .auto:
                crossExplicit = nil
            }

            let measureCross = crossExplicit
                ?? ((effectiveAlignSelf == .stretch) ? crossConstraint : nil)
            let naturalProposal: ProposedViewSize = isRow
                ? ProposedViewSize(width: nil, height: measureCross)
                : ProposedViewSize(width: measureCross, height: nil)
            let naturalSize = input.measure(naturalProposal)

            let basisMain: CGFloat
            if case .minContent = mainRes {
                let minP: ProposedViewSize = isRow
                    ? ProposedViewSize(width: 0, height: measureCross)
                    : ProposedViewSize(width: measureCross, height: 0)
                basisMain = isRow ? input.measure(minP).width : input.measure(minP).height
            } else {
                switch input.basis {
                case .auto:
                    basisMain = mainExplicit ?? (isRow ? naturalSize.width : naturalSize.height)
                case .points(let n):
                    basisMain = max(0, n)
                case .fraction(let f):
                    basisMain = mainConstraint.map { max(0, f * $0) }
                        ?? (isRow ? naturalSize.width : naturalSize.height)
                }
            }

            return RawFlexItem(
                inputIndex:         idx,
                basisMain:          basisMain,
                grow:               input.grow,
                shrink:             input.shrink,
                effectiveAlignSelf: effectiveAlignSelf,
                explicitCrossSize:  crossExplicit,
                zIndex:             input.zIndex,
                top:                input.top,
                bottom:             input.bottom,
                leading:            input.leading,
                trailing:           input.trailing
            )
        }

        // ── Step 3: Line-breaking ─────────────────────────────────────────────
        var lineGroups: [[Int]] = []

        if config.wrap == .nowrap || mainConstraint == nil {
            lineGroups = [Array(rawItems.indices)]
        } else {
            let cm = mainConstraint!
            var lineStart = 0
            var usedMain: CGFloat = 0

            for i in rawItems.indices {
                let itemMain  = rawItems[i].basisMain
                let gapBefore = (i > lineStart) ? mainGap : 0

                if i > lineStart && usedMain + gapBefore + itemMain > cm + 0.001 {
                    lineGroups.append(Array(lineStart..<i))
                    lineStart = i
                    usedMain  = itemMain
                } else {
                    usedMain += gapBefore + itemMain
                }
            }
            if lineStart < rawItems.count {
                lineGroups.append(Array(lineStart..<rawItems.count))
            }
        }

        // ── Steps 4-5: Size per line ─────────────────────────────────────────
        var lines: [ComputedFlexLine] = []

        for lineGroup in lineGroups {
            let lineRaw    = lineGroup.map { rawItems[$0] }
            let totalBasis = lineRaw.reduce(0) { $0 + $1.basisMain }
            let totalGaps  = CGFloat(max(0, lineRaw.count - 1)) * mainGap

            // Grow / shrink
            var mainSizes: [CGFloat]
            if let cm = mainConstraint {
                let free = cm - totalBasis - totalGaps
                if free > 0.5 {
                    mainSizes = resolveGrow(items: lineRaw, freeSpace: free)
                } else if free < -0.5 {
                    mainSizes = resolveShrink(items: lineRaw, overflow: -free)
                } else {
                    mainSizes = lineRaw.map { $0.basisMain }
                }
            } else {
                mainSizes = lineRaw.map { $0.basisMain }
            }

            // Cross sizes
            var crossSizes = [CGFloat](repeating: 0, count: lineRaw.count)
            var ascents    = [CGFloat](repeating: 0, count: lineRaw.count)
            var maxAscent: CGFloat = 0

            for i in lineRaw.indices {
                let input  = inputs[lineRaw[i].inputIndex]
                let mainSz = mainSizes[i]

                if let explicitCross = lineRaw[i].explicitCrossSize {
                    crossSizes[i] = explicitCross
                } else {
                    let crossProp: ProposedViewSize = isRow
                        ? ProposedViewSize(width: mainSz, height: nil)
                        : ProposedViewSize(width: nil, height: mainSz)
                    let sz        = input.measure(crossProp)
                    crossSizes[i] = isRow ? sz.height : sz.width
                }

                if lineRaw[i].effectiveAlignSelf == .baseline {
                    // Use cross size as ascent (simplified — real baseline needs ViewDimensions)
                    ascents[i] = crossSizes[i]
                    maxAscent  = max(maxAscent, ascents[i])
                }
            }

            var lineCrossSize: CGFloat = lineRaw.indices.reduce(0) { acc, i in
                max(acc, crossSizes[i])
            }
            lineCrossSize = applySingleLineCrossConstraint(
                config:          config,
                lineCrossSize:   lineCrossSize,
                crossConstraint: crossConstraint
            )

            // Final cross sizes + offsets
            var computedItems: [ComputedFlexItem] = []
            for i in lineRaw.indices {
                let mainSz = mainSizes[i]
                var finalCross = crossSizes[i]

                if lineRaw[i].effectiveAlignSelf == .stretch
                    && lineRaw[i].explicitCrossSize == nil {
                    finalCross = lineCrossSize
                }

                let crossOff = itemCrossOffset(
                    alignSelf: lineRaw[i].effectiveAlignSelf,
                    itemCross: finalCross,
                    lineCross: lineCrossSize,
                    ascent:    ascents[i],
                    maxAscent: maxAscent
                )

                computedItems.append(ComputedFlexItem(
                    inputIndex:  lineRaw[i].inputIndex,
                    mainSize:    mainSz,
                    crossSize:   finalCross,
                    mainOffset:  0,
                    crossOffset: crossOff,
                    ascent:      ascents[i],
                    zIndex:      lineRaw[i].zIndex
                ))
            }

            lines.append(ComputedFlexLine(
                items:       computedItems,
                crossSize:   lineCrossSize,
                crossOffset: 0
            ))
        }

        if config.wrap == .wrapReverse { lines.reverse() }

        // ── Step 6: Container size ────────────────────────────────────────────
        let totalLineCross = lines.reduce(0) { $0 + $1.crossSize }
        let totalCrossGaps = CGFloat(max(0, lines.count - 1)) * crossGap
        let containerCross: CGFloat = crossConstraint ?? (totalLineCross + totalCrossGaps)
        let containerMain: CGFloat
        if let cm = mainConstraint {
            containerMain = cm
        } else {
            containerMain = lines.map { line in
                line.items.reduce(0) { $0 + $1.mainSize }
                + CGFloat(max(0, line.items.count - 1)) * mainGap
            }.max() ?? 0
        }

        // ── Step 7: justify-content ───────────────────────────────────────────
        for li in lines.indices {
            let offsets = distributeMain(
                containerMain: containerMain,
                itemSizes:     lines[li].items.map { $0.mainSize },
                gap:           mainGap,
                justify:       config.justifyContent,
                reversed:      config.direction.isReversed
            )
            for i in lines[li].items.indices {
                lines[li].items[i].mainOffset = offsets[i]
            }
        }

        // ── Step 8: align-content ─────────────────────────────────────────────
        var crossOffsets = distributeLines(
            containerCross: containerCross,
            lineSizes:      lines.map { $0.crossSize },
            gap:            crossGap,
            align:          config.alignContent
        )

        if config.alignContent == .stretch && lines.count > 1 {
            let usedCross = totalLineCross + totalCrossGaps
            let extra     = (containerCross - usedCross) / CGFloat(lines.count)
            if extra > 0 {
                for li in lines.indices {
                    let newLineCross  = lines[li].crossSize + extra
                    lines[li].crossSize = newLineCross
                    let lineMaxAscent = lines[li].items.map { $0.ascent }.max() ?? 0

                    for i in lines[li].items.indices {
                        let item   = lines[li].items[i]
                        let rawIdx = rawItems.firstIndex { $0.inputIndex == item.inputIndex } ?? 0
                        let raw    = rawItems[rawIdx]
                        var finalCross = item.crossSize
                        if raw.effectiveAlignSelf == .stretch && raw.explicitCrossSize == nil {
                            finalCross = newLineCross
                        }
                        lines[li].items[i].crossSize   = finalCross
                        lines[li].items[i].crossOffset = itemCrossOffset(
                            alignSelf:  raw.effectiveAlignSelf,
                            itemCross:  finalCross,
                            lineCross:  newLineCross,
                            ascent:     item.ascent,
                            maxAscent:  lineMaxAscent
                        )
                    }
                }
                crossOffsets = distributeLines(
                    containerCross: containerCross,
                    lineSizes:      lines.map { $0.crossSize },
                    gap:            crossGap,
                    align:          config.alignContent
                )
            }
        }

        for (li, offset) in crossOffsets.enumerated() {
            lines[li].crossOffset = offset
        }

        // ── Absolute items ────────────────────────────────────────────────────
        var absoluteComputedItems: [ComputedFlexItem] = []
        for idx in absoluteIndices {
            let input = inputs[idx]
            let resW  = resolveFlexSizeEx(input.explicitWidth,
                                          container: isRow ? containerMain : containerCross)
            let resH  = resolveFlexSizeEx(input.explicitHeight,
                                          container: isRow ? containerCross : containerMain)

            let w: CGFloat
            switch resW {
            case .value(let v): w = v
            case .minContent:   w = input.measure(ProposedViewSize(width: 0,   height: nil)).width
            case .auto:         w = input.measure(ProposedViewSize(width: nil,  height: nil)).width
            }
            let h: CGFloat
            switch resH {
            case .value(let v): h = v
            case .minContent:   h = input.measure(ProposedViewSize(width: w,   height: 0  )).height
            case .auto:         h = input.measure(ProposedViewSize(width: w,   height: nil)).height
            }

            let mainSz:  CGFloat = isRow ? w : h
            let crossSz: CGFloat = isRow ? h : w

            absoluteComputedItems.append(ComputedFlexItem(
                inputIndex:  idx,
                mainSize:    mainSz,
                crossSize:   crossSz,
                mainOffset:  0,
                crossOffset: 0,
                ascent:      0,
                zIndex:      input.zIndex,
                isAbsolute:  true,
                absTop:      input.top,
                absBottom:   input.bottom,
                absLeading:  input.leading,
                absTrailing: input.trailing
            ))
        }

        let size: CGSize = isRow
            ? CGSize(width: containerMain,  height: containerCross)
            : CGSize(width: containerCross, height: containerMain)

        return (size, lines, absoluteComputedItems)
    }

    // MARK: - Helpers

    enum ResolvedFlexSize {
        case value(CGFloat)
        case minContent
        case auto
    }

    static func resolveFlexSizeEx(_ size: FlexSize, container: CGFloat?) -> ResolvedFlexSize {
        switch size {
        case .auto:          return .auto
        case .minContent:    return .minContent
        case .points(let n): return .value(max(0, n))
        case .fraction(let f):
            if let c = container { return .value(max(0, f * c)) }
            return .auto
        }
    }

    static func applySingleLineCrossConstraint(
        config:          FlexContainerConfig,
        lineCrossSize:   CGFloat,
        crossConstraint: CGFloat?
    ) -> CGFloat {
        guard config.wrap == .nowrap, let cc = crossConstraint else { return lineCrossSize }
        return max(lineCrossSize, cc)
    }

    static func resolveGrow(items: [RawFlexItem], freeSpace: CGFloat) -> [CGFloat] {
        let totalGrow = items.reduce(0) { $0 + $1.grow }
        guard totalGrow > 0 else { return items.map { $0.basisMain } }
        return items.map { $0.basisMain + ($0.grow / totalGrow) * freeSpace }
    }

    static func resolveShrink(items: [RawFlexItem], overflow: CGFloat) -> [CGFloat] {
        let totalWeight = items.reduce(0) { $0 + $1.shrink * $1.basisMain }
        guard totalWeight > 0 else { return items.map { $0.basisMain } }
        return items.map { item in
            let weight = item.shrink * item.basisMain / totalWeight
            return max(0, item.basisMain - weight * overflow)
        }
    }

    static func itemCrossOffset(
        alignSelf: AlignSelf,
        itemCross: CGFloat,
        lineCross: CGFloat,
        ascent:    CGFloat,
        maxAscent: CGFloat
    ) -> CGFloat {
        switch alignSelf {
        case .auto, .stretch, .flexStart: return 0
        case .flexEnd:                    return max(0, lineCross - itemCross)
        case .center:                     return (lineCross - itemCross) / 2
        case .baseline:                   return max(0, maxAscent - ascent)
        }
    }

    static func distributeMain(
        containerMain: CGFloat,
        itemSizes:     [CGFloat],
        gap:           CGFloat,
        justify:       JustifyContent,
        reversed:      Bool
    ) -> [CGFloat] {
        let count = itemSizes.count
        guard count > 0 else { return [] }

        let totalItems = itemSizes.reduce(0, +)
        let totalGaps  = CGFloat(max(0, count - 1)) * gap
        let free       = containerMain - totalItems - totalGaps

        var offsets = [CGFloat](repeating: 0, count: count)

        switch justify {
        case .flexStart:
            var pos: CGFloat = 0
            for i in 0..<count { offsets[i] = pos; pos += itemSizes[i] + gap }
        case .flexEnd:
            var pos: CGFloat = max(0, free)
            for i in 0..<count { offsets[i] = pos; pos += itemSizes[i] + gap }
        case .center:
            var pos: CGFloat = free / 2
            for i in 0..<count { offsets[i] = pos; pos += itemSizes[i] + gap }
        case .spaceBetween:
            let extra = count > 1 ? free / CGFloat(count - 1) : 0
            var pos: CGFloat = 0
            for i in 0..<count { offsets[i] = pos; pos += itemSizes[i] + gap + extra }
        case .spaceAround:
            let spacing = free / CGFloat(max(1, count))
            var pos: CGFloat = spacing / 2
            for i in 0..<count { offsets[i] = pos; pos += itemSizes[i] + gap + spacing }
        case .spaceEvenly:
            let spacing = free / CGFloat(count + 1)
            var pos: CGFloat = spacing
            for i in 0..<count { offsets[i] = pos; pos += itemSizes[i] + gap + spacing }
        }

        if reversed {
            return offsets.enumerated().map { i, offset in
                containerMain - offset - itemSizes[i]
            }
        }
        return offsets
    }

    static func distributeLines(
        containerCross: CGFloat,
        lineSizes:      [CGFloat],
        gap:            CGFloat,
        align:          AlignContent
    ) -> [CGFloat] {
        let count = lineSizes.count
        guard count > 0 else { return [] }

        let totalLines = lineSizes.reduce(0, +)
        let totalGaps  = CGFloat(max(0, count - 1)) * gap
        let free       = containerCross - totalLines - totalGaps

        var offsets = [CGFloat](repeating: 0, count: count)

        switch align {
        case .flexStart, .stretch:
            var pos: CGFloat = 0
            for i in 0..<count { offsets[i] = pos; pos += lineSizes[i] + gap }
        case .flexEnd:
            var pos: CGFloat = max(0, free)
            for i in 0..<count { offsets[i] = pos; pos += lineSizes[i] + gap }
        case .center:
            var pos: CGFloat = free / 2
            for i in 0..<count { offsets[i] = pos; pos += lineSizes[i] + gap }
        case .spaceBetween:
            let extra = count > 1 ? free / CGFloat(count - 1) : 0
            var pos: CGFloat = 0
            for i in 0..<count { offsets[i] = pos; pos += lineSizes[i] + gap + extra }
        case .spaceAround:
            let spacing = free / CGFloat(max(1, count))
            var pos: CGFloat = spacing / 2
            for i in 0..<count { offsets[i] = pos; pos += lineSizes[i] + gap + spacing }
        case .spaceEvenly:
            let spacing = free / CGFloat(count + 1)
            var pos: CGFloat = spacing
            for i in 0..<count { offsets[i] = pos; pos += lineSizes[i] + gap + spacing }
        }
        return offsets
    }
}
