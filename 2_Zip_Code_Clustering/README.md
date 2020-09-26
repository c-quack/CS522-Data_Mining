# US zip code clustering
The object of this assignment is to: 
* Find large cities based on the density of zip codes in an area.
* Plot to visualize the results.

To accomplish this I used DBSCAN (Density-based spatial clustering of applications with noise) in R. After importing the data and removing the non-contiguous states (Puerto Rico, Alaska, Hawaii), the first major decision is deciding on an EPS and k value. The EPS value defines the radius around the current point that the algorithm will consider. The k value is used to determine if the current point under consideration is a core point, boarder point, or noise point.

