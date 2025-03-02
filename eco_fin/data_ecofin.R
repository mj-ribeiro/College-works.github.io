#*********************************************************************************************
#                                     Data 
#**********************************************************************************************

setwd("D:/Git projects/college_works/eco_fin")


#------------- CMAX Function

# w e o tamanho da janela
# n e a quantidade de janelas
# s e o vetor que vou passar a funcao


CMAX = function(w, n, s){
  
  l = matrix(nrow=n,ncol = (w+1))
  max = matrix(nrow=n, ncol = 1)
  cmax = matrix(nrow=n, ncol = 1)
  
  for (j in 1:n){
    
    l[j, 1:(w+1)] = s[j:(w+j)]
    max[j] = max(l[j, 1:(w+1)])
    
    cmax[j] = l[j, (w+1)]/max(max[j])
  }
  return(cmax)
}



#### get first day

firstDayMonth=function(x)
{           
  x=as.Date(as.character(x))
  day = format(x,format="%d")
  monthYr = format(x,format="%Y-%m")
  y = tapply(day,monthYr, min)
  first=as.Date(paste(row.names(y),y,sep="-"))
  #as.factor(first)
  as.Date(first)
}




# Libraries

library(lubridate)
library(tseries)
library(timeSeries)
library(quantmod)
library(fGarch)
library(GetBCBData)

library(ipeadatar)
library(knitr);
library(tidyr);
library(dplyr);
library(DT);
library(magrittr)
library(data.table)




# Get data

ibov = getSymbols('^BVSP', src='yahoo', 
                  from= '1999-01-01', 
                  to = '2021-02-01',
                  periodicity = "monthly",    # IBOV mensal
                  auto.assign = F)[,4]


colnames(ibov) = 'ibov'
ibov = ibov[is.na(ibov)==F]



# VIX

vix = getSymbols('^VIX', src='yahoo', 
                 periodicity = "monthly",
                 from= '2000-01-01', 
                 to = '2021-01-01',
                 auto.assign = F)[,4]

colnames(vix) = 'vix'

rvix = diff(log(vix))
colnames(rvix) =  'rvix'


# Oil price


oil = getSymbols('CL=F', src='yahoo', 
                 periodicity = "monthly",
                 from= '2000-01-01', 
                 to = '2021-01-01',
                 auto.assign = F)[,4]

colnames(oil) = 'oil'



# Gold price


gold = getSymbols('GC=F', src='yahoo', 
                 periodicity = "monthly",
                 from= '2000-01-01', 
                 to = '2021-01-01',
                 auto.assign = F)[,4]

colnames(gold) = 'gold'




# 11768 - indice da taxa de cambio real (INPC)
library(GetBCBData)

cb = gbcbd_get_series(11768, first.date= '2000-01-01', last.date = '2021-01-01',  
                      format.data = "long", be.quiet = FALSE)[ ,1:2]

data = cb$ref.date
cb[,1]=NULL
cb = xts(cb, order.by = data)

rownames(cb) = data    # colocar a data como indice

colnames(cb) = 'cb'


# cdi


cdi = gbcbd_get_series(4391, first.date= '2000-01-01', last.date = '2021-01-01',  
                       format.data = "long", be.quiet = FALSE)[ ,1:2]

data = cdi$ref.date
cdi[,1]= NULL
cdi = xts(cdi, order.by = data)



rownames(cdi) = data    # colocar a data como indice

colnames(cdi) = 'cdi'


## EMBI


embi_search = as.data.frame(search_series(terms = c('EMBI'), fields = c("name"),language = c("br")))
embi_search %<>% dplyr::slice(1:500L)
datatable(embi_search)


embi = ipeadata(c('JPM366_EMBI366'))[,2:3]
colnames(embi) = c('date', 'embi')



k= firstDayMonth(embi$date)
k = as.Date(k)



k = as.data.frame(k)

colnames(k) = 'date'



setDT(embi)
setDT(k)


embi = embi[k, on = c('date')]


embi$date = as.Date(embi$date)

mday(embi$date) = 1   # transformar os dias do vetor de datas k em 1 (lubridate)



embi = xts(embi, order.by = embi$date)
embi = embi[,-1]



# returns



ret = diff(log(ibov))


ret = ret[is.na(ret)==F]
colnames(ret) = 'ret'



####  State space in excess of return



rexc = read.csv('rexc.csv', header = T, sep=';' )


colnames(rexc) = c('date', 'rexc')

rexc$date = as.Date(rexc$date)


a = rexc$date  


rexc = xts(rexc$rexc, order.by = a)




#------ Using CMAX function


cm2 = CMAX(12,(length(ibov)-12), ibov )

var1 = quantile(cm2, 0.05)
var2 = quantile(cm2, 0.1)



lim = mean(cm2)-2*sd(cm2)


cm2[cm2<lim]
sum((cm2<lim)*1)   # count 


# get the data of ibov

data = index(ibov)
data1 = data[13:length(ibov)]



# transform cmax in xts object

cmts = xts(x=cm2, order.by = data1) 




#----- Create Dummy

# var1

crise = matrix(nrow = length(cmts))

crise = ifelse(cm2<var1, 1, 0)

pos0 = which(crise==1)   # pegar a posicao onde crise== 1
pos0


for(i in 2:length(pos0)){
  crise[(pos0[i]-12):pos0[i]] = 1
}


pos1 = which(crise==1)   # pegar a posicao onde crise== 1
pos1


table(crise)
prop.table(table(crise))



crise = xts(crise, order.by = data1)
colnames(crise) = 'crise'


# var2


crise2 = matrix(nrow = length(cmts))

crise2 = ifelse(cm2<var2, 1, 0)

pos2 = which(crise2==1)   # pegar a posicao onde crise== 1
pos2


for(i in 1:length(pos2)){
  a = (pos2[i]-12)
  if(a<0){
    a = 1
  }
  crise2[a:pos2[i]] = 1
}


pos3 = which(crise2==1)   # pegar a posicao onde crise== 1
pos3




#---- create data frame

data = index(oil)
data = data[-c(1, 2)]


View(data)

crise = xts(crise[-seq(1,11)], order.by = data)
crise2 = xts(crise2[-seq(1,11)], order.by = data)



rvix = rvix[data]
cb = cb[data]
vix = vix[data]
data = index(cb)
oil =oil[data]
vix = vix[data]
crise = crise[data] 
crise2 = crise2[data] 
cdi = cdi[data]
ret = ret[data]
gold = gold[data]
embi = embi[data]
cmts = cmts[data]
rexc = rexc[data]

# transform data in data frame

df = data.frame(ret, vix, cb, crise, cdi, embi,
                crise2, oil, gold, rvix, cmts, rexc)


### save in rds file

saveRDS(df, 'df.rds')



