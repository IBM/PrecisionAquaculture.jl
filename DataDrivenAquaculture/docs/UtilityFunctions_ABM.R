## Utility functions connected to analysis of ABM data
library(RColorBrewer)
require(reshape2)
require(ggplot2)

bin_abm_data <- function(data_dir, month_avail, plot_contour = TRUE,
                         fname_stem = "abm_vertical_distribution.csv"){
  breaks <- seq(0,20)
  nday = 1
  nhour = 2
  year = "2019"
  for (month in month_avail){
    month_data <- NULL
    ave_depth <- NULL
    spr_depth <- NULL
    for (day in 1:nday){
      for (hour in 0:nhour){
        date_is_legitimate <- TRUE
        mm <- sprintf("%02d", match(month,month.abb))
        dd <- sprintf("%02d", day)
        hh <- sprintf("%02d", hour)
        file_datStr = paste(year,mm,dd, "_",hh,  sep="")
        datapath = paste(data_dir, month, "/", sep="")
        file.names <- dir(datapath, pattern =file_datStr)
        echo_range <- NULL
        print(cbind(day, nday, hour, nhour))
        if (length(file.names) != 0){ # no data returned for that hour
          for(i in 1:length(file.names)){
            filename <- paste(datapath, file.names[i], sep="")
            file <- read.table(paste(datapath, file.names[i], sep=""), header = TRUE, sep=",", stringsAsFactors=FALSE)
            echo_range <- cbind(echo_range, file$Echo.Range..m.)
            print(echo_range)
            tar_str <- file$Target.Strength..dB.
            datetime <- strptime(file_datStr, format="%Y%m%d_%H", tz = "Europe/Oslo")
          }
          ## We need to both bin and aggregate the echo_range data
          ## and using those build the echo strength matrix
          bins <- as.data.frame(table(cut(echo_range, breaks, include.lowest = T, right=FALSE)))
        } else{
          bins <- data.frame("Freq" = rep(NA, length(breaks)))
          ## Need to check if file is missing because date is invalid (don't update data)
          ## or because sensor is missing data for that hour (update with datestamp and NAs)
          d <- try( as.Date( file_datStr, format="%Y%m%d_%H" ) )
          if( class( d ) == "try-error" || is.na( d ) ) {
            print( "Not a legitimate date" )
            date_is_legitimate <- FALSE
          } else {
            bins <- data.frame("Freq" = rep(NA, length(breaks)))
            datetime <- strptime(file_datStr, format="%Y%m%d_%H", tz = "Europe/Oslo")
          }
        }
        ## Need to accomodate for missing data in an hour, set to NA
        if (date_is_legitimate){
          echo_range[echo_range > 20] <- NA
          ave_depth <- cbind(ave_depth, mean(echo_range, na.rm = T))
          spr_depth <- cbind(spr_depth, sd(echo_range, na.rm = T))
          
          month_data <- cbind(month_data, bins$Freq)
          colnames(month_data)[dim(month_data)[2]] <- as.numeric(datetime)    
        }
      }
    }
    month_data <- rbind(month_data, ave_depth,spr_depth) 
    month_cols <- t(month_data)
    colnames(month_cols) <-  cbind(rbind(sprintf(breaks[2:length(breaks)], fmt = "%2d")), "AveDept", "Spread")
    file_name <- paste(data_dir, fname_stem, month, ".csv", sep="")
    #filled.contour(time_range, seq(1,19,1), t(month_data))
    write.table(month_cols, file_name,
                col.names=FALSE, sep=",")
  }

  if (plot_contour)
    {
    time_range = as.POSIXct(as.numeric(colnames(month_data)),origin = "1970-01-01", tz = "Europe/Oslo")
    # normalize
    test = t(apply(month_cols, 1, function(x)(x-min(x))/(max(x)-min(x))))
    filled.contour(time_range, seq(1,19,1), test)
  }
  month_data
}


plot_vert_distr <- function(df){
  ggplot(df, aes( x = Timestamp, y = depth, z=Intensity)) +
    geom_tile( aes(fill = Intensity)) + 
    #  coord_equal() +
    geom_contour(color = "white", alpha = 0.05) + 
#    stat_contour(aes(fill=..level..), geom="polygon", binwidth=0.005) + 
 #   ggtitle("Vertical distribution of fish") +
    scale_fill_distiller(palette="Spectral", na.value="white") + 
    theme(panel.background = element_rect(fill = "white", colour = "black"),
          axis.text=element_text(size=20),
          axis.title = element_text(size = 30),
          plot.title = element_text(face = "bold", hjust = 0.5)) +
    labs(x = "", y = "Depth (m)") +
    geom_point(aes(x= Timestamp, y=ave_depth), size=1)
}

create_single_file <- function(month_avail, file_in, file_out){
  row_names <- c("Timestamp", sprintf(seq(1,20), fmt = "%02d"), "AverageDepth", "StandarDeviation")
  write.table(t(row_names), file_out, row.names = FALSE, col.names = FALSE, sep=',')
  for (month in month_avail){
    print(month)
    file_data <- paste(file_in, month,".csv", sep="")
    print(file_data)
    data <- read.table(file_data, sep=",", skip=1)
    time_range = as.POSIXct(as.numeric(data[,1]), origin = "1970-01-01", tz = "Europe/Oslo")
    depth_data <- data[,2:dim(data)[2]]
    depth_data[depth_data>15000] <- NA   # heuristics on noisy data
    indx <- which(depth_data[,21]>11)  ## if average depth > 11, heuristics on anomalous data
    print(indx)
    depth_data[indx,] <- NA
    dout <- cbind(time_range, depth_data)
    write.table(dout, file_out, append = TRUE, row.names = FALSE, col.names = FALSE, sep=',')
  }
  
}

# ++++++++++++++++++++++++++++
# flattenCorrMatrix
# ++++++++++++++++++++++++++++
# cormat : matrix of the correlation coefficients
# pmat : matrix of the correlation p-values
flattenCorrMatrix <- function(cormat, pmat) {
  ut <- upper.tri(cormat)
  data.frame(
    row = rownames(cormat)[row(cormat)[ut]],
    column = rownames(cormat)[col(cormat)[ut]],
    cor  =(cormat)[ut],
    p = pmat[ut]
  )
}

