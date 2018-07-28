//
//  ColumnsViewController.swift
//  FileBrowser
//
//  Created by Bruno Philipe on 4/7/18.
//  Copyright © 2018 Bruno Philipe. All rights reserved.
//

import UIKit

/// UINavigationController replacement that displays children controllers in a column layout when enough
/// space is available
public class ColumnsViewController: UIViewController
{
	public var mode: Mode = .navigation
	{
		didSet
		{
			if mode != oldValue
			{
				modeHasChanged()
			}
		}
	}

	private var childNavigationController = UINavigationController()
	private let scrollView = UIScrollView()
	private let stackView = UIStackView()
	private var stackViewWidthConstraint: NSLayoutConstraint!
	private var stackViewChildControllers: [UIViewController] = []

	override open func viewDidLoad()
	{
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		scrollView.translatesAutoresizingMaskIntoConstraints = false
		scrollView.alwaysBounceHorizontal = true
		view.addSubview(scrollView)

		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.axis = .horizontal
		stackView.distribution = .fillEqually
		stackView.spacing = 1 / (view.window?.screen.scale ?? 1)
		stackView.backgroundColor = .darkGray
		scrollView.addSubview(stackView)

		stackViewWidthConstraint = stackView.widthAnchor.constraint(equalToConstant: scrollView.frame.width)

		NSLayoutConstraint.activate([
			view.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
			scrollView.rightAnchor.constraint(equalTo: view.rightAnchor),
			view.topAnchor.constraint(equalTo: scrollView.topAnchor),
			scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
			stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
			stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
			stackViewWidthConstraint
		])

		// Activate the current mode
		modeHasChanged()
    }
    
	override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?)
	{
		super.traitCollectionDidChange(previousTraitCollection)

		if traitCollection.verticalSizeClass == .regular && traitCollection.horizontalSizeClass == .regular
		{
			mode = .stackview
		}
		else
		{
			mode = .navigation
		}
	}

	open override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()

		updateStackViewWidthConstraint()
	}

	private func updateStackViewWidthConstraint()
	{
		let newWidth = max(scrollView.frame.width, CGFloat(360 * stackViewChildControllers.count))

		if stackViewWidthConstraint.constant != newWidth
		{
			stackViewWidthConstraint.constant = newWidth
			scrollView.contentSize = CGSize(width: newWidth, height: scrollView.frame.height)
		}
	}

	open func pushViewController(_ viewController: UIViewController, animated: Bool)
	{
		switch mode
		{
		case .navigation:	childNavigationController.pushViewController(viewController, animated: animated)
		case .stackview:	pushColumn(viewController, animated: animated)
		}
	}

	private func pushColumn(_ viewController: UIViewController, animated: Bool)
	{
		let containerViewController = UINavigationController(rootViewController: viewController)
		addChildViewController(containerViewController)
		stackView.addArrangedSubview(containerViewController.view)
		stackViewChildControllers.append(containerViewController)

		let traitCollection = UITraitCollection(traitsFrom: [
			self.traitCollection,
			UITraitCollection(horizontalSizeClass: .compact)
		])

		setOverrideTraitCollection(traitCollection, forChildViewController: containerViewController)

		updateStackViewWidthConstraint()
	}

	private func popColumn(animated: Bool) -> UIViewController?
	{
		guard
			let containerViewController = stackViewChildControllers.popLast(),
			let viewController = (containerViewController as? UINavigationController)?.viewControllers.first
		else
		{
			// ERROR
			return nil
		}

		stackView.removeArrangedSubview(containerViewController.view)
		setOverrideTraitCollection(nil, forChildViewController: containerViewController)
		containerViewController.removeFromParentViewController()
		viewController.removeFromParentViewController()

		return viewController
	}

	private func modeHasChanged()
	{
		switch mode
		{
		case .navigation:
			var viewControllers: [UIViewController] = []
			var viewController: UIViewController? = nil

			repeat
			{
				viewController = popColumn(animated: false)

				if let viewController = viewController
				{
					viewControllers.insert(viewController, at: 0)
				}
			}
			while viewController != nil

			scrollView.isHidden = true
			childNavigationController = UINavigationController()
			addChildViewController(childNavigationController)
			view.addSubview(childNavigationController.view)

			NSLayoutConstraint.activate([
				view.leftAnchor.constraint(equalTo: childNavigationController.view.leftAnchor),
				childNavigationController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
				view.topAnchor.constraint(equalTo: childNavigationController.view.topAnchor),
				childNavigationController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
			])

			viewControllers.forEach({ childNavigationController.pushViewController($0, animated: false) })

		case .stackview:
			let viewControllers = childNavigationController.viewControllers
			childNavigationController.setViewControllers([], animated: false)
			childNavigationController.view.removeFromSuperview()
			childNavigationController.removeFromParentViewController()

			for viewController in viewControllers
			{
				pushColumn(viewController, animated: false)
			}

			scrollView.isHidden = false
		}
	}

	public enum Mode
	{
		case navigation, stackview
	}
}
