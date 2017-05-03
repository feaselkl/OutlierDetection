# Outlier Detection with SQL and R
This is demo code for my Outlier Detection with SQL and R presentation.  In this repository, you will get a copy of each of the notebooks I use in the talk.  You can get more details about the talk, including slides and links to additional resources, at http://www.catallaxyservices.com/presentations/outlierdetection/.

## Setup
To run this, you will need the following:
1. SQL Server 2012 or later.  I built this talk against SQL Server 2016 and SQL Server 2017 CTP 2, but the syntax should work going back to 2012.
2. Jupyter Notebooks with the R kernel.  I have a blog post on setting this up at https://36chambers.wordpress.com/2016/05/24/til-installing-jupyter-on-windows/.

## Data Loading
There are two different ways of getting the data loaded:  you can manually load data or you can restore the backup in the DataLoad folder.

### Manual Load
There are three data sets which would need loaded into SQL Server:  Durham Crime 2017, Raleigh Incidents 2014, and Wake County Transactions FY 2016.  In the DataLoad folder, you will find step-by-step scripts and packages for each.  The Durham and Raleigh data sets require SQL Server Integration Services; the packages were built around SSIS 2016.  The Wake County data set requires R to be intalled.

### Restore A Backup
Instead of running the manual load, you can choose instead to restore the OutlierDetection.bak backup.  This backup was taken with SQL Server 2014 Developer Edition.  I recommend restoring to at least 2014 Developer, as I have not tested it against Standard or Express Edition.
