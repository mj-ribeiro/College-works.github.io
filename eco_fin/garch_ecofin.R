#***********************************************************************************************
#                                     GARCH-Volatility
#***********************************************************************************************

setwd("D:/Git projects/Finance/Finance_R")


#--- Libraries


library(tseries)
library(timeSeries)
library(forecast)   # auto.arima
library(quantmod)
library(fGarch)
library(rugarch)

#---- Get data


ibov = getSymbols('^BVSP', src='yahoo', 
                  from= '1999-12-01', 
                  to = '2020-04-01',
                  #periodicity = "monthly",    # IBOV mensal
                  auto.assign = F)[,4]


#----- returns


ret = diff(log(ibov))
colnames(ret) = c('ret')

ret = ret[is.na(ret)==F]  # Drop na to work



#---- GARCH Model

spec1 = ugarchspec(variance.model=list(model="sGARCH", 
                    garchOrder=c(1,1)), 
                    mean.model=list(armaOrder=c(0,0), archm=T),
                   fixed.pars=list(mu=0), 
                   distribution.model="norm")


garch2 = ugarchfit(spec = spec1, data= ret)



garch2


ts.plot(sigma(garch2))


plot(ret**2)




#--- GARCH

spec2 = ugarchspec(variance.model=list(model="sGARCH", 
                                       garchOrder=c(1,1)), 
                   mean.model=list(armaOrder=c(0,0), include.mean=TRUE),
                   distribution.model="norm")




garch3 = ugarchfit(spec = spec2, data= ret)

garch3









windows()
for(i in 1:1000){
  hist(ret[1:(100+i)], breaks = 30, col = 'lightblue')
}


windows()
for(i in 1:(length(ret)-1)){
  plot(as.vector( ret[1:(1+i)]), col='blue')
}






library(vars)
x = rnorm(1000)
y = rnorm(1000)

vmat = as.matrix(cbind(y, x))

head(vmat)
tail(vmat)



vfit = VAR(vmat, p=2)



summary(vfit)


plot(irf(vfit))

vfit




library(xlsx)
write.xlsx(ret,"C:/Users/user/Documents/ret.xlsx")



curve(x^0.2, ylim = c(0, 1))
curve(x^0.4, ylim = c(0, 1), add=T)






