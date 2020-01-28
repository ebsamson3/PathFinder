//
//  DijkstrasGridViewModel.swift
//  PathFinder
//
//  Created by Edward Samson on 1/24/20.
//  Copyright © 2020 Edward Samson. All rights reserved.
//

import UIKit

class GridViewModel: NSObject, GridViewRepresentable, Animatable {
	
	var reload: (() -> Void)?
	var reloadItemAtPosition: ((Position) -> Void)?
	var reloadItemsAtPositions: (([Position]) -> Void)?
	
	var numberOfRows: Int {
		return Int(gridSize.height)
	}
	
	var numberOfColumns: Int {
		return Int(gridSize.width)
	}
	
	var currentOutput: PathFinderOutput?
	
	var isAnimated = false
	var currentAnimationStep = 0
	var animationTimer: Timer?
	
	private var itemsAlongMin: CGFloat = 11
	
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
	
	private lazy var gridSize: CGSize = calculateGridSize()
	private lazy var grid: [[Int]] = createInitialGrid()
	
	let pathFinder: PathFinderProtocol
	
	init(pathFinder: PathFinderProtocol) {
		self.pathFinder = pathFinder
		super.init()
		run()
	}
	
	func calculateGridSize() -> CGSize {
		let screenSize = UIScreen.main.bounds
		let isPortrait = screenSize.width < screenSize.height
		let minDimension = isPortrait ? screenSize.width : screenSize.height
		let maxDimension = isPortrait ? screenSize.height : screenSize.width
		let itemsAlongMax: CGFloat = round(itemsAlongMin * maxDimension / minDimension)
		return CGSize(
			width: isPortrait ? itemsAlongMin : itemsAlongMax,
			height: isPortrait ? itemsAlongMax : itemsAlongMin)
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
		reloadItemAtPosition?(position)
		run()
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
		
		reloadItemsAtPositions?(positionsToReload)
		run()
	}
	
	func touchedEnded(at position: Position) {
		gridStateOfInitialTouch = nil
		displacedGridState = nil
	}
	
	func backgroundColorForItem(at position: Position) -> UIColor? {
		let gridValue = grid[position.row][position.column]
		return GridState(rawValue: gridValue)?.backgroundColor
	}
	
	func foregroundColorForItem(at position: Position) -> UIColor? {
		let gridValue = grid[position.row][position.column]
		return GridState(rawValue: gridValue)?.foregroundColor
	}
	
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
		run()
	}
	
	func setIsAnimated(to isAnimated: Bool) {
		self.isAnimated = isAnimated
		run()
	}
	
	func run() {
		pathFinder.findMinPath(
			from: startPosition,
			to: endPosition,
			inArray: grid)
		{ [weak self] output in
			
			guard let strongSelf = self else {
				return
			}
			
			self?.animationTimer?.invalidate()
			
			self?.cleanUpAnimation()
			self?.clearCurrentPath()
			
			self?.currentOutput = output
			
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
	
	@objc private func fireTimer() {
		guard let currentSteps = currentOutput?.steps else {
			finishAnimatedRun()
			return
		}
		
		let position = currentSteps[currentAnimationStep]
		
		if grid[position.row][position.column] == GridState.empty.rawValue {
			grid[position.row][position.column] = GridState.checking.rawValue
			reloadItemAtPosition?(position)
		}
		
		if currentAnimationStep + 1 >= currentSteps.count {
			finishAnimatedRun()
		} else {
			currentAnimationStep += 1
		}
	}
	
	private func cleanUpAnimation() {
		guard let currentSteps = currentOutput?.steps
		else {
			return
		}
		
		currentSteps[0...currentAnimationStep].forEach { position in
			if grid[position.row][position.column] == GridState.checking.rawValue {
				grid[position.row][position.column] = GridState.empty.rawValue
			}
		}
		
		reloadItemsAtPositions?(Array(currentSteps[0...currentAnimationStep]))
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
		reloadItemsAtPositions?(currentPath)
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
		
		reloadItemsAtPositions?(currentPath)
	}
	
	private func finishAnimatedRun() {
		animationTimer?.invalidate()
		cleanUpAnimation()
		displayCurrentPath()
	}
}
