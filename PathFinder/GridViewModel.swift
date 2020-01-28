//
//  DijkstrasGridViewModel.swift
//  PathFinder
//
//  Created by Edward Samson on 1/24/20.
//  Copyright © 2020 Edward Samson. All rights reserved.
//

import UIKit

/// Manages the connection between path finding and grid display
class GridViewModel: NSObject, GridViewRepresentable, Animatable {
	
	var reload: (() -> Void)?
	var reloadTileAtPosition: ((Position) -> Void)?
	var reloadTilessAtPositions: (([Position]) -> Void)?
	
	var numberOfRows: Int {
		return Int(gridSize.height)
	}
	
	var numberOfColumns: Int {
		return Int(gridSize.width)
	}
	
	// Current path and algorithm steps taken to get there
	var currentOutput: PathFinderOutput?
	
	// Variables for handling/tracking algorithm progress animations
	var isAnimated = false
	var currentAnimationStep = 0
	var animationTimer: Timer?
	
	private var tilesAlongMinAxis: CGFloat = 11
	
	// Start position of path finding
	private lazy var startPosition: Position = {
		
		let position: Position
		
		if numberOfRows >= numberOfColumns {
			let row = min(numberOfRows - 1, 2)
			let column = numberOfColumns / 2
			position = (row: row, column: column)
		} else {
			let row = numberOfRows / 2
			let column = min(numberOfColumns - 1, 2)
			position = (row: row, column: column)
		}
		
		return position
	}()
	
	// Targeted end position of path finding algorithm
	private lazy var endPosition: Position = {
		
		let position: Position
		
		if numberOfRows >= numberOfColumns {
			let row = max(numberOfRows - 3, 0)
			let column = numberOfColumns / 2
			position = (row: row, column: column)
		} else {
			let row = numberOfRows / 2
			let column = max(numberOfColumns - 3, 0)
			position = (row: row, column: column)
		}
		
		return position
	}()
	
	// Variables for grid size and state
	private lazy var gridSize: CGSize = calculateGridSize()
	private lazy var grid: [[Int]] = createInitialGrid()
	
	// Object for managing path finding logic
	let pathFinder: PathFinderProtocol
	
	init(pathFinder: PathFinderProtocol) {
		self.pathFinder = pathFinder
		super.init()
		updateMinPath()
	}
	
	func calculateGridSize() -> CGSize {
		let screenSize = UIScreen.main.bounds
		let isPortrait = screenSize.width < screenSize.height
		let minDimension = isPortrait ? screenSize.width : screenSize.height
		let maxDimension = isPortrait ? screenSize.height : screenSize.width
		let itemsAlongMax: CGFloat = round(tilesAlongMinAxis * maxDimension / minDimension)
		return CGSize(
			width: isPortrait ? tilesAlongMinAxis : itemsAlongMax,
			height: isPortrait ? itemsAlongMax : tilesAlongMinAxis)
	}
	
	private func createInitialGrid() -> [[Int]] {
		
		var array = Array(
			repeating: Array(repeating: GridState.empty.rawValue, count: numberOfColumns),
			count: numberOfRows)
		
		array[startPosition.row][startPosition.column] = GridState.start.rawValue
		array[endPosition.row][endPosition.column] = GridState.end.rawValue
		
		return array
	}
	
	var gridStateOfInitialTouch: GridState?
	var displacedGridState: GridState?
	
	// Handling state changes in response to user interactions
	
	func touchesBegan(at position: Position) {
		let gridValue = grid[position.row][position.column]
		
		guard let gridState = GridState(rawValue: gridValue) else {
			return
		}
		
		gridStateOfInitialTouch = gridState
		
		switch gridState {
		case .empty, .path, .checking:
			grid[position.row][position.column] = GridState.barrier.rawValue
		case .barrier:
			grid[position.row][position.column] = GridState.empty.rawValue
		default:
			return
		}
		reloadTileAtPosition?(position)
		updateMinPath()
	}
	
	func touchesMoved(to position: Position) {
		let gridValue = grid[position.row][position.column]
		
		guard
			let gridState = GridState(rawValue: gridValue),
			gridState != .start,
			gridState != .end
		else {
			return
		}
		
		var positionsToReload: [Position] = [position]
		
		switch gridStateOfInitialTouch {
		case .start:
			grid[startPosition.row][startPosition.column] = displacedGridState?.rawValue ?? GridState.empty.rawValue
			displacedGridState = gridState
			grid[position.row][position.column] = GridState.start.rawValue
			positionsToReload.append(startPosition)
			startPosition = position
		case .end:
			grid[endPosition.row][endPosition.column] = displacedGridState?.rawValue ?? GridState.empty.rawValue
			displacedGridState = gridState
			grid[position.row][position.column] = GridState.end.rawValue
			positionsToReload.append(endPosition)
			endPosition = position
		default:
			switch gridState {
			case .empty, .path, .checking:
				grid[position.row][position.column] = GridState.barrier.rawValue
			case .barrier:
				grid[position.row][position.column] = GridState.empty.rawValue
			default:
				return
			}
		}
		
		reloadTilessAtPositions?(positionsToReload)
		updateMinPath()
	}
	
	func touchedEnded(at position: Position) {
		gridStateOfInitialTouch = nil
		displacedGridState = nil
	}
	
	func backgroundColorForTile(at position: Position) -> UIColor? {
		let gridValue = grid[position.row][position.column]
		return GridState(rawValue: gridValue)?.backgroundColor
	}
	
	func foregroundColorForTile(at position: Position) -> UIColor? {
		let gridValue = grid[position.row][position.column]
		return GridState(rawValue: gridValue)?.foregroundColor
	}
	
	/// Clears all barriers on current grid
	func clearGrid() {
		guard
			grid.isEmpty == false,
			grid.first?.isEmpty == false
		else {
			return
		}
		
		for row in 0..<grid.count {
			for column in 0..<grid[0].count {
				let gridValue = grid[row][column]
				
				guard let gridState = GridState(rawValue: gridValue) else {
					continue
				}
				
				switch gridState {
				case .barrier, .path, .checking:
					grid[row][column] = GridState.empty.rawValue
				default:
					break
				}
			}
		}
		reload?()
		updateMinPath()
	}
	
	func setIsAnimated(to isAnimated: Bool) {
		self.isAnimated = isAnimated
		updateMinPath()
	}
	
	/// Finds current min path and updates displayed min path and/or min path finding animations
	func updateMinPath() {
		pathFinder.findMinPath(
			from: startPosition,
			to: endPosition,
			inArray: grid)
		{ [weak self] output in
			
			guard let strongSelf = self else {
				return
			}
			
			// Clean up old min path & animations
			self?.animationTimer?.invalidate()
			self?.cleanUpAnimation()
			self?.clearCurrentPath()
			
			self?.currentOutput = output
			
			// If animated update display on a timer otherwise show new min path
			if strongSelf.isAnimated {
				let timer = Timer(
					timeInterval: 0.05,
					target: strongSelf,
					selector: #selector(strongSelf.fireTimer),
					userInfo: nil,
					repeats: true)
				
				RunLoop.current.add(timer, forMode: .common)
				self?.animationTimer = timer
			} else {
				self?.displayCurrentPath()
			}
			
		}
	}
	
	/// Iterates through algorithm steps and makes corresponding updates to the displayed grid
	@objc private func fireTimer() {
		guard let currentSteps = currentOutput?.steps else {
			finishAnimatedRun()
			return
		}
		
		let position = currentSteps[currentAnimationStep]
		
		if grid[position.row][position.column] == GridState.empty.rawValue {
			grid[position.row][position.column] = GridState.checking.rawValue
			reloadTileAtPosition?(position)
		}
		
		if currentAnimationStep + 1 >= currentSteps.count {
			finishAnimatedRun()
		} else {
			currentAnimationStep += 1
		}
	}
	
	private func cleanUpAnimation() {
		guard
			let currentSteps = currentOutput?.steps,
			currentSteps.count > currentAnimationStep
		else {
			return
		}
		
		currentSteps[0...currentAnimationStep].forEach { position in
			if grid[position.row][position.column] == GridState.checking.rawValue {
				grid[position.row][position.column] = GridState.empty.rawValue
			}
		}
		
		reloadTilessAtPositions?(Array(currentSteps[0...currentAnimationStep]))
		currentAnimationStep = 0
	}
	
	private func clearCurrentPath() {
		guard let currentPath = currentOutput?.path else {
			return
		}
		
		currentPath.forEach { position in
			if grid[position.row][position.column] == GridState.path.rawValue {
				grid[position.row][position.column] = GridState.empty.rawValue
			}
		}
		reloadTilessAtPositions?(currentPath)
	}
	
	private func displayCurrentPath() {
		guard let currentPath = currentOutput?.path else {
			return
		}
		
		currentPath.forEach { position in
			if grid[position.row][position.column] == GridState.empty.rawValue {
				grid[position.row][position.column] = GridState.path.rawValue
			}
		}
		
		reloadTilessAtPositions?(currentPath)
	}
	
	private func finishAnimatedRun() {
		animationTimer?.invalidate()
		cleanUpAnimation()
		displayCurrentPath()
	}
}
