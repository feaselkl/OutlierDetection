#SourceData2017
install.packages("openxlsx")
library(openxlsx)
library(RODBC)

df <- read.xlsx("C:\\SourceCode\\OutlierDetection\\Data\\WakeCountyTransactionsFY2016.xlsx", sheet = 2, colNames = TRUE)
head(df)

conn <- odbcDriverConnect("driver={SQL Server};server=LOCALHOST;database=OutlierDetection;trusted_connection=true")
sqlSave(conn, df, tablename = "WakeCountyTransactionsFY2016")
