import SwiftUI

/// A SwiftUI `Layout` that implements the full CSS Flexbox specification.
///
/// Use `FlexBox` (in `FlexView.swift`) as a convenient SwiftUI view wrapper,
/// or call `FlexLayout` directly as a layout container:
///
/// ```swift
/// FlexLayout(.init(direction: .row, wrap: .wrap, gap: 8)) {
///     Text("A").flexItem(grow: 1)
///     Text("B").flexItem(basis: .points(120))
/// }
/// ```
public struct FlexLayout: Layout {

    public var config: FlexContainerConfig

    public init(_ config: FlexContainerConfig = FlexContainerConfig()) {
        self.config = config
    }

    // MARK: - Cache

    public struct Cache {
        var lines:         [ComputedFlexLine] = []
        var absoluteItems: [ComputedFlexItem] = []
        var containerSize: CGSize = .zero
    }

    // MARK: - Layout Protocol

    public func makeCache(subviews: Subviews) -> Cache { Cache() }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let pad = config.padding
        let innerProposal = ProposedViewSize(
            width:  proposal.width.map  { max(0, $0 - pad.leading - pad.trailing) },
            height: proposal.height.map { max(0, $0 - pad.top     - pad.bottom  ) }
        )

        let inputs = makeInputs(from: subviews)
        let result = FlexEngine.computeRawLayout(
            config:   config,
            inputs:   inputs,
            proposal: innerProposal
        )
        cache.lines         = result.lines
        cache.absoluteItems = result.absoluteItems

        let contentW = result.size.width  + pad.leading + pad.trailing
        let contentH = result.size.height + pad.top     + pad.bottom
        let isRow = config.direction.isRow

        let mainContent   = isRow ? contentW : contentH
        let crossContent  = isRow ? contentH : contentW
        let mainProposal  = isRow ? proposal.width  : proposal.height
        let crossProposal = isRow ? proposal.height : proposal.width

        // Main axis: wrapping containers stay within their allocation; otherwise fill proposal.
        let finalMain: CGFloat
        if config.wrap != .nowrap, let mp = mainProposal, mp.isFinite {
            finalMain = mp
        } else {
            finalMain = mainProposal.flatMap { $0.isFinite ? max(mainContent, $0) : nil }
                ?? mainContent
        }
        // Cross axis: fill the proposed cross size (flex container acts like a block box).
        let finalCross = crossProposal.flatMap { $0.isFinite ? max(crossContent, $0) : nil }
            ?? crossContent

        cache.containerSize = isRow
            ? CGSize(width: finalMain, height: finalCross)
            : CGSize(width: finalCross, height: finalMain)
        return cache.containerSize
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        guard !subviews.isEmpty else { return }

        // Always recompute using actual placement bounds — sizeThatFits may have
        // returned a larger size (cross-axis fill), so the cached result may not match.
        let pad = config.padding
        let innerProposal = ProposedViewSize(
            width:  (bounds.width  > 0) ? max(0, bounds.width  - pad.leading - pad.trailing) : nil,
            height: (bounds.height > 0) ? max(0, bounds.height - pad.top     - pad.bottom  ) : nil
        )

        let inputs = makeInputs(from: subviews)
        let solution = FlexEngine.solve(
            config:   config,
            inputs:   inputs,
            proposal: ProposedViewSize(width: bounds.width, height: bounds.height)
        )

        // Use the solution frames to place every subview.
        // solution.frames are relative to (0,0); shift by bounds origin.
        _ = innerProposal  // retained for documentation clarity
        for i in inputs.indices {
            let frame    = solution.frames[i]
            let proposal = solution.proposals[i]
            subviews[i].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                anchor: .topLeading,
                proposal: proposal
            )
        }
    }

    // MARK: - applySingleLineCrossConstraint (exposed for legacy unit tests)

    func applySingleLineCrossConstraint(
        _ lineCrossSize: CGFloat,
        crossConstraint: CGFloat?
    ) -> CGFloat {
        FlexEngine.applySingleLineCrossConstraint(
            config:          config,
            lineCrossSize:   lineCrossSize,
            crossConstraint: crossConstraint
        )
    }

    // MARK: - Subview → FlexItemInput conversion

    private func makeInputs(from subviews: Subviews) -> [FlexItemInput] {
        subviews.map { sv in
            FlexItemInput(
                measure:        { sv.sizeThatFits($0) },
                grow:           sv[FlexGrowKey.self],
                shrink:         sv[FlexShrinkKey.self],
                basis:          sv[FlexBasisKey.self],
                alignSelf:      sv[AlignSelfKey.self],
                order:          sv[FlexOrderKey.self],
                zIndex:         sv[FlexZIndexKey.self],
                position:       sv[FlexPositionKey.self],
                explicitWidth:  sv[FlexWidthKey.self],
                explicitHeight: sv[FlexHeightKey.self],
                top:            sv[FlexTopKey.self],
                bottom:         sv[FlexBottomKey.self],
                leading:        sv[FlexLeadingKey.self],
                trailing:       sv[FlexTrailingKey.self]
            )
        }
    }

    // MARK: - Min-content helper

    private func minContentSize(
        subview: Subviews.Element,
        axis: Axis,
        otherAxisSize: CGFloat? = nil
    ) -> CGFloat {
        let proposal: ProposedViewSize
        switch axis {
        case .horizontal:
            proposal = ProposedViewSize(width: 0, height: otherAxisSize)
        case .vertical:
            proposal = ProposedViewSize(width: otherAxisSize, height: 0)
        }
        let sz = subview.sizeThatFits(proposal)
        return axis == .horizontal ? sz.width : sz.height
    }

    private enum Axis { case horizontal, vertical }
}
