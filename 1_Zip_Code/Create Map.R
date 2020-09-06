# Load plotting library, set the working directory, and read in the data table.
library(ggplot2)
setwd("/Users/crquack/Documents/Hood/Current Classes/CS 522 - Data Mining/Homework/2 US zipcode map/")
zipcodes <- read.table("uszips.csv", header = T, sep = ",")

# Take a look at the states included
summary(zipcodes$state_name)
unique(zipcodes$state_name)

# Check if the state name is one of the non-contiguous states. Negate the output so we keep only the contiguous states.
# Use that vector to filter the original dataset.
# Droplevels gets rid of the factors we removed the values for.
contig_zipcodes <- droplevels( zipcodes[!(zipcodes$state_name %in% c("Puerto Rico", "Alaska", "Hawaii")), ] )

# Create the plot!
# Plot twice to get black border around circle. Adjust the alpha so points are opaque.
# Tweak the axis to get nicer breaks, label the axis, and remove the ledgend.
ggplot(data = contig_zipcodes, mapping = aes(x=lng, y=lat)) +
  geom_point(aes(color = state_name), alpha = 0.6) +
  geom_point(shape = 1, color = "black", alpha = 0.1) +
  scale_x_continuous(breaks = seq(-150, 0, 10)) +
  labs(x = "Longitude", y = "Latitude", title = "USA zip code in GCS space") +
  theme(legend.position = "none")
