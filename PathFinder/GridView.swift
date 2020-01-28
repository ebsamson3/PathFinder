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
	func gridView(_ gridView: GridView, foregroundColorForTileAt position: Position) -> UIColor?
	func gridView(_ gridView: GridView, backgroundColorForTileAt position: Position) -> UIColor?
}

/// Grid of tiles with a circular foreground and a bordered, square background
class GridView: UIView {
	
	weak var delegate: GridViewDelegate?
	
	// Layers for each tile
	private var tiles = [[CAShapeLayer]]()
	private var tilePositions = [ObjectIdentifier: Position]()

	init() {
		super.init(frame: CGRect.zero)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		if tiles.isEmpty {
			addSublayers()
		} else {
			updateBoundsForSublayers()
		}
	}
	
	// Tracking user interactions
	
	var lastTouchedTile: CAShapeLayer?
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard
			let point = touches.first?.location(in: nil),
			let layerTouched = layer.hitTest(point) as? CAShapeLayer,
			lastTouchedTile != layerTouched,
			let position = tilePositions[ObjectIdentifier(layerTouched)]
		else {
			return
		}
		delegate?.gridView(self, touchesBeganAt: position)
		lastTouchedTile = layerTouched
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard
			let point = touches.first?.location(in: nil),
			let layerTouched = layer.hitTest(point) as? CAShapeLayer,
			lastTouchedTile != layerTouched,
			let position = tilePositions[ObjectIdentifier(layerTouched)]
		else {
			return
		}
		delegate?.gridView(self, touchesMovedTo: position)
		lastTouchedTile = layerTouched
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard
			let point = touches.first?.location(in: nil),
			let layerTouched = layer.hitTest(point) as? CAShapeLayer,
			let position = tilePositions[ObjectIdentifier(layerTouched)]
		else {
			return
		}
		delegate?.gridView(self, touchesEndedAt: position)
		lastTouchedTile = nil
	}
	
	// Tiles colors are updated in an analogous way to UITableViewCells 
	
	func reload() {
		addSublayers()
	}
	
	func reloadTile(at position: Position) {
		setColorsForTile(at: position)
	}
	
	func reloadTiles(atPositions positions: [Position]) {
		
		positions.forEach {
			setColorsForTile(at: $0)
		}
	}
	
	private func setColorsForTile(at position: Position) {
		let tile = tiles[position.row][position.column]
		
		tile.backgroundColor = delegate?.gridView(self, backgroundColorForTileAt: position)?.cgColor
		tile.fillColor = delegate?.gridView(self, foregroundColorForTileAt: position)?.cgColor
	}
	
	/// Adds a shape layer for each tile to the main grid view
	private func addSublayers() {
		layer.sublayers?.removeAll()
		tilePositions.removeAll()
		
		guard let delegate = delegate else {
			return
		}
		
		let numberOfRows = delegate.numberOfRows(in: self)
		let numberOfColumns = delegate.numberOfColumns(in: self)
		
		tiles = [[CAShapeLayer]]()
		
		CATransaction.begin()
		CATransaction.setDisableActions(true) // Stops default animations
		
		for row in 0..<numberOfRows {
			tiles.append([])
			
			for column in 0..<numberOfColumns {
				let tile = CAShapeLayer()
				tiles[row].append(tile)
				let position: Position = (row: row, column: column)
				setColorsForTile(at: position)
				tile.borderColor = UIColor.darkGray.cgColor
				tile.borderWidth = 1
				tilePositions[ObjectIdentifier(tile)] = (row: row, column: column)
				layer.addSublayer(tile)
			}
		}
		CATransaction.commit()
		updateBoundsForSublayers()
	}
	
	// Updates the bounds and circumscribed circular paths of each sublayer
	private func updateBoundsForSublayers() {
		guard !tiles.isEmpty else {
			return
		}
		
		guard let numberOfColumns = tiles.first?.count else {
			return
		}
		
		let numberOfRows = tiles.count
		let tileWidth = floor(bounds.width / CGFloat(numberOfColumns))
		let tileHeight = floor(bounds.height / CGFloat(numberOfRows))
		let leftoverHorizontalPixels = Int(bounds.width - tileWidth * CGFloat(numberOfColumns))
		let leftoverVerticalPixels = Int(bounds.height - tileHeight * CGFloat(numberOfRows))
		
		for row in 0..<numberOfRows {
			
			let height = CGFloat(tileHeight + (row < leftoverVerticalPixels ? 1 : 0))
			let y = tileHeight * CGFloat(row) + CGFloat(min(row, leftoverVerticalPixels))
			
			for column in 0..<numberOfColumns {
				let width = CGFloat(tileWidth + (column < leftoverHorizontalPixels ? 1 : 0))
				let x = tileWidth * CGFloat(column) + CGFloat(min(column, leftoverHorizontalPixels))
				let tileFrame = CGRect(x: x, y: y, width: width, height: height)
				let tile = tiles[row][column]
				tile.frame = tileFrame
				
				let tileBounds = tile.bounds
				
				let center = CGPoint(x: tileBounds.midX, y: tileBounds.midY)
				let radius = (min(tileBounds.width, tileBounds.height) - 2) / 2
				
				let path = UIBezierPath(
					arcCenter: center,
					radius: radius,
					startAngle: 0,
					endAngle: 2 * CGFloat.pi,
					clockwise: true)
				
				tile.path = path.cgPath
			}
		}
	}
}

