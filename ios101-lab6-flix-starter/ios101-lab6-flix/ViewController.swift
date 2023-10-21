//
//  ViewController.swift
//  ios101-lab6-flix
//

import UIKit
import Nuke

// Conform to UITableViewDataSource
class ViewController: UIViewController, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("🍏 numberOfRowsInSection called with movies count: \(movies.count)")
        return movies.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("🍏 cellForRowAt called for row: \(indexPath.row)")

        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell

        let movie = movies[indexPath.row]

        if let posterPath = movie.posterPath,

            // Create a url by appending the poster path to the base url. https://developers.themoviedb.org/3/getting-started/images
           let imageUrl = URL(string: "https://image.tmdb.org/t/p/w500" + posterPath) {
            Nuke.loadImage(with: imageUrl, into: cell.posterImageView)
        }

        cell.titleLabel.text = movie.title
        cell.overviewLabel.text = movie.overview

        return cell
    }

    @IBOutlet weak var tableView: UITableView!

    private var movies: [Movie] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        fetchMovies()
        
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    // Unselect the row when returning from the DetailViewController
    override func viewWillAppear(_ animated: Bool) {
        /// It is customary to call the overridden method on `super` any time you override a method
        super.viewWillAppear(animated)
        
        /// Get the indexPath for the selected row
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            
            // Deselect the currently selected row
            tableView.deselectRow(at: selectedIndexPath, animated: animated)
        }
    }
    
    /// The `prepare(for:sender:)` function will allow us to pass data from the row of the TableView to the DetailViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // MARK: - Pass the selected movie data to the DetailViewController
        
        /// Get the index path for the selected row.
        /// `indexPathForSelectedRow` returns an optional `indexPath`, so we'll unwrap it with a guard.
        guard let selectedIndexPath = tableView.indexPathForSelectedRow else { return }
        
        /// Get the selected movie from the movies array using the selected indexPath's row
        let selectedMovie = movies[selectedIndexPath.row]
        
        /// Get access to the DetailViewController via the seguie's destination. (guard to unwrap the optional)
        guard let detailViewController = segue.destination as? DetailViewController else { return }
        
        /// Lastly, set the movie variable in the DetailViewController to the selected movie from the TableView
        detailViewController.movie = selectedMovie
    }

    // Fetches a list of popular movies from the TMDB API
    private func fetchMovies() {

        // URL for the TMDB Get Popular movies endpoint: https://developers.themoviedb.org/3/movies/get-popular-movies
        let url = URL(string: "https://api.themoviedb.org/3/movie/popular?api_key=b1446bbf3b4c705c6d35e7c67f59c413&language=en-US&page=1")!

        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)

        // ---
        // Create the URL Session to execute a network request given the above url in order to fetch our movie data.
        // https://developer.apple.com/documentation/foundation/url_loading_system/fetching_website_data_into_memory
        // ---
        let session = URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                print("🚨 Request failed: \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("🚨 Server Error: response: \(String(describing: response))")
                return
            }

            // Check for data
            guard let data = data else {
                print("🚨 No data returned from request")
                return
            }

            // The JSONDecoder's decode function can throw an error. To handle any errors we can wrap it in a `do catch` block.
            do {
                // MARK: - jSONDecoder with custom date formatter
                let decoder = JSONDecoder()

                // Create a date formatter object
                let dateFormatter = DateFormatter()

                // Set the date formatter date format to match the the format of the date string we're trying to parse
                dateFormatter.dateFormat = "yyyy-MM-dd"

                // Tell the json decoder to use the custom date formatter when decoding dates
                decoder.dateDecodingStrategy = .formatted(dateFormatter)

                // Decode the JSON data into our custom `MovieFeed` model.
                let movieResponse = try decoder.decode(MovieFeed.self, from: data)

                // Access the array of movies
                let movies = movieResponse.results

                // Run any code that will update UI on the main thread.
                DispatchQueue.main.async { [weak self] in

                    // We have movies! Do something with them!
                    print("✅ SUCCESS!!! Fetched \(movies.count) movies")

                    // Iterate over all movies and print out their details.
                    for (index, movie) in movies.enumerated() {
                        print("🍿 MOVIE \(index) ------------------")
                        print("Title: \(movie.title)")
                        print("Overview: \(movie.overview)")
                    }

                    // Update the movies property so we can access movie data anywhere in the view controller.
                    self?.movies = movies
                    print("🍏 Fetched and stored \(movies.count) movies")

                    // Prompt the table view to reload its data (i.e. call the data source methods again and re-render contents)
                    self?.tableView.reloadData()
                }
            } catch {
                print("🚨 Error decoding JSON data into Movie Response: \(error.localizedDescription)")
                return
            }
        }

        // Don't forget to run the session!
        session.resume()
    }
}
