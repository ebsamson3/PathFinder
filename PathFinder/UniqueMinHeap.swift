//
//  UniqueMinHeap.swift
//  PathFinder
//
//  Created by Edward Samson on 1/23/20.
//  Copyright © 2020 Edward Samson. All rights reserved.
//

import SwiftUI

/// Data structure that facilitates removal of the min value with an O(1) time efficiency. Only 1 item per unique ID can be inserted into the heap. New items with ID's already present in the heap will replace the old heaped items.
class UniqueMinHeap<T: Identifiable & Comparable> {
	
	private var items = [T]()
	private var positions = [T.ID: Int]()
	
	//MARK: API
	
	/// Gets min value w/o removing from heap
	func peek() -> T? {
		return items.first
	}
	
	/// Gets min value and removes it from the heap
	func poll() -> T? {
		
		guard let lastItem = items.popLast() else {
			return nil
		}
		
		guard
			let firstItem = items.first
		else {
			positions.removeValue(forKey: lastItem.id)
			return lastItem
		}
		
		items[0] = lastItem
		positions.updateValue(0, forKey: lastItem.id)
		positions.removeValue(forKey: firstItem.id)
		heapifyDown(from: 0)
		return firstItem
	}
	
	/// Adds a new item to the heap
	func add(_ item: T) {
		
		let position: Int
		
		if let oldPosition = positions[item.id] {
			items[oldPosition] = item
			position = oldPosition
		} else {
			items.append(item)
			position = items.count - 1
		}
		
		positions.updateValue(position, forKey: item.id)
		heapifyUp(from: position)
		
		guard
			let newPosition = positions[item.id],
			newPosition == position
		else {
			return
		}
		
		heapifyDown(from: newPosition)
	}
	
	/// Check to see if an item with the correpsonding ID is already in the heap
	func checkFor(itemWithId id: T.ID) -> T? {
		guard let position = positions[id] else {
			return nil
		}
		return items[position]
	}
	
	//MARK: Helper functions for finding parent and child heap items
	
	private func getLeftChildIndex(of index: Int) -> Int? {
		let childIndex = 2 * index + 1
		return childIndex < items.count ? childIndex : nil
	}
	
	private func getRightChildIndex(of index: Int) -> Int? {
		let childIndex = 2 * index + 2
		return childIndex < items.count ? childIndex : nil
	}
	
	private func getParentIndex(of index: Int) -> Int? {
		return index > 0 ? (index - 1) / 2 : nil
	}
	
	//MARK: Heap state management
	
	/// Swap two item positions in heap
	private func swapAt(_ i: Int, _ j: Int) {
		positions.updateValue(i, forKey: items[j].id)
		positions.updateValue(j, forKey: items[i].id)
		items.swapAt(i, j)
	}
	
	// Move item up in heap if it's value is less than any number of it's parents
	private func heapifyUp(from index: Int) {
		var index = index
		
		while
			let parentIndex = getParentIndex(of: index),
			items[parentIndex] > items[index]
		{
			swapAt(index, parentIndex)
			index = parentIndex
		}
	}
	
	// Move item down in heap if it's value is greater than any of it's parents
	private func heapifyDown(from index: Int) {
		var index = index
		
		while let leftIndex = getLeftChildIndex(of: index) {
			
			let smallerChildIndex: Int
			
			if
				let rightIndex = getRightChildIndex(of: index),
				items[rightIndex] < items[leftIndex]
			{
				smallerChildIndex = rightIndex
			} else {
				smallerChildIndex = leftIndex
			}
			
			if items[index] < items[smallerChildIndex] {
				break
			}
			
			swapAt(index, smallerChildIndex)
			index = smallerChildIndex
		}
	}
}
