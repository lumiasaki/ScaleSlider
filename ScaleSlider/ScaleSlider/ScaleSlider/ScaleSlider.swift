//
//  ScaleSlider.swift
//  ScaleSlider
//
//  Created by Lumia_Saki on 2021/1/27.
//

import Foundation
import UIKit

public class ScaleSlider: UIView {
    
    /// Configurations for the slider, `scaleInterval` must be a valid value for slider displaying, which means the `scaleInterval` needs to be met the requirement with the `minimumScale` and `maximumScale`.
    public struct Configuration {
        
        var minimumScale: Int
        var maximumScale: Int
        var scaleInterval: Int
        var defaultValue: Int
        
        init?(minimumScale: Int, maximumScale: Int, scaleInterval: Int, defaultValue: Int? = nil) {
            guard scaleInterval != 0, maximumScale > minimumScale, (maximumScale - minimumScale) % scaleInterval == 0, ((maximumScale - minimumScale) / scaleInterval) + 1 > 1 else {
                return nil
            }
            
            self.minimumScale = minimumScale
            self.maximumScale = maximumScale
            self.scaleInterval = scaleInterval
            self.defaultValue = defaultValue ?? minimumScale
        }
    }
    
    // MARK: - Index
    
    /// Index structure for representing a scale.
    public class Index: NSObject {
                
        public var title: String
        public var selected: Bool
        
        public init(title: String, selected: Bool) {
            self.title = title
            self.selected = selected
        }
    }
    
    // MARK: - IndexView
        
    /// View for an `Index`.
    private class IndexView: UIView {
        
        private lazy var scaleLabel: UILabel = {
            let view = UILabel()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.font = .systemFont(ofSize: 12)
            view.textColor = .lightGray
            return view
        }()
        
        var scaleIndex: Index? {
            willSet {
                guard let scaleIndex = newValue else {
                    return
                }
                
                scaleLabel.text = scaleIndex.title
                scaleLabel.textColor = scaleIndex.selected ? .orange : .lightGray
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            setUp()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUp() {
            addSubview(scaleLabel)
            
            NSLayoutConstraint.activate([
                scaleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
                scaleLabel.topAnchor.constraint(equalTo: topAnchor),
                scaleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
                scaleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
            ])
        }
    }
    
    // MARK: - ScaleSlider
        
    /// Callback when value changed.
    public var scaleValueChanged: ((ScaleSlider) -> Void)?
    
    /// Configuration, must be set during initialization.
    private(set) var configuration: Configuration
    
    /// Current selected instance of `Index`, should never be nil.
    private(set) var selectedIndex: Index! {
        willSet {
            guard newValue != selectedIndex else {
                return
            }
            
            if #available(iOS 10, *) {
                impactGenerator.impactOccurred()
            }
                        
            for index in scaleIndices {
                index.selected = index == newValue
            }
            
            updateIndexViews(from: scaleIndices)
        }
        
        didSet {
            guard oldValue != selectedIndex else {
                return
            }
                        
            scaleValueChanged?(self)
        }
    }
    
    private lazy var indicesContainer: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.distribution = .equalCentering
        return view
    }()
    
    private lazy var slider: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .lightGray
        return view
    }()
    
    private lazy var indicator: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        view.layer.cornerRadius = 14
        view.backgroundColor = .orange
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(indicatorPanned(sender:)))
        view.addGestureRecognizer(gesture)
        
        return view
    }()
    
    private var indicatorLeadingConstraint: NSLayoutConstraint!
    
    private var scaleIndices: [Index]!
    private var scaleIndexViews: [IndexView]!
        
    private var cachedBounds: CGRect?
    private var ranges: [ClosedRange<CGFloat>]?
    
    /// A tuple for saving current possible index and range, since the principle of locality.
    private var possibleIndexAndRange: (index: Int, range: ClosedRange<CGFloat>)?
    
    @available(iOS 10.0, *)
    private lazy var impactGenerator: UIImpactFeedbackGenerator = {
        UIImpactFeedbackGenerator(style: .medium)
    }()
    
    /// Initializer, configuration should be valid one.
    /// - Parameter configuration: The configuration for the slider.
    public init(configuration: Configuration) {
        self.configuration = configuration
        
        let indices = Self.indices(from: configuration)
        
        self.scaleIndices = indices
        self.selectedIndex = indices.first { $0.selected }
        
        super.init(frame: .zero)
        
        setUp()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if indicator.frame.contains(point) {
            return indicator
        }
                
        if indicator.frame.origin.y ... indicator.frame.origin.y + indicator.frame.height ~= point.y {
            return self
        }
        
        return super.hitTest(point, with: event)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if let cachedBounds = cachedBounds, cachedBounds == bounds {
            return
        }
        
        cachedBounds = bounds
        
        DispatchQueue.main.async {
            let positionX = self.indicesContainer.arrangedSubviews.map { $0.frame.origin.x }
                
            var ranges: [ClosedRange<CGFloat>] = []
            for (index, x) in positionX.enumerated() {
                if index < positionX.count - 1 {
                    ranges.append(x...positionX[index + 1])
                }
            }
            
            self.ranges = ranges
            
            if let indexOfSelectedScaleIndex = self.scaleIndices.firstIndex(of: self.selectedIndex), indexOfSelectedScaleIndex < self.scaleIndexViews.count {
                let selectedIndexView = self.scaleIndexViews[indexOfSelectedScaleIndex]
                
                self.indicatorLeadingConstraint.constant = selectedIndexView.frame.origin.x + selectedIndexView.bounds.width / 2
                
                self.layoutIfNeeded()
            }
        }
    }
    
    private func setUp() {
        do {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(sliderTapped(sender:)))
            addGestureRecognizer(gesture)
        }
        
        addSubview(indicesContainer)
        
        NSLayoutConstraint.activate([
            indicesContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            indicesContainer.topAnchor.constraint(equalTo: topAnchor),
            indicesContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
        ])
        
        addSubview(slider)
        addSubview(indicator)
        
        NSLayoutConstraint.activate([
            slider.topAnchor.constraint(equalTo: indicesContainer.bottomAnchor, constant: 12),
            slider.leadingAnchor.constraint(equalTo: leadingAnchor),
            slider.bottomAnchor.constraint(equalTo: bottomAnchor),
            slider.trailingAnchor.constraint(equalTo: trailingAnchor),
            slider.heightAnchor.constraint(equalToConstant: 10)
        ])
        
        indicatorLeadingConstraint = indicator.centerXAnchor.constraint(equalTo: indicesContainer.leadingAnchor)
        
        NSLayoutConstraint.activate([
            indicatorLeadingConstraint,
            indicator.widthAnchor.constraint(equalToConstant: 28),
            indicator.heightAnchor.constraint(equalToConstant: 28),
            indicator.centerYAnchor.constraint(equalTo: slider.centerYAnchor)
        ])
        
        scaleIndexViews = indexViews(from: scaleIndices)
        
        for (index, view) in scaleIndexViews.enumerated() {
            if index != 0 {
                let separateView = UIView()
                NSLayoutConstraint.activate([
                    separateView.widthAnchor.constraint(equalToConstant: 1)
                ])
                
                indicesContainer.addArrangedSubview(separateView)
            }
            indicesContainer.addArrangedSubview(view)
        }
    }
        
    @objc
    private func indicatorPanned(sender: UIPanGestureRecognizer) {
        gestureTouched(at: sender.location(in: self).x)
    }
        
    @objc
    private func sliderTapped(sender: UITapGestureRecognizer) {
        gestureTouched(at: sender.location(in: self).x)
    }
        
    private func gestureTouched(at x: CGFloat) {
        guard let ranges = self.ranges else {
            return
        }
        
        if let possibleIndexAndRange = possibleIndexAndRange, possibleIndexAndRange.range ~= x {
            moveIndicator(to: possibleIndexAndRange.range, index: possibleIndexAndRange.index)
            return
        }
        
        for (index, range) in ranges.enumerated() where range ~= (x) {
            possibleIndexAndRange = (index, range)
            
            moveIndicator(to: range, index: index)
        }
    }
    
    private func moveIndicator(to range: ClosedRange<CGFloat>, index: Int) {
        indicatorLeadingConstraint.constant = (index % 2 == 0 ? range.lowerBound : range.upperBound) + scaleIndexViews[Int(ceilf(Float(index) / 2.0))].bounds.width / 2
        selectedIndex = scaleIndices[Int(ceilf(Float(index) / 2.0))]
        
        UIView.animate(withDuration: 0.1) { self.layoutIfNeeded() }
    }
}

extension ScaleSlider {
    
    enum Error: Swift.Error {
        case generateIndicesError
    }
    
    private static func indices(from configuration: Configuration) -> [Index] {
        let numberOfIndices = ((configuration.maximumScale - configuration.minimumScale) / configuration.scaleInterval) + 1
        
        var result: [Index] = []
                
        var hasValidDefaultValue: Bool?
        
        for i in 0 ..< numberOfIndices {
            let isDefaultIndex = configuration.minimumScale + i * configuration.scaleInterval == configuration.defaultValue
            if hasValidDefaultValue == nil && isDefaultIndex {
                hasValidDefaultValue = isDefaultIndex
            }
                        
            result.append(Index(title: String(configuration.minimumScale + i * configuration.scaleInterval), selected: isDefaultIndex))
        }
                
        // default value is invalid, try to find a valid one after the middle index.
        if hasValidDefaultValue == nil {
            result.afterMiddle(1)?.selected = true
        }
        
        return result
    }
}

extension ScaleSlider {
    
    private func updateIndexViews(from indices: [Index]) {
        guard scaleIndexViews.count == indices.count else {
            return
        }
        
        for (index, scaleIndex) in indices.enumerated() {
            scaleIndexViews[index].scaleIndex = scaleIndex
        }
    }
    
    private func indexViews(from indices: [Index]) -> [IndexView] {
        return indices.map {
            let view = IndexView()
            view.scaleIndex = $0
            return view
        }
    }
}

private extension Array where Element: ScaleSlider.Index {
    
    func afterMiddle(_ x: Index) -> Element? {
        guard count != 0 else {
            return nil
        }

        let middleIndex = (count > 1 ? count - 1 : count) / 2
        guard middleIndex + x < count else {
            return nil
        }
        
        return self[middleIndex + x]
    }
}
