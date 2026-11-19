//
//  LockScreenView.swift
//  SixLS
//
//  Created by Skitty on 11/26/20.
//  Copyright © 2020 Skitty. All rights reserved.
//

import UIKit

@objc final public class LockScreenView: UIView {
	let statusBarBackground = UIView()
	let topGrabber = UIView()
	let bottomGrabber = UIView()
	let dateView = DateBarView()
	let lockView = LockBarView()
	let chargingView = ChargingView()
	let nowPlayingView = NowPlayingArtView()
	let wallpaperGradient = UIImageView()
	let fakeCameraBackground = UIView()

	var dateViewHeightConstraint: NSLayoutConstraint?

    // Long-press the clock for 1.5 seconds to open the on-device editor.
    private let editorKey = "com.7lock.layout.v1"
    private let editorElements = ["Clock", "Date", "Unlock", "Camera"]
    private var editorSelection = 0
    private var editorPanel: UIView?
    private var editorX = UISlider()
    private var editorY = UISlider()
    private var editorSize = UISlider()
    private var editorValueLabels = [UILabel]()
    private var editorOffsets: [[CGFloat]] = [[0,0,67],[0,0,16],[0,0,20],[0,0,26]]


	let notificationAlertView = NotificationAlertView(request: nil)
	let notificationTableView = UITableView(frame: .zero, style: .plain)

	@objc var notificationList: NCNotificationStructuredSectionList? {
		didSet {
			if let requests = notificationList?.allNotificationRequests {
				notifications = requests.sorted {
					$0.timestamp.compare($1.timestamp) == .orderedDescending
				}
			}
		}
	}

	@objc var notifications = [NCNotificationRequest]() {
		didSet {
			reloadNotifications()
		}
	}

	private var statusBarHeight: CGFloat {
		var height: CGFloat = 0
		if #available(iOS 14.0, *) {
			height = CGFloat(UIStatusBar._height(forStyle: 306,
												 orientation: 1,
												 forStatusBarFrame: false,
												 inWindow: nil))
			if height <= 0 {
				height = CGFloat(UIStatusBar_Modern._height(forStyle: 1,
															orientation: 1,
															forStatusBarFrame: false,
															inWindow: nil))
			}
		} else {
			height = CGFloat(UIStatusBar._height(forStyle: 306,
												 orientation: 1,
												 forStatusBarFrame: false))
			if height <= 0 {
				height = CGFloat(UIStatusBar_Modern._height(forStyle: 1,
															orientation: 1,
															forStatusBarFrame: false))
			}
		}
		return height
	}

	var hideTopBar: Bool? {
		didSet {
			dateView.isHidden = hideTopBar ?? false
		}
	}
	var hideBottomBar: Bool? {
		didSet {
			lockView.isHidden = hideBottomBar ?? false
		}
	}
	var unlockText: String? {
		didSet {
			lockView.unlockSlider.text = unlockText
		}
	}
	var timeBarDisabled = false
	var useNotifications = true
	var useChargingView = true

	override init(frame: CGRect) {
		super.init(frame: frame)

		configureViews()

		lockView.delegate = self
		notificationTableView.delegate = self
		notificationTableView.dataSource = self

		notificationTableView.estimatedRowHeight = 47
		notificationTableView.rowHeight = UITableView.automaticDimension

		addSubview(wallpaperGradient)
		addSubview(chargingView)
		addSubview(nowPlayingView)
		addSubview(dateView)
		addSubview(lockView)
		addSubview(fakeCameraBackground)
		addSubview(notificationTableView)
		addSubview(notificationAlertView)
		addSubview(statusBarBackground)
		addSubview(topGrabber)
		addSubview(bottomGrabber)

		activateConstraints()
        loadEditorOffsets()
        applyEditorOffsets()
        let editorGesture = UILongPressGestureRecognizer(target: self, action: #selector(openLayoutEditor(_:)))
        editorGesture.minimumPressDuration = 1.5
        dateView.addGestureRecognizer(editorGesture)
        dateView.isUserInteractionEnabled = true
		observePreferences()

		NotificationCenter.default.addObserver(self,
											   selector: #selector(observePreferences),
											   name: Notification.Name("observePreferences"),
											   object: nil)
		NotificationCenter.default.addObserver(self,
											   selector: #selector(updatePlayingState),
											   name: Notification.Name("nowPlayingUpdate"),
											   object: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func configureViews() {
		statusBarBackground.backgroundColor = .clear
		for grabber in [topGrabber, bottomGrabber] {
			grabber.backgroundColor = UIColor.white.withAlphaComponent(0.72)
			grabber.layer.cornerRadius = 2.5
			grabber.isUserInteractionEnabled = false
			grabber.translatesAutoresizingMaskIntoConstraints = false
		}
		statusBarBackground.translatesAutoresizingMaskIntoConstraints = false

		dateView.translatesAutoresizingMaskIntoConstraints = false
		lockView.translatesAutoresizingMaskIntoConstraints = false

		chargingView.isHidden = true
		chargingView.translatesAutoresizingMaskIntoConstraints = false

		nowPlayingView.isHidden = true
		nowPlayingView.translatesAutoresizingMaskIntoConstraints = false

		wallpaperGradient.image = UIImage.forSix(named: "sb")
		wallpaperGradient.contentMode = .scaleToFill
		wallpaperGradient.translatesAutoresizingMaskIntoConstraints = false

		fakeCameraBackground.backgroundColor = .black
		fakeCameraBackground.translatesAutoresizingMaskIntoConstraints = false

		notificationAlertView.isHidden = true
		notificationAlertView.translatesAutoresizingMaskIntoConstraints = false

		notificationTableView.backgroundColor = .clear
		notificationTableView.separatorColor = .clear
		notificationTableView.allowsSelection = false
		notificationTableView.isHidden = true
		notificationTableView.translatesAutoresizingMaskIntoConstraints = false
	}

	func activateConstraints() {
		topGrabber.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
		topGrabber.topAnchor.constraint(equalTo: topAnchor, constant: 7).isActive = true
		topGrabber.widthAnchor.constraint(equalToConstant: 38).isActive = true
		topGrabber.heightAnchor.constraint(equalToConstant: 5).isActive = true
		bottomGrabber.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
		bottomGrabber.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
		bottomGrabber.widthAnchor.constraint(equalToConstant: 38).isActive = true
		bottomGrabber.heightAnchor.constraint(equalToConstant: 5).isActive = true
		statusBarBackground.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
		statusBarBackground.heightAnchor.constraint(equalToConstant: statusBarHeight).isActive = true

		dateView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
		dateView.topAnchor.constraint(equalTo: topAnchor, constant: statusBarHeight).isActive = true
		dateView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
		dateViewHeightConstraint = dateView.heightAnchor.constraint(equalToConstant: 105)
		dateViewHeightConstraint?.isActive = true

		lockView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
		lockView.topAnchor.constraint(equalTo: bottomAnchor, constant: -95).isActive = true
		lockView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
		lockView.heightAnchor.constraint(equalToConstant: 95).isActive = true

		chargingView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
		chargingView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true

		nowPlayingView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
		nowPlayingView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true

		wallpaperGradient.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
		wallpaperGradient.heightAnchor.constraint(equalTo: heightAnchor).isActive = true

		fakeCameraBackground.topAnchor.constraint(equalTo: lockView.bottomAnchor).isActive = true
		fakeCameraBackground.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
		fakeCameraBackground.heightAnchor.constraint(equalTo: heightAnchor).isActive = true

		notificationAlertView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
		notificationAlertView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
		notificationAlertView.heightAnchor.constraint(equalToConstant: 79.5).isActive = true

		if UIDevice.current.model.hasPrefix("iPad") {
			notificationAlertView.widthAnchor.constraint(equalToConstant: 357).isActive = true
		} else {
			notificationAlertView.widthAnchor.constraint(equalTo: widthAnchor, constant: -18).isActive = true
		}

		notificationTableView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
		notificationTableView.topAnchor.constraint(equalTo: dateView.bottomAnchor).isActive = true
		notificationTableView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
		notificationTableView.bottomAnchor.constraint(equalTo: lockView.topAnchor).isActive = true
	}

    private func loadEditorOffsets() {
        guard let saved = UserDefaults.standard.array(forKey: editorKey) as? [[Double]], saved.count == 4 else { return }
        for i in 0..<4 where saved[i].count == 3 {
            editorOffsets[i] = saved[i].map { CGFloat($0) }
        }
    }

    private func applyEditorOffsets() {
        dateView.timeLabel.transform = CGAffineTransform(translationX: editorOffsets[0][0], y: editorOffsets[0][1])
        dateView.dateLabel.transform = CGAffineTransform(translationX: editorOffsets[1][0], y: editorOffsets[1][1])
        lockView.unlockSlider.glintyTextView.transform = CGAffineTransform(translationX: editorOffsets[2][0], y: editorOffsets[2][1])
        lockView.cameraGrabber.transform = CGAffineTransform(translationX: editorOffsets[3][0], y: editorOffsets[3][1])
        dateView.timeLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: editorOffsets[0][2]) ?? UIFont.systemFont(ofSize: editorOffsets[0][2], weight: .ultraLight)
        dateView.dateLabel.font = UIFont(name: "HelveticaNeue-Medium", size: editorOffsets[1][2]) ?? UIFont.systemFont(ofSize: editorOffsets[1][2], weight: .medium)
        lockView.unlockSlider.font = UIFont(name: "HelveticaNeue-Light", size: editorOffsets[2][2]) ?? UIFont.systemFont(ofSize: editorOffsets[2][2], weight: .light)
        // Keep the camera touch target unchanged; scale only the rendered image.
        let scale = editorOffsets[3][2] / 26.0
        lockView.cameraGrabber.transform = CGAffineTransform(translationX: editorOffsets[3][0], y: editorOffsets[3][1]).scaledBy(x: scale, y: scale)
    }

    @objc private func openLayoutEditor(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, editorPanel == nil else { return }
        editorSelection = 0
        let panel = UIView()
        panel.backgroundColor = UIColor(white: 0.10, alpha: 0.97)
        panel.layer.cornerRadius = 15
        panel.layer.borderWidth = 1
        panel.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        panel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(panel)
        bringSubviewToFront(panel)
        editorPanel = panel
        // Keep the editor interactive above the underlying lockscreen views.
        panel.isUserInteractionEnabled = true
        NSLayoutConstraint.activate([
            panel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            panel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            panel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            panel.heightAnchor.constraint(equalToConstant: 285)
        ])
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 7
        stack.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: panel.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -12)
        ])
        let title = UILabel()
        title.text = "7lock · Layout Editor"
        title.textColor = .white
        title.textAlignment = .center
        title.font = UIFont.boldSystemFont(ofSize: 16)
        stack.addArrangedSubview(title)
        let picker = UISegmentedControl(items: editorElements)
        picker.selectedSegmentIndex = 0
        picker.addTarget(self, action: #selector(editorChangedElement(_:)), for: .valueChanged)
        stack.addArrangedSubview(picker)
        editorValueLabels.removeAll()
        for (index, name) in ["Horizontal", "Vertical", "Size"].enumerated() {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 6
            let label = UILabel()
            label.text = name
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 12)
            label.widthAnchor.constraint(equalToConstant: 67).isActive = true
            row.addArrangedSubview(label)
            let slider = UISlider()
            slider.minimumValue = index == 2 ? 10 : -100
            slider.maximumValue = index == 2 ? 110 : 100
            slider.tag = index
            slider.addTarget(self, action: #selector(editorSliderMoved(_:)), for: .valueChanged)
            row.addArrangedSubview(slider)
            let value = UILabel()
            value.textColor = .white
            value.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            value.textAlignment = .right
            value.widthAnchor.constraint(equalToConstant: 38).isActive = true
            row.addArrangedSubview(value)
            editorValueLabels.append(value)
            stack.addArrangedSubview(row)
            if index == 0 { editorX = slider }
            if index == 1 { editorY = slider }
            if index == 2 { editorSize = slider }
        }
        let buttons = UIStackView()
        buttons.axis = .horizontal
        buttons.distribution = .fillEqually
        buttons.spacing = 8
        for (name, action) in [("Reset", #selector(resetLayoutEditor)), ("Save", #selector(saveLayoutEditor)), ("Close", #selector(closeLayoutEditor))] {
            let button = UIButton(type: .system)
            button.setTitle(name, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = UIColor(white: 0.35, alpha: 1)
            button.layer.cornerRadius = 8
            button.addTarget(self, action: action, for: .touchUpInside)
            buttons.addArrangedSubview(button)
        }
        stack.addArrangedSubview(buttons)
        updateEditorSliders()
    }

    @objc private func editorChangedElement(_ sender: UISegmentedControl) {
        editorSelection = sender.selectedSegmentIndex
        updateEditorSliders()
    }

    private func updateEditorSliders() {
        let values = editorOffsets[editorSelection]
        for (i, slider) in [editorX, editorY, editorSize].enumerated() {
            slider.value = Float(values[i])
            editorValueLabels[i].text = String(Int(values[i].rounded()))
        }
    }

    @objc private func editorSliderMoved(_ sender: UISlider) {
        editorOffsets[editorSelection][sender.tag] = CGFloat(sender.value)
        applyEditorOffsets()
        // Do not reassign slider.value during tracking: UIKit must own the thumb.
        editorValueLabels[sender.tag].text = String(Int(sender.value.rounded()))
    }

    @objc private func saveLayoutEditor() {
        let saved = editorOffsets.map { $0.map { Double($0) } }
        UserDefaults.standard.set(saved, forKey: editorKey)
        closeLayoutEditor()
    }

    @objc private func resetLayoutEditor() {
        editorOffsets = [[0,0,67],[0,0,16],[0,0,20],[0,0,26]]
        applyEditorOffsets()
        updateEditorSliders()
    }

    @objc private func closeLayoutEditor() {
        editorPanel?.removeFromSuperview()
        editorPanel = nil
    }

    // Route editor touches to the actual control, even when the underlying
    // lockscreen uses pass-through hit testing for system notifications.
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let panel = editorPanel, !panel.isHidden, panel.alpha > 0.01 {
            let local = convert(point, to: panel)
            if panel.point(inside: local, with: event) {
                return panel.hitTest(local, with: event) ?? panel
            }
        }
        return super.hitTest(point, with: event)
    }

	override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // The editor must receive touches even when classic notifications are disabled.
        // Otherwise the passthrough area below swallows all editor controls.
        if let panel = editorPanel, !panel.isHidden {
            let panelPoint = convert(point, to: panel)
            if panel.point(inside: panelPoint, with: event) {
                return true
            }
        }
		if !useNotifications {
			let frame = CGRect(x: 0,
							   y: timeBarDisabled ? 0 : statusBarHeight + 95,
							   width: bounds.size.width,
							   height: bounds.size.height - (timeBarDisabled ? 95 : statusBarHeight + 190))
			if frame.contains(point) {
				return false
			}
		}

		return true
	}

	@objc func observePreferences() {
		let manager = SixLSManager.sharedInstance()
		statusBarBackground.isHidden = manager?.disableDateBar ?? false
		dateView.isHidden = manager?.disableDateBar ?? false
		lockView.isHidden = manager?.disableLockBar ?? false
		wallpaperGradient.isHidden = manager?.disableWallpaperShadow ?? false
		lockView.unlockSlider.text = manager?.unlockText
		dateView.timeFormatter.dateFormat = manager?.militaryTime ?? false ? "HH:mm" : "h:mm"
		timeBarDisabled = manager?.disableDateBar ?? false
		useChargingView = !(manager?.disableChargingView ?? false)
		useNotifications = !(manager?.disableClassicNotifications ?? false)
		reloadNotifications()
		updateChargingState()
	}

	@objc func updatePlayingState(_ notification: NSNotification) {
		if let notificationInfo = notification.userInfo {
			let info = [
				"artist": "Artist",
				"song": "Song Title",
				"album": "Album"
			]
			dateView.nowPlayingInfo = info
			dateView.isPlaying = true
			dateViewHeightConstraint?.constant = 133
			nowPlayingView.isHidden = false
			// nowPlayingView.artworkImageView.image = nil
		} else {
			dateView.isPlaying = false
			dateViewHeightConstraint?.constant = 105
			nowPlayingView.isHidden = true
		}
	}

	@objc func updateChargingState() {
		if useChargingView {
			chargingView.isHidden = UIDevice.current.batteryState != .charging
			chargingView.updateImage()
		} else {
			chargingView.isHidden = true
		}
	}
	@objc func dismiss() {
		UIView.animate(withDuration: 0.3, animations: {
			var dateFrame = self.dateView.frame
			var lockFrame = self.lockView.frame
			dateFrame.origin.y -= 100 + self.statusBarHeight
			lockFrame.origin.y += 100
			self.dateView.frame = dateFrame
			self.lockView.frame = lockFrame
		}, completion: { _ in
			self.lockView.unlockSlider.uiSlider.value = 0
			self.lockView.unlockSlider.glintyTextView.alpha = 1
			self.lockView.unlockSlider.glintyTextView.transform = CGAffineTransform(translationX: self.editorOffsets[2][0], y: self.editorOffsets[2][1])
			self.dateView.transform = .identity
		})
	}

	@objc func presentAnimated() {
		UIView.animate(withDuration: 0.3) {
			self.present()
		}
	}

	@objc func present() {
		self.alpha = 1
		dateView.transform = .identity
		lockView.unlockSlider.glintyTextView.transform = CGAffineTransform(translationX: editorOffsets[2][0], y: editorOffsets[2][1])
		lockView.unlockSlider.glintyTextView.alpha = 1
		var dateFrame = self.dateView.frame
		var lockFrame = self.lockView.frame
		dateFrame.origin.y = self.statusBarHeight
		lockFrame.origin.y = self.bounds.height - lockFrame.height
		self.dateView.frame = dateFrame
		self.lockView.frame = lockFrame
	}

	@objc func unlock() {
		SixLSManager.sharedInstance().unlock()
	}
}

extension LockScreenView {
	func reloadNotifications() {
		guard useNotifications else {
			notificationTableView.isHidden = true
			notificationAlertView.isHidden = true
			return
		}

		if notifications.count > 1 {
			notificationTableView.isHidden = false
			notificationAlertView.isHidden = true
			notificationTableView.reloadData()
		} else if notifications.count == 1 {
			notificationAlertView.request = notifications[0]
			notificationTableView.isHidden = true
			notificationAlertView.isHidden = false
			notificationTableView.reloadData()
		} else {
			notificationTableView.isHidden = true
			notificationAlertView.isHidden = true
		}
	}

	@objc func removeNotification(_ request: NCNotificationRequest) {
		if let index = notifications.firstIndex(of: request) {
			notifications.remove(at: index)
			reloadNotifications()
		}
	}
}

extension LockScreenView: LockBarViewDelegate {
	func sliderStopped(_ slider: UISlider) {
		if slider.value < 1 {
			UIView.animate(withDuration: 0.1) {
				slider.setValue(0, animated: true)
				self.lockView.unlockSlider.glintyTextView.alpha = 1
			self.lockView.unlockSlider.glintyTextView.transform = CGAffineTransform(translationX: self.editorOffsets[2][0], y: self.editorOffsets[2][1])
			self.dateView.transform = .identity
			}
		} else {
			dismiss()
			unlock()
		}
	}

	func sliderMoved(_ slider: UISlider) {
		let distance = max(0, lockView.unlockSlider.bounds.width - 100)
		let translation = CGFloat(slider.value) * distance
		lockView.unlockSlider.glintyTextView.transform = CGAffineTransform(translationX: translation + editorOffsets[2][0], y: editorOffsets[2][1])
		dateView.transform = CGAffineTransform(translationX: translation, y: 0)
		lockView.unlockSlider.glintyTextView.alpha = 1
	}

	func cameraTapped(_ gesture: UITapGestureRecognizer) {
		if gesture.state == .ended {
			UIView.animate(withDuration: 0.2, animations: {
				self.center = CGPoint(x: self.center.x, y: self.center.y - self.statusBarHeight)
			}, completion: { _ in
				UIView.animate(withDuration: 0.2) {
					self.center = CGPoint(x: self.center.x, y: self.center.y + self.statusBarHeight)
				}
			})
		}
	}

	func cameraDragged(_ gesture: UIPanGestureRecognizer) {
		var translatedPoint = gesture.translation(in: self)
		translatedPoint = CGPoint(x: self.center.x, y: self.center.y + translatedPoint.y)

		if !(translatedPoint.y > self.bounds.height / 2) {
			self.center = translatedPoint
		}

		gesture.setTranslation(.zero, in: self)

		if gesture.state == .ended || gesture.state == .cancelled { // todo: momentum
			let openCamera = !(self.center.y + self.bounds.height / 2 > self.bounds.height / 2 + 95)
			UIView.animate(withDuration: 0.4, animations: {
				self.center = CGPoint(x: self.center.x, y: openCamera ? -self.bounds.height / 2 : self.bounds.height / 2)
			}, completion: { _ in
				if openCamera {
					SixLSManager.sharedInstance().openCamera()
					self.center = CGPoint(x: self.center.x, y: self.bounds.height / 2)
				}
			})
		}
	}
}

extension LockScreenView: UITableViewDelegate, UITableViewDataSource {
	public func numberOfSections(in tableView: UITableView) -> Int {
		1
	}

	public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		UITableView.automaticDimension
	}

	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		notifications.count
	}

	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard notifications.count > indexPath.row else { return UITableViewCell() }

		let cell = NotificationCell(request: notifications[indexPath.row])
		return cell
	}
}
