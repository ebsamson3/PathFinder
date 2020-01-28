//
//  DijkstrasController.swift
//  PathFinder
//
//  Created by Edward Samson on 1/23/20.
//  Copyright © 2020 Edward Samson. All rights reserved.
//

import SwiftUI

class DijkstrasController: PathFinderProtocol {
	
	private var currentWorkItem: DispatchWorkItem?
	
	private struct Neighbor: Identifiable, Comparable {
		typealias ID = Int
		
		var id: Int
		var distance: Double
		
		static func < (lhs: Neighbor, rhs: Neighbor) -> Bool {
			return lhs.distance < rhs.distance
		}
	}

	private static func getId(fromPosition position: Position, columnCount: Int) -> Int {
		return position.row * columnCount + position.column
	}

	private static func getPosition(fromId id: Int, columnCount: Int) -> Position {
		let result = id.quotientAndRemainder(dividingBy: columnCount)
		return (row: result.quotient, column: result.remainder)
	}
	
	func findMinPath(
		from start: Position,
		to finish: Position,
		inArray array: [[Int]],
		completion: @escaping (PathFinderOutput) -> ())
	{
		
		var workItem: DispatchWorkItem!
		
		workItem = DispatchWorkItem {
			
			var visitedVertices = Set<Int>()
			var parents = [Int: Int]()
			
			let rowCount = array.count
			let columnCount = array[0].count
			
			let heap = UniqueMinHeap<Neighbor>()
			let startId = Self.getId(fromPosition: start, columnCount: columnCount)
			let finishId = Self.getId(fromPosition: finish, columnCount: columnCount)
			
			let startVertex = Neighbor(id: startId, distance: 0)
			heap.add(startVertex)
			
			var steps = [Position]()
			
			while let vertex = heap.poll() {
				guard !workItem.isCancelled else {
					break
				}
				
				let position = Self.getPosition(fromId: vertex.id, columnCount: columnCount)
				
				steps.append(position)
				visitedVertices.insert(vertex.id)
				
				guard vertex.id != finishId else {
					break
				}
				
				let minRow = max(position.row - 1, 0)
				let maxRow = min(position.row + 1, rowCount - 1)
				let minColumn = max(position.column - 1, 0)
				let maxColumn = min(position.column + 1, columnCount - 1)
				
				for row in minRow...maxRow {
					for column in minColumn...maxColumn {
						
						let neighbor: Position = (row: row, column: column)
						let id = Self.getId(fromPosition: neighbor, columnCount: columnCount)
						
						guard !visitedVertices.contains(id) else {
							continue
						}
						
						guard array[row][column] != GridState.barrier.rawValue else {
							continue
						}
						
						let verticalDistance = row - position.row
						let horizontalDistance = column - position.column 
						
						if
							verticalDistance != 0 &&
							horizontalDistance != 0 &&
							array[position.row + verticalDistance][position.column] == GridState.barrier.rawValue &&
							array[position.row][position.column + horizontalDistance] == GridState.barrier.rawValue
						{
							continue
						}
						
						let distance = sqrt(pow(Double(horizontalDistance), 2) + pow(Double(verticalDistance), 2))
						
						let totalDistance = vertex.distance + distance
						
						if
							let previousTotalDistance = heap.checkFor(itemWithId: id)?.distance,
							previousTotalDistance <= totalDistance
						{
							continue
						}
						
						heap.add(Neighbor(id: id, distance: totalDistance))
						parents[id] = vertex.id
					}
				}
			}
			
			var currentId: Int? = finishId
			var path: [Position]? = []
			
			while currentId != nil {
				let position = Self.getPosition(fromId: currentId!, columnCount: columnCount)
				currentId = parents[currentId!]
				path?.append(position)
			}
			
			let didFindStart = path?.last?.row == start.row && path?.last?.column == start.column
			
			
			path = didFindStart ? path?.reversed() : nil
			
			DispatchQueue.main.async {
				completion((path: path, steps: steps))
				workItem = nil
			}
		}
		
		DispatchQueue.global(qos: .userInitiated).async { [weak self] in
			self?.currentWorkItem?.cancel()
			self?.currentWorkItem = workItem
			workItem.perform()
		}
	}
}
