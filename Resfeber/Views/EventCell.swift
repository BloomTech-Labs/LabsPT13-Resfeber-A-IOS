//
//  EventCell.swift
//  Resfeber
//
//  Created by David Wright on 12/14/20.
//  Copyright © 2020 Spencer Curtis. All rights reserved.
//

import UIKit
import CoreLocation

class EventCell: UICollectionViewCell {
    static let reuseIdentifier = "event-cell-reuse-identifier"

    var event: Event? {
        didSet {
            updateViews()
        }
    }

    fileprivate let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = .systemGray2
        iv.image = UIImage(named: "Backpack")
        iv.setDimensions(height: 50, width: 50)
        iv.layer.cornerRadius = 10
        return iv
    }()

    fileprivate let infoView: UIView = {
        let view = UIView()
        return view
    }()

    fileprivate let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        return label
    }()
    
    fileprivate let addressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        return label
    }()
    
    fileprivate let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureCell()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Helpers

private extension EventCell {
    func configureCell() {
        backgroundColor = .systemGray5
        layer.cornerRadius = 10
        clipsToBounds = true
        
        // Configure Image View
        addSubview(imageView)
        imageView.anchor(top: topAnchor, right: rightAnchor, paddingTop: 8, paddingRight: 8)

        // Configure Info View
        infoView.addSubview(nameLabel)
        nameLabel.anchor(top: infoView.topAnchor, left: infoView.leftAnchor, right: infoView.rightAnchor)
        
        infoView.addSubview(addressLabel)
        addressLabel.anchor(top: nameLabel.bottomAnchor, left: infoView.leftAnchor, right: infoView.rightAnchor, paddingTop: 1)
        
        infoView.addSubview(categoryLabel)
        categoryLabel.anchor(top: addressLabel.bottomAnchor, left: infoView.leftAnchor, right: infoView.rightAnchor, paddingTop: 1)
        
        addSubview(infoView)
        infoView.anchor(top: topAnchor,
                        left: leftAnchor,
                        bottom: bottomAnchor,
                        right: imageView.leftAnchor,
                        paddingTop: 8,
                        paddingLeft: 8,
                        paddingBottom: 8,
                        paddingRight: 4)
        
        layoutSubviews()
    }

    func updateViews() {
        if let event = event {
            imageView.contentMode = .scaleAspectFill
            nameLabel.text = event.name
            categoryLabel.text = event.category
            updateAddressLabel()
        } else {
            imageView.image = UIImage(named: "Backpack")
            imageView.contentMode = .scaleAspectFill
        }
    }
    
    func updateAddressLabel() {
        guard let event = event else { return }
        
        let location = CLLocation(latitude: event.latitude, longitude: event.longitude)
        
        location.fetchAddress { address in
            self.addressLabel.text = address
        }
    }
}
