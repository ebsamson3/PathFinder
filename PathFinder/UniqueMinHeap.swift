//
//  UniqueMinHeap.swift
//  PathFinder
//
//  Created by Edward Samson on 1/23/20.
//  Copyright © 2020 Edward Samson. All rights reserved.
//

import SwiftUI

class UniqueMinHeap<T: Identifiable & Comparable> {
	
	private var items = [T]()
	private var positions = [T.ID: Int]()
	
	func peek() -> T? {
		return items.first
	}
	
	func checkFor(itemWithId id: T.ID) -> T? {
		guard let position = positions[id] else {
			return nil
		}
		return items[position]
	}
	
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
	
	private func swapAt(_ i: Int, _ j: Int) {
		positions.updateValue(i, forKey: items[j].id)
		positions.updateValue(j, forKey: items[i].id)
		items.swapAt(i, j)
	}
	
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
