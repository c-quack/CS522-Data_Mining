#####------------------------------------------------------------------------------------------------------#####
# Corey Quackenbush
# CS 522 - Data Mining
# 11/3/2020
#####------------------------------------------------------------------------------------------------------#####

# Load packages, set the working directory, and read in the data table.
library(ggplot2)
library(dbscan)
library(factoextra)
library(fiftystater)
setwd("/Users/crquack/Documents/Hood/Current Classes/CS 522 - Data Mining/Homework/8 zipcode clustering 2/")
zipcodes <- read.table("../2 US zipcode map/uszips.csv", header = T, sep = ",")

# Check if the state name is one of the non-contiguous states. Negate the output so we keep only the contiguous states.
# Use that vector to filter the original dataset.
# Droplevels gets rid of the factors we removed the values for.
zipcodes <- droplevels( zipcodes[!(zipcodes$state_name %in% c("Puerto Rico", "Alaska", "Hawaii")), ] )



#####----------------------------------------- DBSCAN clustering ------------------------------------------#####
# Create a new data frame that only contains the zipcode latitudes and longitudes
# Swap order of lat and lng so x=lng and y=lat when plotting
lat_lng <- zipcodes[ , c(3,2)]

# Find optimal EPS value
# EPS value too small: sparse clusters defined as noise
# EPS value too large: denser cluster may be merged together
kNNdistplot(lat_lng, k = 70)
abline(h = 0.25, lty = 2)

# DBSCAN: Density-based spatial clustering of applications with noise.
# View cluster output and create a plot title based on DBSCAN settings.
zip_clusters <- dbscan(lat_lng, eps = .25, minPts = 70)
zip_clusters

plotTitle <- paste("DBSCAN - EPS=", zip_clusters$eps," - k=", zip_clusters$minPts, sep = "")

##### Visualize DBSCAN results #####
# Scatter plot
fviz_cluster(zip_clusters, lat_lng, geom = "point", ellipse = F, outlier.pointsize = 0, outlier.shape = 3, shape = 16, stand = F) +
  labs(x = "Longitude", y = "Latitude", title = plotTitle) +
  scale_x_continuous(breaks = seq(-150, 0, 5))



#####----------------------------------- Clusted zipcodes on map of USA -----------------------------------#####
# fifty_states is a dataset from the package fiftystater. We'll use it to create the state outlines for plots.
# Remove Alaska and Hawaii from the data.
contiguous_states <- fifty_states
contiguous_states <- droplevels( contiguous_states[!(contiguous_states$id %in% c("alaska", "hawaii")), ] )

# Add clustering results back to the main dataset, remove noise points, and factor the numerical cluster groups.
clusted_zips <- cbind(zipcodes, cluster = zip_clusters$cluster)
clusted_zips <- clusted_zips[ clusted_zips$cluster>0, ]
clusted_zips$cluster <- factor(clusted_zips$cluster)

##### Plot - clustered zipcodes on US map #####
ggplot() + geom_polygon( data=contiguous_states, aes(x=long, y=lat, group = group),color="black", fill="grey" ) +
  geom_point(data = clusted_zips, aes(x=lng, y=lat, color = cluster)) +
  geom_point(data =clusted_zips, aes(x=lng, y=lat), shape = 1, color = "black", alpha = 0.05) +
  labs(x = "Longitude", y = "Latitude", title = plotTitle) +
  scale_x_continuous(breaks = seq(-150, 0, 5))



#####----------------------------- Top 20 US cities based on census estimate -----------------------------#####
# Import top city data and set the factor levels for "City" so that they display from highest population
# to lowest when ploted
top20 <- read.table("top20cities.csv", header = T, sep = ",")
top20$City <- factor(top20$City, levels = top20$City[order(top20$Population, decreasing = T)])

##### Top 20 US cities alone
ggplot() + geom_polygon( data=contiguous_states, aes(x=long, y=lat, group = group),color="black", fill="grey" ) +
  geom_point(data = top20, aes(x=lat, y=lng, color = City), size = 5) +
  labs(x = "Longitude", y = "Latitude", title = "Top 20 US Cities (census estimate)")

##### Overlay top 20 populated cities and top 20 clustered zipcodes
ggplot() + geom_polygon( data=contiguous_states, aes(x=long, y=lat, group = group),color="black", fill="grey" ) +
  geom_point(data = clusted_zips, aes(x=lng, y=lat, color = cluster)) +
  labs(x = "Longitude", y = "Latitude", title = "Top 20 cities (population) vs Top 20 DBSCAN clusters") +
  scale_x_continuous(breaks = seq(-150, 0, 5)) +
  geom_point(data = top20, aes(x=lat, y=lng), shape = 1, color = "black", size = 5, stroke = 1.5)



#####----------------------------------------- Kmeans Clustering -----------------------------------------#####
# Run kmeans clustering with equal to 20 and enforcing 100 iterations till convergence.
kmeanClusters <- kmeans(lat_lng, centers = 20, iter.max = 100)

# Merge clustering results back into original dataset.
kmeans_zips <- cbind(zipcodes, cluster = kmeanClusters$cluster)
kmeans_zips$cluster <- factor(kmeans_zips$cluster)

# Extract centers for plotting
centers <- as.data.frame(kmeanClusters$centers)

##### Overlay top 20 kmeans clusters on top of US map
ggplot() + geom_polygon( data=contiguous_states, aes(x=long, y=lat, group = group),color="black", fill="grey" ) +
  geom_point(data = kmeans_zips, aes(x=lng, y=lat, color = cluster)) +
  geom_point(data =kmeans_zips, aes(x=lng, y=lat), shape = 1, color = "black", alpha = 0.1) +
  geom_point(data = centers, aes(x=lng, y=lat), shape = 3, size = 3, stroke = 1) +
  labs(x = "Longitude", y = "Latitude", title = "Kmeans Clustering - k=20") +
  scale_x_continuous(breaks = seq(-150, 0, 5))





