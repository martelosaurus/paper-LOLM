library(data.table) 
library(ggplot2) 
library(lfe)

# estimator--------------------------------------------------------------------#
estimator=function(dummies,duration.breaks,application,X) {
	#
	#	Parameters
	#	----------
	#	dummies : vector (of strings)
	#		Dummies to project out
	#	duration.breaks : vector
	# 		x
	#	application : string
	#		Name of application (e.g. "venture capital")
	#	X : data.table
	#		Data 
	#
	#	Notes
	#	-----
	# 	This function saves a plot of each of three different estimations and of
	# 	a simple histogram. The three estimations are as follows:
	#		Model 1: GAM of log holding period returns on duration
	#		Model 2:
	#		Model 3:

    if (application=="venture_capital") {
        smpar = 1.
        X=subset(X,duration>.25)
    } else {
        smpar = 10
    }

    title=gsub("_"," ",application,fixed=TRUE)

    # factorize the dummies
	X[,paste(dummies):=lapply(.SD[,dummies,with=FALSE],factor)]	

    # truncate the sample
    X=subset(X,duration>0)
    X=subset(X,duration%between%range(duration.breaks))

    # MODEL 1: RAW ------------------------------------------------------------#
    ga=gam(logret ~ s(duration,sp=smpar),data=X) 
    pdf(paste(application,"_rawrets.pdf",sep=""),height=4.5,width=5.5)
    par(mar=c(5.1, 4.1, 2.1, 2.1))
    plot(ga,
		se=1.65,
		lwd=2,
		xlab='Length of Ownership (Years)',
        ylab="Log Return",
		rug=FALSE)
    dev.off()

    # MODEL 2: ROTATED --------------------------------------------------------#
    fm = lm(logret~duration,data=X)
    X[,logret_rot:=fm$residuals]
    ga=gam(logret_rot ~ s(duration,sp=smpar),data=X) 
    pdf(paste(application,"_rotrets.pdf",sep=""),height=4.5,width=5.5)
    par(mar=c(5.1, 4.1, 2.1, 2.1))
    plot(ga,
		se=1.65,
		lwd=2,
		xlab='Length of Ownership (Years)',
       	ylab="Adjusted Log Return",
		rug=FALSE)
    dev.off()
    
    # MODEL 3: RESIDUALS-------------------------------------------------------#
    modstr=paste("logret~-1|",ifelse(length(dummies)==0,"0",paste(dummies,collapse="+")))
    modfor=as.formula(modstr)
    fm.r=felm(modfor,data=X)
    if (application=="housing") {
        fm.r=felm(logret~-1|T.buy.yq+t.buy.yq,data=X)
    }
    X[,logret.res:=fm.r$residuals]
    ga=gam(logret.res~s(duration,sp=smpar),data=X)
    pdf(paste(application,"_resrets.pdf",sep=""),height=4.5,5.5)
    par(mar=c(5.1, 4.1, 2.1, 2.1))
    plot(ga,
		se=1.65,
		lwd=2,
		xlab='Length of Ownership (Years)',
        ylab="Adjusted Log Return",
		rug=FALSE)
    dev.off()

    # HISTOGRAM ---------------------------------------------------------------#
    pdf(paste(application,"_hist.pdf",sep=""),height=4.5,width=5.5)
    par(mar=c(5.1, 4.1, 2.1, 2.1))
    hist(X[,duration],breaks=duration.breaks,xlab="Length of Ownership (Years)",main="")
    box()
    dev.off() 
}
