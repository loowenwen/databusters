* my directory
clear all
cd /Users/loowenwen/Desktop/Databusters

* capture open log files
capture log close
log using my_attempt, replace

********************************************************************************

* import quarterly_final csv file
import delimited "quarterly_final.csv", clear
save "quarterly_final.dta", replace
use quarterly_final.dta

** real gdp indicators
regress gdp real_consumption real_priv_investment government_expenditure exports imports
*** root mse = 37.527

** include real interest rate
regress gdp real_consumption real_priv_investment government_expenditure exports imports real_interest_rate
*** root mse = 36.171

** include financial indicators + consumer sentiment
regress gdp real_consumption real_priv_investment government_expenditure exports imports real_interest_rate vix sp500 umc_sentiment
*** root mse =  30.506
estat ic

* inspect data
describe 
summarize

* find correlation of all other variables to `gdp_change'
ds gdp, not
local varlist = r(varlist)
** `correlate`' command computes the Pearson correlation coefficients
** measures the strength and direction of a linear relationship between continuous variables, with values ranging from -1 to 1
foreach var of local varlist {
    correlate gdp `var'
}


********************************************************************************

* import quarterly_perc csv file
import delimited "quarterly_perc.csv", clear
save "quarterly_perc.dta", replace
use quarterly_perc.dta

** real gdp indicators
regress gdp_change consump_change invest_change govt_change exports_change imports_change
*** root mse = .10571

** include real interest rate
regress gdp_change consump_change invest_change govt_change exports_change imports_change real_int_change
*** root mse = .10553

** include consumer sentiment
regress gdp_change consump_change invest_change govt_change exports_change imports_change real_int_change umc_senti_change
*** root mse = .10559

** include financial indicators
regress gdp_change consump_change invest_change govt_change exports_change imports_change real_int_change vix_change sp500_change umc_senti_change
*** root mse = .1019
estat ic

** predict value for historical
predict gdp_forecast


********************************************************************************

* import quarterly_perc csv file
use quarterly_perc.dta, replace

* set time variable in stata
** convert the date column of string objects into date objects
gen date_var = date(date, "MDY")
gen quarter_date = qofd(date_var)
format quarter_date %tq
tsset quarter_date, quarterly

* arima model
dfuller gdp_change
** p = 0; stationary, so d = 0

corrgram gdp_change, lags(20)
** the PAC doesn't show a clear sharp cutoff at low lags, implying a lower value for p
** the AC remains small across most lags, with no strong peaks, suggesting a small q

arima gdp_change, ar(1) ma(1)
** prob > chi2 = 0.0009

arima gdp_change, ar(2) ma(1)
** prob > chi2 = 0.2147

arima gdp_change, ar(3) ma(1)
** prob > chi2 = 0.7641

arima gdp_change, ar(3) ma(2)
** prob > chi2 = 0.3670

** therefore, best model is arima gdp_change, ar(3) ma(1)
arima gdp_change, ar(3) ma(1)
estimates store arima_model  // store the results


********************************************************************************
