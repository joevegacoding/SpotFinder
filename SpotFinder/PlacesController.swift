//
//  PlacesController.swift
//  SpotFinder
//
//  Created by Joseph Bouhanef on 2021-06-10.
//

import Foundation
import UIKit
import LBTATools
import MapKit
import GooglePlaces
import JGProgressHUD

class PlacesControler: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    

    
    let mapView = MKMapView()
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(mapView)
        mapView.delegate = self
        mapView.fillSuperview()
        mapView.showsUserLocation = true
        locationManager.delegate = self
        
        requestForLocationAuthorization()
      
    }
    
    let hudNameLabel = UILabel(text: "Name", font: UIFont(name: "AvenirNext-Bold", size: 18), textColor: .label, textAlignment: .left, numberOfLines: 0)
    let hudAddressLabel = UILabel(text: "Address", font: UIFont(name: "AvenirNext-DemiBold", size: 16), textColor: .label, textAlignment: .left, numberOfLines: 0)
    let hudTypesLabel = UILabel(text: "Types", font: UIFont(name: "Avenir-Light", size: 16), textColor: .label, textAlignment: .left, numberOfLines: 0)
    lazy var infoButton = UIButton(type: .infoDark)
    let hudContainer = UIView(backgroundColor: .systemBackground)
    
    
    
    fileprivate func setupAnnotationHud() {
        
        infoButton.addTarget(self, action: #selector(handleInformation), for: .touchUpInside)
        view.addSubview(hudContainer)
        hudContainer.layer.cornerRadius = 15
        hudContainer.setupShadow(opacity: 0.5, radius: 8, offset: .zero, color: .darkGray)
        hudContainer.anchor(top: nil, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor, padding: .allSides(16), size: .init(width: 0, height: 160))
        
        let topRow = UIView()
        topRow.hstack(hudNameLabel, infoButton.withWidth(70))
        infoButton.tintColor = .systemPurple
        hudContainer.hstack(hudContainer.stack(topRow, hudAddressLabel, hudTypesLabel, spacing: 8), alignment: .center).withMargins(.allSides(16))
    }
    
    @objc fileprivate func handleInformation() {
        guard let placeAnnotation = mapView.selectedAnnotations.first as? PlaceAnnotation else { return }
        
        
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Loading Photos..."
        hud.show(in: view)
        
        //We need to access and view all the photos available
        guard let placeId = placeAnnotation.place.placeID else { return }
        client.lookUpPhotos(forPlaceID: placeId) { [weak self] list, error in
            if let error = error {
                print("Failed to fetch photos from API", error)
                hud.dismiss(animated: true)
                return
            }
            
            let dispatchGroup = DispatchGroup()
         
            var images = [UIImage]()
            
          
            
            list?.results.forEach({ photoMetadata in
                dispatchGroup.enter()
                self?.client.loadPlacePhoto(photoMetadata) { image, error in
                    if let error = error {
                       
                        print("Failed to fetch photos from API", error)
                        hud.dismiss(animated: true)
                        return
                    }
                    dispatchGroup.leave()
                    guard let image = image else { return }
                    images.append(image)
                }
            })
            //introduce some mechanism to wait to fetch. Asynchronous.
            dispatchGroup.notify(queue: .main) {
                hud.dismiss(animated: true)
                let photosController = PlacePhotosController(scrollDirection: .horizontal)
                photosController.items = images
                 //render out images in this controller
                photosController.view.backgroundColor = .systemRed
                self?.present(UINavigationController(rootViewController: photosController), animated: true)

                
            }
        }
    }
    
    
    let client = GMSPlacesClient()
    fileprivate func findNearbyPlaces() {
        client.currentPlace { [weak self] likelihoodList, error in
            if let error = error {
                
                print("failed to find nearby places", error)
            }
            
            likelihoodList?.likelihoods.forEach({  likeligood in
                print(likeligood.place.name ?? "")
                
                let place = likeligood.place
                
                let annotation = PlaceAnnotation(place: place)
                annotation.title = place.name
                annotation.coordinate = place.coordinate
                
                self?.mapView.addAnnotation(annotation)
                
            })
            
            self?.mapView.showAnnotations(self?.mapView.annotations ?? [], animated: true)
        }
    }
    
   
    class PlaceAnnotation: MKPointAnnotation {
        let place: GMSPlace
        init(place: GMSPlace) {
            self.place = place
        }
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //When we change the annotations into pins, even the user's location becomes a pin. This code below brings back the blue dot originally implemented with MKPointAnnotation
        if !(annotation is PlaceAnnotation) { return nil }
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "annotationId")
        
        if let placeAnnotation = annotation as? PlaceAnnotation {
            
            let types = placeAnnotation.place.types
            if let firstType = types?.first {
                if firstType == "cafe" {
                    annotationView.image = #imageLiteral(resourceName: "pin_app")
                } else {
                    annotationView.image = #imageLiteral(resourceName: "annotationPink")
                }
            }
//            print(placeAnnotation.place.types )

//            annotationView.image = #imageLiteral(resourceName: "annotationPink")
        }
        return annotationView
        
    }
    
    var currentCustomCallout: UIView?
    

    fileprivate func requestForLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    fileprivate func setupHud(view: MKAnnotationView) {
        guard let annotation = view.annotation as? PlaceAnnotation else { return }
        
        let place = annotation.place
        hudNameLabel.text = place.name
        hudAddressLabel.text = place.formattedAddress
        let hudTypes = place.types?.joined(separator: ", ")
        hudTypesLabel.text = hudTypes?.replacingOccurrences(of: "_", with: " ")
    }
    
  
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        setupAnnotationHud()
        setupHud(view: view)
        UIView.transition(with: self.view, duration: 0.4, options: [.transitionCrossDissolve], animations: {
            self.currentCustomCallout?.removeFromSuperview()
        }, completion: nil)
        
        let customCalloutContainer = CalloutCntainer()
        
        UIView.transition(with: self.view, duration: 0.4, options: [.transitionCrossDissolve], animations: {
            view.addSubview(customCalloutContainer)
        }, completion: nil)
        
        let widthAnchor = customCalloutContainer.widthAnchor.constraint(equalToConstant: 200)
        widthAnchor.isActive = true
        let heightAnchor = customCalloutContainer.heightAnchor.constraint(equalToConstant: 120)
        heightAnchor.isActive = true
        customCalloutContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        customCalloutContainer.bottomAnchor.constraint(equalTo: view.topAnchor).isActive = true
        
        currentCustomCallout = customCalloutContainer
            
        guard let firstPhotoMetadata = (view.annotation as? PlaceAnnotation)?.place.photos?.first else { return }

            self.client.loadPlacePhoto(firstPhotoMetadata) { [weak self] image, error in
                if let error = error {
                    print("Could not load place photos", error)
                }
                guard let image = image else { return }
                guard let setupCalloutImageSize = self?.setupCalloutImageSize(image: image) else { return }
                widthAnchor.constant = setupCalloutImageSize.width
                heightAnchor.constant = setupCalloutImageSize.height
                
                
                customCalloutContainer.imageView.image = image
                customCalloutContainer.nameLabel.text = (view.annotation as? PlaceAnnotation)?.place.name
            }
    }
    
    fileprivate func setupCalloutImageSize(image: UIImage) -> CGSize {
        
        if image.size.width > image.size.height {
            //width1/heigh1 = width2/height2
            let newWidth: CGFloat = 300
            let newHeight = (newWidth * image.size.height) / image.size.width
            return .init(width: newWidth, height: newHeight)

        } else {
            let newHeight: CGFloat = 200
            let newWidth = (newHeight * image.size.width) / image.size.height
            return .init(width: newWidth, height: newHeight)
        }
        
    }
    //To read doc because deprecated.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let first = locations.first else { return }
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        
        let region = MKCoordinateRegion(center: first.coordinate, span: span)
        mapView.setRegion(region, animated: false)
        
        findNearbyPlaces()
    }
}
