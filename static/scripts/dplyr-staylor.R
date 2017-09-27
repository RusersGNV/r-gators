#Uncomment these two lines to install the required packages
#install.packages(c('tidyverse','devtools'))
#devtools::install_github('weecology/portalr')
library(portalr)
library(tidyverse)


########################################################################
########################################################################
#The portalr package is made to deal specifically with this dataset.
#This function will download the most up to date data into the 
#current project working directory
portalr::download_observations(base_folder = '.')

########################################################################
########################################################################
# This is the raw rodent data. Each row is a single captured rodent in a 
# sampling period. Included is info about the time and location of sampling
# and information about the specific rodent
rodent_data = read.csv('PortalData/Rodents/Portal_rodent.csv')

#There are ~24 species or rodents seen at the site. In the raw data above
#species are only identified by a 2 letter code. This data.frame will associate
#the 2 letter code with the  full names as well as other info
species_info = read.csv('PortalData/Rodents/Portal_rodent_species.csv')

# This data is organized by periods. Period 1 is the first trapping session
# in 1977. The period is incrimented by 1 every month trapping is done. 
# Information about all the periods, such as dates and which of 24 plots were
# sampled, is in this data.frame
trapping_info = read.csv('PortalData/Rodents/Portal_rodent_trapping.csv')


# Filter out periods with sampling issues (those with negative period number),
# undefined species names, and non-rodent species. 
rodent_data = rodent_data %>%
  filter(period>0, !is.na(species), species!='')

# Filter out non-rodent species by combining info from the species table
rodent_data = rodent_data %>%
  left_join(species_info, by=c('species'='speciescode')) %>%
  filter(rodent==1)


########################################################################
########################################################################
#Summarize the rodent data into monthly counts of each species

#Get the counts of each rodent species by trapping period
period_counts = rodent_data %>%
  group_by(period, species) %>%
  summarise(num_rodents = n()) %>%
  ungroup() 

#Also add in the *total* amount of rodents caught, regardless of species
total_period_counts = rodent_data %>%
  group_by(period) %>%
  summarise(num_rodents = n()) %>%
  ungroup() %>%
  mutate(species='total')

period_counts = period_counts %>%
  bind_rows(total_period_counts)

###############################################################################
################################################################################
#Clean and compile the precipitaiton data into precip at different lags. 

weather_data = portalr::weather(level = 'Monthly', path='.')

#The weather data does not have period info in it, so it must be added
#by a join using the month and year.
period_months = trapping_info %>%
  group_by(period) %>%
  summarize(month = min(month), year=min(year)) %>%
  ungroup()

weather_data = weather_data %>%
  left_join(period_months, by=c('year','month')) %>%
  ungroup()

################################################################
################################################################
# This function will, for a given period  number, extract the  precipitation
# records from the prior months (default is 6)
get_prior_months_precip = function(num_months=6, period){
  # Within the weather data.frame, find the row that corrosponds to
  # the given period number. If it ends up being NA (meaning there is
  # no entry for this period number) then return NA without doing further work
  this_period_row_number = which(weather_data$period==period)
  if(is.na(this_period_row_number) | length(this_period_row_number)!=1 ){
    return(NA)
  }
  
  # Calculate the prior entries needed 
  starting_value = this_period_row_number - num_months
  ending_value   = this_period_row_number - 1
  prior_precip = weather_data[starting_value:ending_value,]
  
  # Fill in any missing precip values with the average from this
  # subset
  prior_precip$precipitation[is.na(prior_precip$precipitation)] = mean(prior_precip$precipitation, na.rm=T)
  
  # Return only the precip data with one other column of the prior period identifier
  prior_precip = select(prior_precip, precipitation)
  prior_precip$months_prior = paste0('months_prior_',num_months:1)
  
  return(prior_precip)
}
################################################################
################################################################
# Use a for loop to iterate over each period and retrieve the precipitation
# record of the prior 6 months using the above function

num_prior_months = 6

# Create an empty data.frame to hold this
prior_precip_values = data.frame()

for(this_period in unique(period_counts$period)){
  # Skip the first 30 or so periods where weather wasn't recorded
  if(this_period < 40){
    next
  }
  
  # Get this periods prior precip, and use spread to put each row into a column
  this_period_prior_precip = get_prior_months_precip(num_months = num_prior_months, period = this_period) %>%
    spread(months_prior, precipitation)
  
  this_period_prior_precip$period = this_period
  
  # Add this periods data to the data.frame with all the periods
  prior_precip_values = prior_precip_values %>%
    bind_rows(this_period_prior_precip)
  
}

###################################################################
###################################################################
# Add the information about the past 6 months precip into the monthly rodent count data
# Drop any rows where prior precip is missing from it not being recorded

period_counts = period_counts %>%
  left_join(prior_precip_values, by=c('period')) %>%
  filter(complete.cases(.))

#####################################################################
#####################################################################
# The data is now cleaned and ready to be put directly into a model
# using the period_counts data.frame

#####################################################################
#####################################################################

# For each species, run an linear model to find out which months in the past
# contribute the most to rodent abundance

#Create some empty data.frames which will hold the final results
model_info = data.frame()
coef_info = data.frame()

#Loop thru each species, adding results from models as we go
for(this_species in unique(period_counts$species)){
  this_species_data = period_counts %>%
    filter(species == this_species)
  
  species_model = lm(num_rodents ~ months_prior_1 + months_prior_2 + months_prior_3 + months_prior_4 + months_prior_5 + months_prior_6,
             data=this_species_data)
  
  #The broom packages summarize the model results into a dataframe
  #
  #broom::tidy() returns info about each coefficient, 1 per row
  species_coef_info = broom::tidy(species_model)
  #broom::glance() returns info about the entire  model, such as AIC, r^2, p.values, etc.
  species_model_info = broom::glance(species_model)
  
  species_coef_info$species = this_species
  species_model_info$species = this_species
  
  model_info = model_info %>%
    bind_rows(species_model_info) 
  coef_info = coef_info %>%
    bind_rows(species_coef_info)
  
}

####################################################################################
####################################################################################
#Some summary graphs. 

# First take out the intercept term from the models, which isn't relevant for our current
# analysis.
coef_info = coef_info %>%
  filter(term != '(Intercept)')


# For each species show the coefficient values for each month in the past
ggplot(coef_info, aes(x=term, y=estimate)) + 
  geom_bar(stat = 'identity') + 
  geom_errorbar(aes(ymin = estimate - std.error, ymax = estimate + std.error)) +
  geom_hline(yintercept = 0, color='red') +
  facet_wrap(~species, scales='free') + 
  theme(axis.text.x = element_text(size = 7, angle=80, hjust = 1))


# Many of the coefficients have their standard error estimates around 0, which means
# they aren't significant. Some are significant though. For example the species DO
# looks to be negatively correlated with the prior months precip, and OL positively 
# correlated with prior months 2-6. 
# 
# Some graphs have incomplete data. Such as the species OX, PX, and SX. Can you figure out why?
# 
# How else could the modeling aspect of this be improved?