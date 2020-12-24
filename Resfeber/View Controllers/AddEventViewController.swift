//
//  AddEventViewController.swift
//  Resfeber
//
//  Created by David Wright on 12/22/20.
//  Copyright © 2020 Spencer Curtis. All rights reserved.
//

import UIKit
import CoreData
import MapKit

protocol AddEventViewControllerDelegate: class {
    func didAddEvent(_ event: Event)
}

class AddEventViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: AddEventViewControllerDelegate?
    
    private let tripsController: TripsController
    private let trip: Trip
    
    private let mapView = MKMapView()
    private var selectedPlacemark: MKPlacemark?
    private var category: EventCategory?

    private var nameTextField: UITextField = {
        let tf = UITextField()
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.textColor = RFColor.red
        tf.tintColor = RFColor.red
        tf.textContentType = .name
        tf.placeholder = "Add an event name"
        tf.addTarget(self, action: #selector(textFieldValueChanged), for: .editingChanged)
        return tf
    }()
    
    lazy private var locationTextField: UITextField = {
        let tf = UITextField()
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.textColor = RFColor.red
        tf.tintColor = .clear
        tf.placeholder = "Add a location"
        tf.delegate = self
        tf.addTarget(self, action: #selector(locationTextFieldTapped), for: .editingDidBegin)
        return tf
    }()
    
    lazy private var categoryTextField: UITextField = {
        let tf = UITextField()
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.textColor = RFColor.red
        tf.tintColor = .clear
        tf.placeholder = "Select category"
        tf.delegate = self
        categoryPicker = tf.setInputViewCategoryPicker(target: self, selector: #selector(tapCategoryPickerDone))
        return tf
    }()
    
    lazy private var startDateTextField: UITextField = {
        let tf = UITextField()
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.textColor = RFColor.red
        tf.tintColor = .clear
        tf.placeholder = "Add a start date"
        tf.delegate = self
        startDatePicker = tf.setInputViewDatePicker(target: self, selector: #selector(tapStartDateDone))
        return tf
    }()
    
    lazy private var endDateTextField: UITextField = {
        let tf = UITextField()
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.textColor = RFColor.red
        tf.tintColor = .clear
        tf.placeholder = "Add an end date"
        tf.delegate = self
        endDatePicker = tf.setInputViewDatePicker(target: self, selector: #selector(tapEndDateDone))
        return tf
    }()
    
    lazy private var notesTextView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.textColor = RFColor.red
        tv.tintColor = RFColor.red
        tv.delegate = self
        return tv
    }()
    
    lazy private var notesPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.font = notesTextView.font
        label.textColor = UIColor.placeholderText
        label.text = "Add notes"
        return label
    }()
        
    private lazy var eventInputStackView: UIStackView = {
        let inputRowTitleLabelWidth: CGFloat = 88
        
        let stack = UIStackView(arrangedSubviews: [
            RFInputRow(rowTitle: "Event Name",
                       titleLabelWidth: inputRowTitleLabelWidth,
                       inputView: nameTextField,
                       borderStyle: .top),
            RFInputRow(rowTitle: "Location",
                       titleLabelWidth: inputRowTitleLabelWidth,
                       inputView: locationTextField,
                       borderStyle: .top),
            RFInputRow.spacer(borderStyle: .top),
            RFInputRow(rowTitle: "Category",
                       titleLabelWidth: inputRowTitleLabelWidth,
                       inputView: categoryTextField,
                       borderStyle: .top),
            RFInputRow.spacer(borderStyle: .top),
            RFInputRow(rowTitle: "Start Date",
                       titleLabelWidth: inputRowTitleLabelWidth,
                       inputView: startDateTextField,
                       borderStyle: .top),
            RFInputRow(rowTitle: "End Date",
                       titleLabelWidth: inputRowTitleLabelWidth,
                       inputView: endDateTextField,
                       borderStyle: .top),
            RFInputRow.spacer(borderStyle: .top),
            RFInputRow(rowTitle: "Notes",
                       titleLabelWidth: inputRowTitleLabelWidth,
                       inputTextView: notesTextView,
                       placeholderLabel: notesPlaceholderLabel,
                       height: 150,
                       borderStyle: .topAndBottom)
        ])
        
        stack.axis = .vertical
        stack.spacing = 0
        return stack
    }()
    
    private var categoryPicker = UIPickerView()
    private var startDatePicker = UIDatePicker()
    private var endDatePicker = UIDatePicker()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    // MARK: - Lifecycle
    
    init(trip: Trip, tripsController: TripsController) {
        self.trip = trip
        self.tripsController = tripsController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    // MARK: - Helpers
    
    private func configureViews() {
        view.backgroundColor = RFColor.background
        
        // Configure Navigation Bar
        navigationController?.navigationBar.tintColor = RFColor.red
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(addNewEventWasCancelled))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .done, target: self, action: #selector(newEventWasSaved))
        navigationItem.rightBarButtonItem?.isEnabled = false
        title = "New Event"
        
        // Configure MapView
        mapView.layer.borderWidth = 1
        mapView.layer.borderColor = RFColor.red.cgColor
        view.addSubview(mapView)
        mapView.anchor(top: view.safeAreaLayoutGuide.topAnchor,
                       left: view.leftAnchor,
                       right: view.rightAnchor,
                       paddingTop: 4,
                       paddingLeft: 12,
                       paddingRight: 12,
                       height: view.frame.width * 0.8)
        
        // Configure Event Info StackView
        view.addSubview(eventInputStackView)
        eventInputStackView.anchor(top: mapView.bottomAnchor,
                                 left: view.leftAnchor,
                                 right: view.rightAnchor,
                                 paddingTop: 16)
        
        nameTextField.becomeFirstResponder()
    }

    private func separatorView() -> UIView {
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor.systemGray.withAlphaComponent(0.3)
        separatorView.setDimensions(height: 1, width: view.frame.width)
        return separatorView
    }

    private func spacer(height: CGFloat? = nil, width: CGFloat? = nil) -> UIView {
        let spacerView = UIView()

        if let width = width {
            spacerView.setDimensions(width: width)
        }

        if let width = width {
            spacerView.setDimensions(width: width)
        }
        return spacerView
    }
    
    // MARK: - Selectors
    
    @objc private func textFieldValueChanged() {
        navigationItem.rightBarButtonItem?.isEnabled = !(nameTextField.text?.isEmpty ?? true)
    }
    
    @objc private func tapCategoryPickerDone() {
        let selectedRow = categoryPicker.selectedRow(inComponent: 0)
        category = EventCategory(rawValue: selectedRow)
        categoryTextField.text = category?.displayName
        self.categoryTextField.resignFirstResponder()
    }
    
    @objc func tapStartDateDone() {
        if let datePicker = self.startDateTextField.inputView as? UIDatePicker {
            self.startDateTextField.text = dateFormatter.string(from: datePicker.date)
            
            if endDateTextField.text == nil || endDateTextField.text == "" {
                endDatePicker.date = datePicker.date
            }
        }
        self.startDateTextField.resignFirstResponder()
    }

    @objc func tapEndDateDone() {
        if let datePicker = self.endDateTextField.inputView as? UIDatePicker {
            self.endDateTextField.text = dateFormatter.string(from: datePicker.date)
            
            if startDateTextField.text == nil || startDateTextField.text == "" {
                startDatePicker.date = datePicker.date
            }
        }
        self.endDateTextField.resignFirstResponder()
    }
    
    @objc func locationTextFieldTapped() {
        let locationSearchVC = LocationSearchViewController()
        locationSearchVC.delegate = self
        
        if let region = trip.eventsCoordinateRegion {
            locationSearchVC.searchRegion = region
        }
        
        present(locationSearchVC, animated: true, completion: nil)
    }
    
    @objc func addNewEventWasCancelled() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func newEventWasSaved() {
        guard let placemark = selectedPlacemark else { return }
        guard let name = nameTextField.text ?? placemark.name,
              let latitude = placemark.location?.coordinate.latitude,
              let longitude = placemark.location?.coordinate.longitude else { return }
        
        let address = placemark.address
        
        var startDate: Date?
        if let startDateString = startDateTextField.text {
            startDate = dateFormatter.date(from: startDateString)
        }
        
        var endDate: Date?
        if let endDateString = endDateTextField.text {
            endDate = dateFormatter.date(from: endDateString)
        }
        
        let notes = notesTextView.text
        
        let event = tripsController.addEvent(name: name,
                                             eventDescription: nil,
                                             category: category,
                                             latitude: latitude,
                                             longitude: longitude,
                                             address: address,
                                             startDate: startDate,
                                             endDate: endDate,
                                             notes: notes,
                                             trip: trip)
        
        delegate?.didAddEvent(event)
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Location Search ViewController Delegate

extension AddEventViewController: LocationSearchViewControllerDelegate {
    func didSelectLocation(with placemark: MKPlacemark) {
        self.selectedPlacemark = placemark
        updateLocationDescription(with: placemark)
        dropPinAndZoomIn(placemark: placemark)
    }
    
    private func updateLocationDescription(with placemark: MKPlacemark) {
        mapView.removeAnnotations(mapView.annotations)
        
        locationTextField.text = placemark.name
    }
    
    private func dropPinAndZoomIn(placemark: MKPlacemark) {
        mapView.removeAnnotations(mapView.annotations)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        
        if let address = placemark.address {
            annotation.subtitle = address
        }
        
        mapView.addAnnotation(annotation)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
}

// MARK: - UIPickerView Data Source

extension AddEventViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        EventCategory.displayNames.count
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let categoryName = EventCategory.displayNames[row] ?? "- Select Category -"
        let textColor = EventCategory.displayNames[row] == nil ? UIColor.placeholderText : UIColor.label
        let attributes = [NSAttributedString.Key.foregroundColor : textColor]
        return NSAttributedString(string: categoryName, attributes: attributes)
    }
}

// MARK: - UITextField Delegate

extension AddEventViewController: UITextFieldDelegate {
    /// Only allow the user to manually edit text in textFields that do not have a custom input view set
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        textField.inputView == nil
    }
}

// MARK: - UITextView Delegate

extension AddEventViewController: UITextViewDelegate {
    /// Show "placeholder" label when the text view is empty
    func textViewDidChange(_ textView: UITextView) {
        notesPlaceholderLabel.isHidden = !textView.text.isEmpty
    }
}
