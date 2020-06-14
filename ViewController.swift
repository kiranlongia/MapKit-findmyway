
import UIKit
import MapKit

class ViewController: UIViewController , CLLocationManagerDelegate {
    
  
    @IBOutlet weak var directionBtn: UIButton!
    var locationManager = CLLocationManager()
       let places = Place.getPlaces()
     var destination: CLLocationCoordinate2D!
   // var showZoomControls : Bool { get set }

    @IBOutlet weak var map: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        map.delegate = self
        

       
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
 
       let latitude: CLLocationDegrees = 43.64
        let longitude: CLLocationDegrees = -79.38
        

        
        // long press gesture
        let uilpgr = UILongPressGestureRecognizer(target: self, action: #selector(addlongPressAnnotation))
        map.addGestureRecognizer(uilpgr)
        //add pinchto zoom gesture
                      let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(sender:)))
                           view.addGestureRecognizer(pinch)
    
        addDoubleTap()
        addPolyline()
       
    }
    
   
    @objc func addlongPressAnnotation(gestureRecognizer: UIGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: map)
        let coordinate = map.convert(touchPoint, toCoordinateFrom: map)
        
       
        let annotation = MKPointAnnotation()
        annotation.title = "Destination"
        annotation.coordinate = coordinate
        map.addAnnotation(annotation)
    }
    
    
  
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation = locations[0]
        
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        
        displayLocation(latitude: latitude, longitude: longitude, title: "Your Location", subtitle: "You are here")
        
        
        
    }
    
   
    func displayLocation(latitude: CLLocationDegrees, longitude: CLLocationDegrees, title: String, subtitle: String) {
       
        let latDelta: CLLocationDegrees = 0.05
        let lngDelta: CLLocationDegrees = 0.05
        
      
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: location, span: span)
        
       
        map.setRegion(region, animated: true)
       
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin))
        doubleTap.numberOfTapsRequired = 2
        map.addGestureRecognizer(doubleTap)
    }
    
    func addPolyline() {
        let coordinates = places.map {$0.coordinate}
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        map.addOverlay(polyline)
    }
    
    @IBAction func drawDirBtn(_ sender: UIButton) {
        
                
                let sourcePlaceMark = MKPlacemark(coordinate: locationManager.location!.coordinate)
                let destinationPlaceMark = MKPlacemark(coordinate: destination)
                
              
                let directionRequest = MKDirections.Request()
             
                directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
                directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
                
               
                directionRequest.transportType = .automobile
                
             
                let directions = MKDirections(request: directionRequest)
                directions.calculate { (response, error) in
                    guard let directionResponse = response else {return}
                    // create route
                    let route = directionResponse.routes[0]
                    // draw the polyline
                    self.map.addOverlay(route.polyline, level: .aboveRoads)
                   
                    let rect = route.polyline.boundingMapRect
       
                self.map.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: true)
                }
    }
    @objc func handlePinch(sender: UIPinchGestureRecognizer) {
                guard sender.view != nil else { return }
                
                if sender.state == .began || sender.state == .changed {
                    sender.view?.transform = (sender.view?.transform.scaledBy(x: sender.scale, y: sender.scale))!
                    sender.scale = 1.0
                }
      
              
          }
      
    
    @IBAction func zoomIn(_ sender: Any) {
       let span = MKCoordinateSpan(latitudeDelta: map.region.span.latitudeDelta*2, longitudeDelta: map.region.span.longitudeDelta*2)
       let region = MKCoordinateRegion(center: map.region.center, span: span)

       map.setRegion(region, animated: true)
    }
    
    
    @IBAction func zoomOut(_ sender: Any) {
        let span = MKCoordinateSpan(latitudeDelta: map.region.span.latitudeDelta/2, longitudeDelta: map.region.span.longitudeDelta/2)
        let region = MKCoordinateRegion(center: map.region.center, span: span)

        map.setRegion(region, animated: true)
        
        
    }
    
    
   
    
    @objc func dropPin(sender: UITapGestureRecognizer) {
        removePin()
        
        let touchPoint = sender.location(in: map)
        let coordinate = map.convert(touchPoint, toCoordinateFrom: map)
        let annotation = MKPointAnnotation()
        annotation.title = "Destination"
        annotation.coordinate = coordinate
        map.addAnnotation(annotation)
        
         destination = coordinate
    }
    
    func removePin() {
        for annotation in map.annotations {
            map.removeAnnotation(annotation)
        }
//        map.removeAnnotations(map.annotations)
    }
}

extension ViewController: MKMapViewDelegate {
   
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }

        
        let pinAnnotation = map.dequeueReusableAnnotationView(withIdentifier: "droppablePin") ?? MKPinAnnotationView()
        pinAnnotation.image = UIImage(named: "ic_place_2x.png" )
        pinAnnotation.canShowCallout = true
        pinAnnotation.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        return pinAnnotation
    }
    
   
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let alertController = UIAlertController(title: "Your Place", message: "You have reached your location", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
         if overlay is MKPolyline {
             let rendrer = MKPolylineRenderer(overlay: overlay)
             rendrer.strokeColor = UIColor.orange
             rendrer.lineWidth = 4
             return rendrer
         }
         return MKOverlayRenderer()
     }
}
