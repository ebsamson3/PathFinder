//
//  GridViewController.swift
//  PathFinder
//
//  Created by Edward Samson on 1/24/20.
//  Copyright © 2020 Edward Samson. All rights reserved.
//

import UIKit

/// Handles grid view display and user interaction
class GridViewController: UIViewController {
	
	private lazy var gridView: GridView = {
		let gridView = GridView()
		gridView.delegate = self
		return gridView
	}()
	
	private lazy var clearGridButton = UIBarButtonItem(
		barButtonSystemItem: .trash,
		target: self,
		action: #selector(handleClearGrid(_:)))
	
	private lazy var isAnimatedButton = UIBarButtonItem(
		barButtonSystemItem: .play,
		target: self,
		action: #selector(handleIsAnimated(_:)))
	
	let viewModel: GridViewRepresentable & Animatable
	
	init(viewModel: GridViewRepresentable & Animatable) {
		self.viewModel = viewModel
		super.init(nibName: nil, bundle: nil)
		
		// Binding to view model
		
		viewModel.reload = { [weak self] in
			self?.gridView.reload()
		}
		
		viewModel.reloadItemAtPosition = { [weak self] position in
			self?.gridView.reloadTile(at: position)
		}
		
		viewModel.reloadItemsAtPositions = { [weak self] positions in
			self?.gridView.reloadTiles(atPositions: positions)
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		navigationItem.rightBarButtonItems = [clearGridButton, isAnimatedButton]
		isAnimatedButton.tintColor = viewModel.isAnimated ? .systemGreen : nil
		configure()
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		// Update grid frame on view bounds changes
		
		let topInset = view.safeAreaInsets.top
		let frame = CGRect(
			x: view.frame.origin.x,
			y: view.frame.origin.y + topInset,
			width: view.frame.width,
			height: view.frame.height - topInset)

		gridView.frame = frame
		gridView.center = CGPoint(x: frame.midX, y: frame.midY)
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		
		// Used to have grid view ignore device orientation changes
		
		gridView.isHidden = true
		
		coordinator.animate(alongsideTransition: { [weak self] context in
			
			//TODO: Decided to hide the grid during rotation so animating the grids rotation changes are no longer neccesary
			
			guard let strongSelf = self else {
				return
			}
			
			let deltaTransform = coordinator.targetTransform
			let deltaAngle = atan2(deltaTransform.b, deltaTransform.a)
			
			if var currentRotation = strongSelf.gridView.layer.value(forKeyPath: "transform.rotation.z") as? CGFloat {
				currentRotation += -1 * deltaAngle + 0.0001
				strongSelf.gridView.layer.setValue(currentRotation, forKeyPath: "transform.rotation.z")
			}
			
		}) { [weak self]  context in
			
			guard let strongSelf = self else {
				return
			}
			
			// Rounding transform to undo the additional small angle used to control CA rotation direction
			
			var currentTransform = strongSelf.gridView.transform
			currentTransform.a = round(currentTransform.a)
			currentTransform.b = round(currentTransform.b)
			currentTransform.c = round(currentTransform.c)
			currentTransform.d = round(currentTransform.d)
			strongSelf.gridView.transform = currentTransform
			
			strongSelf.gridView.isHidden = false
		}
	}
	
	private func configure() {
		view.backgroundColor = .black
		view.addSubview(gridView)
	}
	
	@objc private func handleClearGrid(_ sender: UIBarButtonItem) {
		viewModel.clearGrid()
	}
	
	@objc private func handleIsAnimated(_ sender: UIButton) {
		viewModel.setIsAnimated(to: !viewModel.isAnimated)
		sender.tintColor = viewModel.isAnimated ? .systemGreen : nil
	}
}

//MARK: GridViewDelegate

extension GridViewController: GridViewDelegate {
	
	func numberOfRows(in gridView: GridView) -> Int {
		return viewModel.numberOfRows
	}
	
	func numberOfColumns(in gridView: GridView) -> Int {
		return viewModel.numberOfColumns
	}
	
	func gridView(_ gridView: GridView, touchesBeganAt position: Position) {
		viewModel.touchesBegan(at: position)
	}
	
	func gridView(_ gridView: GridView, touchesMovedTo position: Position) {
		viewModel.touchesMoved(to: position)
	}
	
	func gridView(_ gridView: GridView, touchesEndedAt position: Position) {
		viewModel.touchedEnded(at: position)
	}
	
	func gridView(_ gridView: GridView, foregroundColorForTileAt position: Position) -> UIColor? {
		return viewModel.foregroundColorForItem(at: position)
	}
	
	func gridView(_ gridView: GridView, backgroundColorForTileAt position: Position) -> UIColor? {
		return viewModel.backgroundColorForItem(at: position)
	}
}


