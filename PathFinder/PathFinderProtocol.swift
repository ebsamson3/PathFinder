//
//  PathFinderProtocol.swift
//  PathFinder
//
//  Created by Edward Samson on 1/24/20.
//  Copyright © 2020 Edward Samson. All rights reserved.
//

import Foundation
typealias PathFinderOutput = (path: [Position]?, steps: [Position])

protocol PathFinderProtocol {
	func findMinPath(
		from start: Position,
		to finish: Position,
		inArray array: [[Int]],
		completion: @escaping (PathFinderOutput) -> ())
}
