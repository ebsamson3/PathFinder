//
//  GridViewController.swift
//  PathFinder
//
//  Created by Edward Samson on 1/24/20.
//  Copyright © 2020 Edward Samson. All rights reserved.
//

import UIKit

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
		
		viewModel.reload = { [weak self] in
			self?.gridView.reload()
		}
		
		viewModel.reloadItemAtPosition = { [weak self] position in
			self?.gridView.reloadItem(at: position)
		}
		
		viewModel.reloadItemsAtPositions = { [weak self] positions in
			self?.gridView.reloadItems(atPositions: positions)
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
		
		gridView.isHidden = true
		
		coordinator.animate(alongsideTransition: { [weak self] context in
			
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
		gridView.frame = view.frame
	}
	
	func calculateGridSize() -> CGSize {
		let screenSize = UIScreen.main.bounds
		let isPortrait = screenSize.width < screenSize.height
		let minDimension = isPortrait ? screenSize.width : screenSize.height
		let maxDimension = isPortrait ? screenSize.height : screenSize.width
		let itemsAlongMin: CGFloat = 11
		let itemsAlongMax: CGFloat = round(itemsAlongMin * maxDimension / minDimension)
		return CGSize(
			width: isPortrait ? itemsAlongMin : itemsAlongMax,
			height: isPortrait ? itemsAlongMax : itemsAlongMin)
	}
	
	@objc private func handleClearGrid(_ sender: UIBarButtonItem) {
		viewModel.clearGrid()
	}
	
	@objc private func handleIsAnimated(_ sender: UIButton) {
		viewModel.setIsAnimated(to: !viewModel.isAnimated)
		sender.tintColor = viewModel.isAnimated ? .systemGreen : nil
	}
}

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
	
	func gridView(_ gridView: GridView, foregroundColorForItemAt position: Position) -> UIColor? {
		return viewModel.foregroundColorForItem(at: position)
	}
	
	func gridView(_ gridView: GridView, backgroundColorForItemAt position: Position) -> UIColor? {
		return viewModel.backgroundColorForItem(at: position)
	}
}


