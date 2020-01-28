//
//  DijkstrasController.swift
//  PathFinder
//
//  Created by Edward Samson on 1/23/20.
//  Copyright © 2020 Edward Samson. All rights reserved.
//

import SwiftUI

/// Finds the min path through a 2-D grid with barriers using Dijkstra's algorithm
class DijkstrasController: PathFinderProtocol {
	
	private var currentWorkItem: DispatchWorkItem?
	
	// Struct representing a nearest neighbor to a grid position. Has a unique ID for compatibility with UniqueMinHeap.
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
	
	/// Calculates the min path through a grid with barriers
	func findMinPath(
		from start: Position,
		to finish: Position,
		inArray array: [[Int]],
		completion: @escaping (PathFinderOutput) -> ())
	{
		
		// Cancellable item that performs path finding work
		var workItem: DispatchWorkItem!
		
		workItem = DispatchWorkItem {
			
			var visitedVertices = Set<Int>()
			var parents = [Int: Int]()
			
			let rowCount = array.count
			let columnCount = array[0].count
			
			// Heap for storing min paths
			let heap = UniqueMinHeap<Neighbor>()
			
			// Ids for starting and finishing positions
			let startId = Self.getId(fromPosition: start, columnCount: columnCount)
			let finishId = Self.getId(fromPosition: finish, columnCount: columnCount)
			
			// Adding initial min to the heap
			let startVertex = Neighbor(id: startId, distance: 0)
			heap.add(startVertex)
			
			var steps = [Position]()
			
			// While there is a min to remove from the heap
			while let vertex = heap.poll() {
				guard !workItem.isCancelled else {
					break
				}
				
				let position = Self.getPosition(fromId: vertex.id, columnCount: columnCount)
				
				steps.append(position)
				visitedVertices.insert(vertex.id)
				
				// If the min path leads to the finish position then stop
				guard vertex.id != finishId else {
					break
				}
				
				// Define valid row and column ranges for neighboring positions of current min path
				let minRow = max(position.row - 1, 0)
				let maxRow = min(position.row + 1, rowCount - 1)
				let minColumn = max(position.column - 1, 0)
				let maxColumn = min(position.column + 1, columnCount - 1)
				
				// For each neighboring position, calculate the min path length to that position and insert into heap
				for row in minRow...maxRow {
					for column in minColumn...maxColumn {
						
						let neighbor: Position = (row: row, column: column)
						let id = Self.getId(fromPosition: neighbor, columnCount: columnCount)
						
						// If already chosen as a potential min, skip
						guard !visitedVertices.contains(id) else {
							continue
						}
						
						// If position is a barrier, skip
						guard array[row][column] != GridState.barrier.rawValue else {
							continue
						}
						
						let verticalDistance = row - position.row
						let horizontalDistance = column - position.column 
						
						// Prevents path from going through diagnal walls
						if
							verticalDistance != 0 &&
							horizontalDistance != 0 &&
							array[position.row + verticalDistance][position.column] == GridState.barrier.rawValue &&
							array[position.row][position.column + horizontalDistance] == GridState.barrier.rawValue
						{
							continue
						}
						
						// Find distancce to neighbor from current position
						let distance = sqrt(pow(Double(horizontalDistance), 2) + pow(Double(verticalDistance), 2))
						
						// Distance to current position + distance between current position and neighbor
						let totalDistance = vertex.distance + distance
						
						// If the total min path length to neighbor is shorter than any previously calculated path lengths to that neighbor, add it to min heap. Replace old min-heap-stored path to neighbor if neccesary.
						if
							let previousTotalDistance = heap.checkFor(itemWithId: id)?.distance,
							previousTotalDistance <= totalDistance
						{
							continue
						}
						
						heap.add(Neighbor(id: id, distance: totalDistance))
						
						// Track parent of neihboring position, aka the position that must be taken in order to reach the neighbor.
						parents[id] = vertex.id
					}
				}
			}
			
			// Starting at the end position, work backwards through the parent positions until you reach the start position to retrieve the shortest path
			
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
			}
		}
		
		// Take care to perform and cancel the work items on the same thread
		DispatchQueue.global(qos: .userInitiated).async { [weak self] in
			self?.currentWorkItem?.cancel()
			self?.currentWorkItem = workItem
			workItem.perform()
		}
	}
}
