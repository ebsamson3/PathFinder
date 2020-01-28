//
//  GridState.swift
//  PathFinder
//
//  Created by Edward Samson on 1/25/20.
//  Copyright © 2020 Edward Samson. All rights reserved.
//

import UIKit

enum GridState: Int {
	case empty
	case start
	case end
	case barrier
	case path
	case checking
	
	var foregroundColor: UIColor? {
		switch self {
		case .path:
			return .systemTeal
		case .checking:
			return .random
		default:
			return nil
		}
	}
	
	var backgroundColor: UIColor? {
		switch self {
		case .empty, .path, .checking:
			return .black
		case .start:
			return .systemGreen
		case .end:
			return .systemRed
		case .barrier:
			return .white
		}
	}
}
