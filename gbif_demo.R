##rgbif demo
library(rgbif)
#retrieving a machine readable key for gbif
key<-name_backbone(name="Pinus sylvestris")$usageKey

#if naming issues are likely: get the accepted name first from taxize: POW, 
library(taxize)
ppow<-get_pow("Pinus sylvestris", accepted = TRUE, rows = 1, messages=FALSE)
ppow_data<-pow_lookup(ppow[1])
key<-name_backbone(name=paste(ppow_data$meta$name))$usageKey

#retrieve data from gbif, for all options see: https://www.rdocumentation.org/packages/rgbif/versions/3.4.0/topics/occ_search 
occ<-occ_search(taxonKey=key, country = "SE", year="1000,2021", fields="all", hasCoordinate = T, hasGeospatialIssue = F,limit=100)

#access the data
names(occ$data)
occ$data$country
occ$data$year

#download a study-extent, here: Sweden/Norrbotten
library(raster)
ext <- getData('GADM', country='SWE', level=1)
ext1<-subset(ext, ext$NAME_1=="Norrbotten")
occ<-occ_search(taxonKey=key, geometry=c(bbox(ext1)), year="1000,2021", fields="all", hasCoordinate = T, hasGeospatialIssue = F,limit=100)

#read the data
occ$data

#e.g. year of observation
occ$data$year

#bases of record
occ$data$basisOfRecord

#and other
names(occ$data)


#plot the data in space:
occ_points <- data.frame(x=occ$data$decimalLongitude,y=occ$data$decimalLatitude)
#convert to spatial points
occ_points <- SpatialPoints(occ_points, proj4string=CRS("+proj=longlat +datum=WGS84"))
#or spatial points dataframe
occ_points <- SpatialPointsDataFrame(occ_points, occ$data, proj4string=CRS("+proj=longlat +datum=WGS84"))

#plot the extent and all retrieved data
plot(ext1)
plot(occ_points, add=T)

#remove points outside the original polygon
ext1 <- spTransform(ext1,CRS("+proj=longlat +datum=WGS84"))
occ_points <- occ_points[!is.na(sp::over(occ_points, sp::geometry(ext1))), ] 

#plot the extent and all retrieved data
plot(ext1)
plot(occ_points, add=T)

#Basis of record, as defined in our BasisOfRecord enum here https://gbif.github.io/gbif-api/apidocs/org/gbif/api/vocabulary/BasisOfRecord.html Acceptable values are:
#FOSSIL_SPECIMEN An occurrence record describing a fossilized specimen.
#HUMAN_OBSERVATION An occurrence record describing an observation made by one or more people.
#LITERATURE An occurrence record based on literature alone.
#LIVING_SPECIMEN An occurrence record describing a living specimen, e.g.
#MACHINE_OBSERVATION An occurrence record describing an observation made by a machine.
#OBSERVATION An occurrence record describing an observation.
#PRESERVED_SPECIMEN An occurrence record describing a preserved specimen.
#UNKNOWN Unknown basis for the record.
occ<-occ_search(taxonKey=key, geometry=c(bbox(ext1)), year="1000,2021", fields="all", basisOfRecord = "PRESERVED_SPECIMEN",hasCoordinate = T, hasGeospatialIssue = F,limit=100)
occ$data$basisOfRecord

#counting the number of observations based on different parameters see: https://www.rdocumentation.org/packages/rgbif/versions/3.3.0/topics/occ_count
occ_count(taxonKey=key, country="SE",basisOfRecord = "HUMAN_OBSERVATION", georeferenced = TRUE)

#by counting how many observations there are in total we can set a start parameter and retrieve the oldest 500 observations:
occ<-occ_search(taxonKey=key, country = "SE", fields=c('name','latitude','longitude','year'), basisOfRecord = "HUMAN_OBSERVATION",hasCoordinate = T, hasGeospatialIssue = F,
                limit=500,
                start = as.numeric(occ_count(taxonKey=key, country="SE",basisOfRecord = "HUMAN_OBSERVATION", georeferenced = TRUE)-500))

occ
nrow(occ$data)
occ$data$year
min(na.exclude(occ$data$year))

#exemplary workaround for large datasets:
i<-1
while(is.null(occ$data$year)){
  occ<-occ_search(taxonKey=key, country = "SE", fields="all", basisOfRecord = "HUMAN_OBSERVATION",hasCoordinate = T, hasGeospatialIssue = F,
                  limit=500,
                  start = as.numeric(occ_count(taxonKey=key, country="SE",basisOfRecord = "HUMAN_OBSERVATION", georeferenced = TRUE)-(500*i)))
  print(i)
  i<-i+1
}


occ
nrow(occ$data)
occ$data$year
min(na.exclude(occ$data$year))
#for other databases checkout: https://docs.ropensci.org/spocc/ 
  
  
  