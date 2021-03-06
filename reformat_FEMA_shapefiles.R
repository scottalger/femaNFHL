# read FEMA NFHL data and reclassify/rename the flood zone data

library(foreign)

# function to change FEMA flood zone descriptor names to concise ones
# high risk (A and V = 1)
# moderate risk (B and SHX = 4)
# low risk (C and X = 7)
# unknown risk (D = 9)
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
    return ("1")
    
  } else if (x %in% c("B", 
                      "SHX",
                      "0.2 PCT ANNUAL CHANCE FLOOD HAZARD",
                      "0.2 PCT ANNUAL CHANCE FLOOD HAZARD CONTAINED IN CHANNEL",
                      "0.2 PCT CHA")) {
    return ("4")
    
  } else if (x %in% c("C", 
                      "X", 
                      "X PROTECTED BY LEVEE")) {
    return ("7")
    
  } else if (x %in% c("D", 
                      "AREA NOT INCLUDED",
                      NA)) {
    return ("9")
    
  } else {
    stop(paste(x, "check! unknown flood zone!"))
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

#-------------------------------------------------------------------------------
# process data
inDataPath  <- "FEMA NFHL/raw_v1/" # original data
outDataPath <- "FEMA NFHL/formatted/" # processed data

dataDirs <- list.dirs(inDataPath)
dataDirs <- dataDirs[grep("_NFHL_", dataDirs)]

for (eachDir in dataDirs) {
  
  # extract fips code
  stateFips <- rev(unlist(strsplit(eachDir, "/")))[1]
  stateFips <- (unlist(strsplit(stateFips, "_")))[1]
  
  # for lower 48 + DC + AK + HI
  if (as.numeric(stateFips) <= 56) {
    stateFips <- names(fips[which(fips == stateFips)])
  
    cat(eachDir, stateFips, "\n")
    
    # copy all the relevant files 
    dataFiles <- list.files(eachDir)[grep("FLD_HAZ_AR", list.files(eachDir))]
    for (eachFile in dataFiles) {
      fileExtn <- unlist(strsplit(eachFile, "[.]"))[2] # file extension
      file.copy(paste0(eachDir, "/", eachFile), 
                paste0(outDataPath, stateFips, ".", fileExtn),
                overwrite = TRUE)
    }
    
    # read data from the dbf (newly created copy)
    inputDbf <- read.dbf(paste0(outDataPath, stateFips, ".dbf"), as.is=TRUE)
                         
    # rename flood zones
    #   levels(factor(inputDbf$FLD_ZONE, exclude = NULL))
    # inputDbf$FLD_ZONE <- sapply(inputDbf$FLD_ZONE, FnRenameFloodZones)
    inputDbf$SCORE <- sapply(inputDbf$FLD_ZONE, FnRenameFloodZones)
    
    # write output
    write.dbf(inputDbf, paste0(outDataPath, stateFips, ".dbf"), max_nchar = 500)
  }
}
