//
//  HolesCollectionViewController.swift
//  Swingify
//
//  Created by Oskar Hosken on 22/5/2024.
//

import UIKit
import MapKit

class HolesCollectionViewController: UICollectionViewController {
    
    let VIEW_HOLE = "holeView"
    
    weak var selectedCourse: Course?
    
    var courseHoles: [HoleData] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
//        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "holeView")

        // Do any additional setup after loading the view.
        collectionView.setCollectionViewLayout(UICollectionViewCompositionalLayout(section: createTiledLayoutSection()), animated: false)
        
        
        navigationItem.title = "Loading Holes..."
        
        // API CALL
        guard let selectedCourse else {
            print("No Course Selected.")
            return
        }
        // ID to make the API call with
        let request_id = selectedCourse.id
        guard let requestURL = URL(string: "https://swingify.s3.ap-southeast-2.amazonaws.com/course_\(request_id).json") else {
            print("URL not valid")
            return
        }
        // Previous data was cached, this fixes that
        var request = URLRequest(url: requestURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw HoleListError.invalidServerResponse
                }
                
                let decoder = JSONDecoder()
                let courseData = try decoder.decode(CourseData.self, from: data)
                
                navigationItem.title = courseData.name
                
                courseHoles = courseData.holes!
                collectionView.reloadData()
            }
            catch {
                print(error)
            }
        }
    }
    
    
    func createHeaderLayout() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))
        let headerLayout = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        return headerLayout
    }
    
    func createTiledLayoutSection() -> NSCollectionLayoutSection {
        // Tiled layout.
        //  * Group is three posters, side-by-side.
        //  * Group is 1 x screen width, and height is 1/2 x screen width (poster height)
        //  * Poster width is 1/3 x group width, with height as 1 x group width
        //  * This makes item dimensions 2:3
        //  * contentInsets puts a 1 pixel margin around each poster.
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/3), heightDimension: .fractionalHeight(1))
        let itemLayout = NSCollectionLayoutItem(layoutSize: itemSize)
        itemLayout.contentInsets = NSDirectionalEdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(1/2))
        let layoutGroup = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [itemLayout])
        
        let layoutSection = NSCollectionLayoutSection(group: layoutGroup)
        layoutSection.boundarySupplementaryItems = [createHeaderLayout()]
//        layoutSection.orthogonalScrollingBehavior = .continuous
        return layoutSection
    }
    
    // Function to compute distance between two CLLocationCoordinate2D points
    func distanceBetweenPoints(first: CLLocationCoordinate2D, second: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: first.latitude, longitude: first.longitude)
        let location2 = CLLocation(latitude: second.latitude, longitude: second.longitude)
        return location1.distance(from: location2)
    }
    
    // Function that gets the hole's distance (tee to green)
    func calcHoleDistance(hole: HoleData) -> Int {
        // Getting tee and green locations
        let tee = CLLocationCoordinate2D(latitude: hole.tee_lat, longitude: hole.tee_lng)
        let green = CLLocationCoordinate2D(latitude: hole.green_lat, longitude: hole.green_lng)
        
        // Using our distance function to get the distance
        let distance = distanceBetweenPoints(first: tee, second: green)
        
        return Int(distance)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return courseHoles.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "holeView", for: indexPath) as! HoleCollectionViewCell
        
        let hole = courseHoles[indexPath.row]
        
        // Getting the distance, number and par of the hole
        let distance = calcHoleDistance(hole: hole)
        let number = hole.num
        let par = hole.par
    
        // Configure the cell
        cell.titleLabel.text = "Hole \(number)"
        cell.parLabel.text = String(par)
        cell.distanceLabel.text = String(distance)
        
        cell.backgroundColor = .lightGray
        cell.layer.cornerRadius = 0.5
    
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "goToHoleSegue", sender: indexPath)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToHoleSegue" {
            let destinationVC = segue.destination as! MapViewController
            if let indexPath = sender as? IndexPath {
                let selectedHole = courseHoles[indexPath.row]
                destinationVC.selectedHole = selectedHole
            }
        }
    }

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
