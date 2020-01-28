//
//  GridViewRepresentable.swift
//  PathFinder
//
//  Created by Edward Samson on 1/24/20.
//  Copyright © 2020 Edward Samson. All rights reserved.
//

import UIKit

protocol GridViewRepresentable: AnyObject {
	var numberOfRows: Int { get }
	var numberOfColumns: Int { get }
	var reload: (() -> Void)? { get set }
	var reloadItemAtPosition: ((Position) -> Void)? { get set }
	var reloadItemsAtPositions: (([Position]) -> Void)? { get set }
	
	func touchesBegan(at position: Position)
	func touchesMoved(to position: Position)
	func touchedEnded(at position: Position)
	func backgroundColorForItem(at position: Position) -> UIColor?
	func foregroundColorForItem(at position: Position) -> UIColor?
	func clearGrid()
}
