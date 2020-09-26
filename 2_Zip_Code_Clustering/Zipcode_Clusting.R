# Load packages, set the working directory, and read in the data table.
library(ggplot2)
library(dbscan)
library(factoextra)
setwd("/Users/crquack/Documents/Hood/Current Classes/CS 522 - Data Mining/Homework/5  zipcode clustering/")
zipcodes <- read.table("../2 US zipcode map/uszips.csv", header = T, sep = ",")

# Check if the state name is one of the non-contiguous states. Negate the output so we keep only the contiguous states.
# Use that vector to filter the original dataset.
# Droplevels gets rid of the factors we removed the values for.
zipcodes <- droplevels( zipcodes[!(zipcodes$state_name %in% c("Puerto Rico", "Alaska", "Hawaii")), ] )

# Create a new data frame that only contains the zipcode latitudes and longitudes
# Swap order of lat and lng so x=lng and y=lat when plotting
lat_lng <- zipcodes[ , c(3,2)]

# Find optimal EPS value
# EPS value too small: sparse clusters defined as noise
# EPS value too large: denser cluster may be merged together
kNNdistplot(lat_lng, k = 60)
abline(h = 0.24, lty = 2)

# DBSCAN: Density-based spatial clustering of applications with noise 
zip_clusters <- dbscan(lat_lng, eps = .24, minPts = 60, borderPoints = F)

# Visualize the results
fviz_cluster(zip_clusters, lat_lng, geom = "point", ellipse = F, outlier.pointsize = 0, outlier.shape = 3, shape = 16, stand = F) +
  labs(x = "Longitude", y = "Latitude", title = "DBSCAN - EPS=0.24 - k=60") +
  scale_x_continuous(breaks = seq(-150, 0, 5)) +
  theme(legend.position = "none")
