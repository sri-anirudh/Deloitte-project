

library(dplyr)
#load data
getwd()
setwd("/Users/chenhuiguo/Desktop/MSU Project Purchase to Pay/Project Data")


# 1.1 load data
EKPO=read.csv("EKPO.csv",colClasses=c(EBELN="character",EBELP="character"),header=TRUE,sep=",")
EKKO=read.csv("EKKO.csv",colClasses=c(EBELN="character"),header=TRUE,sep=",")
EKBE=read.csv("EKBE.csv",colClasses=c(EBELN="character",EBELP="character"),header=TRUE,sep=",")
EBAN=read.csv("EBAN.csv",colClasses=c(EBELN="character",EBELP="character"),header=TRUE,sep=",")
Activity=read.csv("Activity.csv",colClasses=c(X_CASE_KEY="character",EBELN="character",EBELP="character"),header=TRUE,sep=",")


# 1.2. cleanup data
View(Activity)
str(Activity)
Activity=Activity[,!(colnames(Activity) %in% c("MANDT"))]
Activity=Activity%>%select(-starts_with("CHANGED"))

Activity$time=strptime(Activity$EVENTTIME,"%b %d %Y %I:%M %p")

Activity=Activity%>%arrange(EBELN,EBELP,time)%>%
            group_by(X_CASE_KEY,EBELN,EBELP)%>%
            mutate(create=if_else(ACTIVITY_EN=="Create Purchase Order Item",1,0),
                  receive=if_else(ACTIVITY_EN=="Record Goods Receipt",1,0),
                  changeconfirmeddeliverydate=if_else(ACTIVITY_EN=="Change Confirmed Delivery Date",1,0),
                  changecontract=if_else(ACTIVITY_EN=="Change Contract",1,0),
                  changecurrency=if_else(ACTIVITY_EN=="Change Currency",1,0),
                  changedeliveryindicator=if_else(ACTIVITY_EN=="Change Delivery Indicator",1,0),
                  changefinalinvoiceindicator=if_else(ACTIVITY_EN=="Change Final Invoice Indicator",1,0),
                  changeoutwarddeliveryindicator=if_else(ACTIVITY_EN=="Change Outward Delivery Indicator",1,0),
                  changeprice=if_else(ACTIVITY_EN=="Change Price",1,0),
                  changequantity=if_else(ACTIVITY_EN=="Change Quantity",1,0),
                  changerequesteddeliverydate=if_else(ACTIVITY_EN=="Change requested delivery date",1,0),
                  changestoragelocation=if_else(ACTIVITY_EN=="Change Storage Location",1,0))%>%
            mutate(receive=cumsum(receive)*receive) #use 1,2,3 to index the record goods receipt events

ActivitySummary=Activity%>%group_by(X_CASE_KEY,EBELN,EBELP)%>%
                   summarize(
                   #get the number of each type of change-item events 
                   changeconfirmeddeliverydate=sum(changeconfirmeddeliverydate), 
                   changecontract=sum(changecontract),
                   changecurrency=sum(changecurrency),
                   changedeliveryindicator=sum(changedeliveryindicator),
                   changefinalinvoiceindicator=sum(changefinalinvoiceindicator),
                   changeoutwarddeliveryindicator=sum(changeoutwarddeliveryindicator),
                   changeprice=sum(changeprice),
                   changequantity=sum(changequantity),
                   changerequesteddeliverydate=sum(changerequesteddeliverydate),
                   changestoragelocation=sum(changestoragelocation),
                   numdelivery=max(receive))

createTime=Activity%>%filter(create==1)%>%
      select(X_CASE_KEY,EBELN,EBELP,time)%>%
      rename(createtime=time)
#86402 cases with create purchase
dim(createTime)
  
firstReceiveTime=Activity%>%filter(receive==1)%>%
      select(X_CASE_KEY,EBELN,EBELP,time)%>%
      rename(firstreceivetime=time)
#76412 cases with first receive goods
dim(firstReceiveTime)

#get GD days with 2 decimal digits
options(scipen = 999)
data=createTime%>%inner_join(firstReceiveTime,by=c("X_CASE_KEY","EBELN","EBELP"))%>%
                  inner_join(ActivitySummary,by=c("X_CASE_KEY","EBELN","EBELP"))%>%
                  mutate(GDdays=round(100*as.numeric(difftime(firstreceivetime,createtime,units="days")))/100)

# clean EKPO table
EKPO=EKPO[,(colnames(EKPO) %in% c("NETPR","EBELP","EBELN","BUKRS",
                                  "MATNR","MATKL","LOEKZ","PSTYP","WERKS"))]
# clean EBAN table
EBAN=EBAN[,(colnames(EBAN) %in% c("EBELP","EBELN","ERNAM"))]
#remove duplicated records (some records are the same except the BADAT column)
EBAN=EBAN[!(duplicated(EBAN)),]


#join tables
data=data%>%left_join(EKPO,by=c("EBELP","EBELN"))%>%
            left_join(EBAN,by=c("EBELP","EBELN"))

# output GD data
write.table(data,"GData.csv",sep=",",row.names=FALSE,col.names=TRUE)


# 2.1.load and clean Payment data
BSEG=read.csv("BSEG.csv",colClasses=c(GJAHR="character",BELNR="character"),header=TRUE,sep=",")
BKPF=read.csv("BKPF.csv",colClasses=c(GJAHR="character",BELNR="character",RSEG_GJAHR="character",RSEG_BELNR="character"),header=TRUE,sep=",")
RBKP=read.csv("RBKP.csv",colClasses=c(GJAHR="character",BELNR="character"),header=TRUE,sep=",")
RSEG=read.csv("RSEG.csv",colClasses=c(GJAHR="character",BELNR="character",EBELN="character",EBELP="character"),header=TRUE,sep=",")

#remove duplicated columns, missing value columns, and useless column MANDT
BSEG=BSEG[,!(colnames(BSEG) %in% c("MANDT"))]
BKPF=BKPF[,!(colnames(BKPF) %in% c("MANDT","BUDAT","CPUDT","XBLNR","BLART","BLDAT"))]
RBKP=RBKP[,!(colnames(RBKP) %in% c("MANDT","BUDAT","CPUDT","BLDAT","ZFBDT","FDTAG",
                                   "REINDAT","VATDATE","ASSIGN_NEXT_DATE","ASSIGN_END_DATE"))]
RSEG=RSEG[,!(colnames(RSEG) %in% c("MANDT","RETDUEDT","BUZEI"))]

#there are some missing values for paytime, since not paid yet
BSEG$invoicetime=strptime(BSEG$BLDAT,"%b %d %Y %I:%M %p")
BSEG$paytime=strptime(BSEG$AUGDT,"%b %d %Y %I:%M %p")
BSEG$after=difftime(BSEG$paytime,BSEG$invoicetime,units="days")
BSEG$earlydays=round(100*(BSEG$ZBD1T-BSEG$after))/100
BSEG$isearly=if_else(BSEG$earlydays>0,1,0)

# 2.2.create the joined Payment-GD data
#it seems that there is a many-to-many relationship between (early payment) table BSEG and (good delivery) data we derived before
#RSEG table is the bridge between early payment data (PK is RSEG_GJAHR+RSEG_BELNR, not GJAHR+BELNR) and good delivery data (PK is EBELN+EBELP)
#Here, we rename the GJAHR and BELNR in RBKP and RSEG tables, so that the tables can be joined
RSEG=RSEG%>%rename(RSEG_GJAHR=GJAHR,RSEG_BELNR=BELNR)
RBKP=RBKP%>%rename(RSEG_GJAHR=GJAHR,RSEG_BELNR=BELNR)
#actually, we find that RBKP table is useless, we can join BKPB directly to RSEG
#RSEG data has duplicated records, so remove duplicated records
RSEG=RSEG[!duplicated(RSEG),]
join=BSEG%>%inner_join(BKPF,by=c("GJAHR","BELNR","BUKRS"))%>%
             select(-GJAHR,-BELNR)%>%
             inner_join(RSEG,by=c("RSEG_GJAHR","RSEG_BELNR"),multiple="all")

#get the combined data, then we need to aggregate it into RSEG_BELNR+RSEG_GJAHR level
#we can see that RSEG_BELNR+RSEG_GJAHR=RBKPKEY, so we can use RBKPKEY as the PK of the aggregate data
#we drop all the columns in table and only keep P Key and F Keys
join=join[,(colnames(join) %in% c("RBKPKEY","EBELN","EBELP"))]
combined=join%>%inner_join(data,by=c("EBELN","EBELP"))

#test relationship between payment and delivery data
#aggregate data at the payment level, we find 25.5% of payments have multiple items purchased
rs1=combined%>%group_by(RBKPKEY)%>%
  summarize(count=n())%>%
  arrange(desc(count))
mean(rs1$count>1)
#[1] 0.2552232
#aggregate data at the GD delivery data, we find 5.8% of purchases have multiple payments
rs2=combined%>%group_by(EBELN,EBELP)%>%
              summarize(count=n())%>%
              arrange(desc(count))
mean(rs2$count>1)
#[1] 0.05761424

# 2.3. make the Payment data
#though not perfect, we should treat payment-delivery as one-to-many relationship,
#and aggregate the joint data at the payment level, by aggregating the GD variables (mean, sum, first, or count)
#for each RBKPKEY, we find there is exactly one BUKRS, so use BUKRS as aggregate variable
aggregated=combined%>%group_by(RBKPKEY,BUKRS)%>%
                      arrange(RBKPKEY,createtime)%>%
                      summarize(numitems=n(),
                                mincreatetime=min(createtime),
                                minfirstreceivetime=min(firstreceivetime),
                                avgGDdays=mean(GDdays,na.rm=TRUE),
                                sumNETPR=sum(NETPR,na.rm=TRUE),
                                sumchangeconfirmeddeliverydate=sum(changeconfirmeddeliverydate), 
                                sumchangecontract=sum(changecontract),
                                sumchangecurrency=sum(changecurrency),
                                sumchangedeliveryindicator=sum(changedeliveryindicator),
                                sumchangefinalinvoiceindicator=sum(changefinalinvoiceindicator),
                                sumchangeoutwarddeliveryindicator=sum(changeoutwarddeliveryindicator),
                                sumchangeprice=sum(changeprice),
                                sumchangequantity=sum(changequantity),
                                sumchangerequesteddeliverydate=sum(changerequesteddeliverydate),
                                sumchangestoragelocation=sum(changestoragelocation),
                                dcountWERKS=n_distinct(WERKS),
                                dcountMATKL=n_distinct(MATKL),
                                dcountERNAM=n_distinct(ERNAM),
                                posPSTYP=if_else(sum(PSTYP)>0,1,0),
                                sumnumdelivery=sum(numdelivery))

#test distributions
table(aggregated$dcountMATKL)
table(aggregated$dcountWERKS)
table(aggregated$dcountERNAM)
table(aggregated$posPSTYP)
  
#join the aggregated data with the payment table (BSEG)
#for same payment records, we cannot find matched delivery data; maybe the product is not delivered yet
table=BSEG%>%inner_join(BKPF,by=c("GJAHR","BELNR","BUKRS"))%>%
       select(-GJAHR,-BELNR)%>%
       inner_join(aggregated,by=c("RBKPKEY","BUKRS"))
              

# output payment data
write.table(table,"PData.csv",sep=",",row.names=FALSE,col.names=TRUE)



