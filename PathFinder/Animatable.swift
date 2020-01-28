//
//  Animatable.swift
//  PathFinder
//
//  Created by Edward Samson on 1/27/20.
//  Copyright © 2020 Edward Samson. All rights reserved.
//

import Foundation

protocol Animatable {
	var isAnimated: Bool { get }
	
	func setIsAnimated(to isAnimated: Bool)
}

