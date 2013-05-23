# read FEMA NFHL shapefiles and write out only flood zone risk classification data

library(rgdal) # for reading and editing shapefiles
library(foreign)
# library(maptools) # for reading and editing shapefiles
# library(PBSmapping)

# function to change FEMA flood zone descriptor names to concise ones
# high risk (A and V = 100)
# moderate risk (B and SHX = 200)
# low risk (C and X = 400)
# unknown risk (D = 400)
FnRenameFloodZones <- function(x) {
  if (x %in% c("A", 
               "AE", 
               paste0("A", c(1:30)), 
               "AH", 
               "AO", 
               "AR", 
               "A99", 
               "V", 
               "VE", 
               paste0("V", c(1:30)),
               "1 PCT ANNUAL CHANCE FLOOD HAZARD CONTAINED IN CHANNEL",
               "1 PCT FUTURE CONDITIONS",
               "OPEN WATER")) {
    return ("100")
    
  } else if (x %in% c("B", 
                      "SHX")) {
    return ("200")
    
  } else if (x %in% c("C", 
                      "X", 
                      "0.2 PCT ANNUAL CHANCE FLOOD HAZARD",
                      "0.2 PCT ANNUAL CHANCE FLOOD HAZARD CONTAINED IN CHANNEL",
                      "0.2 PCT CHA", 
                      "X PROTECTED BY LEVEE")) {
    return ("300")
    
  } else if (x %in% c("D", 
                      "AREA NOT INCLUDED")) {
    return ("400")
    
  } else {
    stop("check! unknown flood zone!")
  }
}

#USA FIPS (Federal Information Processing Standard) codes
fips <- list('AK'='02', 'AL'='01', 'AR'='05', 'AS'='60', 'AZ'='04', 
             'CA'='06', 'CO'='08', 'CT'='09', 'DC'='11', 'DE'='10', 
             'FL'='12', 'GA'='13', 'GU'='66', 'HI'='15', 'IA'='19', 
             'ID'='16', 'IL'='17', 'IN'='18', 'KS'='20', 'KY'='21', 
             'LA'='22', 'MA'='25', 'MD'='24', 'ME'='23', 'MI'='26', 
             'MN'='27', 'MO'='29', 'MS'='28', 'MT'='30', 'NC'='37', 
             'ND'='38', 'NE'='31', 'NH'='33', 'NJ'='34', 'NM'='35', 
             'NV'='32', 'NY'='36', 'OH'='39', 'OK'='40', 'OR'='41', 
             'PA'='42', 'PR'='72', 'RI'='44', 'SC'='45', 'SD'='46', 
             'TN'='47', 'TX'='48', 'UT'='49', 'VA'='51', 'VI'='78', 
             'VT'='50', 'WA'='53', 'WI'='55', 'WV'='54', 'WY'='56')

# process data
dataPath <- "../FEMA NFHL/"
# GA (10), NY (32), NC (33), TX (43) issues 
# for (eachDir in c(44:50)) {
for (eachDir in c(32)) {
  # name of the folder
  dirName <- list.dirs(paste0(dataPath, "/raw/", eachDir, "-55"))[2]
  # extract fips code
  stateFips <- rev(unlist(strsplit(dirName, "/")))[1]
  stateFips <- (unlist(strsplit(stateFips, "_")))[1]
  stateFips <- names(fips[which(fips == stateFips)])

  cat(eachDir, stateFips, "\n")
  
  # read shapefile data
  inputShp <- readOGR(dirName, "S_FLD_HAZ_AR")
#   inputShp <- readShapePoly(paste0(dirName, "/S_FLD_HAZ_AR"))
#     inputShp <- importShapefile(paste0(dirName, "/S_FLD_HAZ_AR"))
  
  inputDbf <- read.dbf("../FEMA NFHL//raw/32-55//36_NFHL_20090818//S_FLD_HAZ_AR.dbf", as.is=TRUE)
  inputDbf$FLD_ZONE <- sapply(inputDbf$FLD_ZONE, FnRenameFloodZones)
  
  
  
  # rename flood zones
#   levels(as.factor(inputShp$FLD_ZONE))
  inputShp$FLD_ZONE <- sapply(inputShp$FLD_ZONE, FnRenameFloodZones)
  # write output
  writeOGR(inputShp, paste0(dataPath, "/formatted"), stateFips, 
           driver = "ESRI Shapefile", overwrite_layer = TRUE)
}
