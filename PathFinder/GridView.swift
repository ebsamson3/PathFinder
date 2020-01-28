//
//  GridView.swift
//  PathFinder
//
//  Created by Edward Samson on 1/24/20.
//  Copyright © 2020 Edward Samson. All rights reserved.
//

import UIKit

protocol GridViewDelegate: AnyObject {
	func numberOfRows(in gridView: GridView) -> Int
	func numberOfColumns(in gridView: GridView) -> Int
	func gridView(_ gridView: GridView, touchesBeganAt position: Position)
	func gridView(_ gridView: GridView, touchesMovedTo position: Position)
	func gridView(_ gridView: GridView, touchesEndedAt position: Position)
	func gridView(_ gridView: GridView, foregroundColorForItemAt position: Position) -> UIColor?
	func gridView(_ gridView: GridView, backgroundColorForItemAt position: Position) -> UIColor?
}

class GridView: UIView {
	
	weak var delegate: GridViewDelegate?
	
	private var layers = [[CAShapeLayer]]()
	private var layerPositions = [ObjectIdentifier: Position]()

	init() {
		super.init(frame: CGRect.zero)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		if layers.isEmpty {
			addSublayers()
		} else {
			updateBoundsForSublayers()
		}
	}
	
	var lastTouchedLayer: CAShapeLayer?
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard
			let point = touches.first?.location(in: nil),
			let layerTouched = layer.hitTest(point) as? CAShapeLayer,
			lastTouchedLayer != layerTouched,
			let position = layerPositions[ObjectIdentifier(layerTouched)]
		else {
			return
		}
		delegate?.gridView(self, touchesBeganAt: position)
		lastTouchedLayer = layerTouched
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard
			let point = touches.first?.location(in: nil),
			let layerTouched = layer.hitTest(point) as? CAShapeLayer,
			lastTouchedLayer != layerTouched,
			let position = layerPositions[ObjectIdentifier(layerTouched)]
		else {
			return
		}
		delegate?.gridView(self, touchesMovedTo: position)
		lastTouchedLayer = layerTouched
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard
			let point = touches.first?.location(in: nil),
			let layerTouched = layer.hitTest(point) as? CAShapeLayer,
			let position = layerPositions[ObjectIdentifier(layerTouched)]
		else {
			return
		}
		delegate?.gridView(self, touchesEndedAt: position)
		lastTouchedLayer = nil
	}
	
	func reload() {
		addSublayers()
	}
	
	func reloadItem(at position: Position) {
		setColorsForItem(at: position)
	}
	
	func reloadItems(atPositions positions: [Position]) {
		
		positions.forEach {
			setColorsForItem(at: $0)
		}
	}
	
	private func setColorsForItem(at position: Position) {
		let layer = layers[position.row][position.column]
		layer.backgroundColor = delegate?.gridView(self, backgroundColorForItemAt: position)?.cgColor
		layer.fillColor = delegate?.gridView(self, foregroundColorForItemAt: position)?.cgColor
	}
	
	private func addSublayers() {
		layer.sublayers?.removeAll()
		layerPositions.removeAll()
		
		guard let delegate = delegate else {
			return
		}
		
		let numberOfRows = delegate.numberOfRows(in: self)
		let numberOfColumns = delegate.numberOfColumns(in: self)
		
		layers = [[CAShapeLayer]]()
		
		CATransaction.begin()
		
		CATransaction.setDisableActions(true)
		
		for row in 0..<numberOfRows {
			layers.append([])
			
			for column in 0..<numberOfColumns {
				let item = CAShapeLayer()
				layers[row].append(item)
				let position: Position = (row: row, column: column)
				setColorsForItem(at: position)
				item.borderColor = UIColor.darkGray.cgColor
				item.borderWidth = 1
				layerPositions[ObjectIdentifier(item)] = (row: row, column: column)
				layer.addSublayer(item)
			}
		}
		CATransaction.commit()
		updateBoundsForSublayers()
	}
	
	private func updateBoundsForSublayers() {
		guard !layers.isEmpty else {
			return
		}
		
		guard let numberOfColumns = layers.first?.count else {
			return
		}
		
		let numberOfRows = layers.count
		let itemWidth = floor(bounds.width / CGFloat(numberOfColumns))
		let itemHeight = floor(bounds.height / CGFloat(numberOfRows))
		let leftoverHorizontalPixels = Int(bounds.width - itemWidth * CGFloat(numberOfColumns))
		let leftoverVerticalPixels = Int(bounds.height - itemHeight * CGFloat(numberOfRows))
		
		for row in 0..<numberOfRows {
			
			let height = CGFloat(itemHeight + (row < leftoverVerticalPixels ? 1 : 0))
			let y = itemHeight * CGFloat(row) + CGFloat(min(row, leftoverVerticalPixels))
			
			for column in 0..<numberOfColumns {
				let width = CGFloat(itemWidth + (column < leftoverHorizontalPixels ? 1 : 0))
				let x = itemWidth * CGFloat(column) + CGFloat(min(column, leftoverHorizontalPixels))
				let layerFrame = CGRect(x: x, y: y, width: width, height: height)
				let item = layers[row][column]
				item.frame = layerFrame
				
				let layerBounds = item.bounds
				
				let center = CGPoint(x: layerBounds.midX, y: layerBounds.midY)
				let radius = (min(layerBounds.width, layerBounds.height) - 2) / 2
				
				let path = UIBezierPath(
					arcCenter: center,
					radius: radius,
					startAngle: 0,
					endAngle: 2 * CGFloat.pi,
					clockwise: true)
				
				item.path = path.cgPath
			}
		}
	}
}

