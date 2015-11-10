#Title: Draw fitting curve
#Auther: Naoto Imamachi
#ver: 1.0.0
#Date: 2015-10-08

###Draw_fitting_curve_function###
BridgeRSimpleDraw <- function(filename="BridgeR_4_Normalized_expression_dataset.txt", group, hour, ComparisonFile, CutoffRelExp = 0.1, CutoffDataPoint = 3, InforColumn = 4, OutputDir = "BridgeR_simple_fig"){
    ###Make_stored_directory###
    ComparisonFile_name = paste(ComparisonFile,collapse="_")
    output_dir_name <- paste(OutputDir,ComparisonFile_name,sep="_")
    dir.create(output_dir_name)
    
    ###Prepare_file_infor###
    time_points <- length(hour)
    group_number <- length(group)
    input_file <- fread(filename, header=T)
    comp_file_number <- NULL
    for(a in 1:length(ComparisonFile)){
        comp_file_number <- append(comp_file_number, which(group == ComparisonFile[a]))
    }
    
    #setwd(output_dir_name)
    
    ###Draw_fitting_curve###
    gene_number <- length(input_file[[1]])
    for(x in 1:gene_number){
        data <- as.vector(as.matrix(input_file[x,]))
        
        #Save_fig
        gene_name <- as.character(data[2])
        file_name <- sprintf("%1$s.png",gene_name)
        file_name <- paste(output_dir_name,"/",file_name,sep="")
        png(filename=file_name,width = 640, height = 640)
        
        #Prepare_ggplot2
        p.fitting <- ggplot()
        
        flg <- 0
        fig_color <- NULL
        for(a in comp_file_number){
            if(flg == 0){
                fig_color <- "black"
            }else{
                fig_color <- "red"
            }
            infor_st <- 1 + (a - 1)*(time_points + InforColumn)
            infor_ed <- (InforColumn)*a + (a - 1)*(time_points)
            exp_st <- infor_ed + 1
            exp_ed <- infor_ed + time_points

            #gene_infor <- data[infor_st:infor_ed]
            exp <- as.numeric(data[exp_st:exp_ed])
            time_point_exp_original <- data.frame(hour,exp)
            
            p.fitting <- p.fitting + layer(data=time_point_exp_original, 
                                           mapping=aes(x=hour, y=exp), 
                                           geom="point",
                                           size=4,
                                           shape=19,
                                           colour=fig_color)
            
            time_point_exp <- time_point_exp_original[time_point_exp_original$exp >= CutoffRelExp, ] #>=0.1
            data_point <- length(time_point_exp$exp)
            
            if(!is.null(time_point_exp)){
                if(data_point >= CutoffDataPoint){ #>=3
                    model <- lm(log(time_point_exp$exp) ~ time_point_exp$hour - 1)
                    fig_data <- data.frame(hour=time_point_exp$hour)
                    predicted <- as.numeric(as.vector(as.matrix(predict(model, fig_data))))
                    fig_data$exp <- exp(as.vector(as.matrix(predicted)))
                    
                    p.fitting <- p.fitting + layer(data=fig_data,
                                                   mapping=(aes(x=hour, y=exp)),
                                                   geom="line",
                                                   size=1.2,
                                                   colour=fig_color)
                }
            }
            flg <- 1
        }
        p.fitting <- p.fitting + ggtitle(gene_name)
        p.fitting <- p.fitting + xlab("Time")
        p.fitting <- p.fitting + ylab("Relative RPKM (Time0 = 1)")
        p.fitting <- p.fitting + xlim(0,12)
        ybreaks <- seq(0,10,0.1)[2:101]
        p.fitting <- p.fitting + scale_y_log10(breaks=ybreaks,labels=ybreaks)
        plot(p.fitting)
        
        dev.off() #close_fig
        plot.new()
    }
}

#####################################################
BridgeRDrawFittingCurve <- function(filename="BridgeR_4_Normalized_expression_dataset.txt", group, hour, ComparisonFile, CutoffRelExp = 0.1, CutoffDataPoint = 3, InforColumn = 4, OutputDir = "BridgeR_fig", OutputFile = "BridgeR_4_HalfLife_Pvalue.txt"){
    ###Import_library###
    #library(data.table)
    #library(ggplot2)
    
    ###Make_stored_directory###
    ComparisonFile_name = paste(ComparisonFile,collapse="_")
    output_dir_name <- paste(OutputDir,ComparisonFile_name,sep="_")
    dir.create(output_dir_name)
    
    ###Prepare_file_infor###
    time_points <- length(hour)
    group_number <- length(group)
    input_file <- fread(filename, header=T)
    comp_file_number <- NULL
    for(a in 1:length(ComparisonFile)){
        comp_file_number <- append(comp_file_number, which(group == ComparisonFile[a]))
    }
    output_file <- OutputFile
    
    #setwd(output_dir_name)
    
    ###print_header###
    cat("",file=output_file)
    hour_label <- NULL
    for(a in comp_file_number){
        if(!is.null(hour_label)){
            cat("\t", file=output_file, append=T)
        }
        hour_label <- NULL
        for(x in hour){
            hour_label <- append(hour_label, paste("T", x, "_", a, sep=""))
        }
        infor_st <- 1 + (a - 1)*(time_points + InforColumn)
        infor_ed <- (InforColumn)*a + (a - 1)*time_points
        infor <- colnames(input_file)[infor_st:infor_ed]
        cat(infor,hour_label, sep="\t", file=output_file, append=T)
        cat("\t", sep="", file=output_file, append=T)
        cat("Model","Decay_rate_coef","coef_error","coef_p-value","R2","Adjusted_R2","Residual_standard_error","half_life","SD_ori","half_exp_minus","half_exp_plus","half_life_SD", sep="\t", file=output_file, append=T)
    }
    cat("\t", sep="", file=output_file, append=T)
    cat("p_value(Welch Modified Two-Sample t-Test)","\n", sep="\t", file=output_file, append=T)
    
    ###Draw_fitting_curve###
    gene_number <- length(input_file[[1]])
    for(x in 1:gene_number){
        data <- as.vector(as.matrix(input_file[x,]))
        
        #Save_fig
        gene_name <- as.character(data[2])
        file_name <- sprintf("%1$s.png",gene_name)
        file_name <- paste(output_dir_name,"/",file_name,sep="")
        png(filename=file_name,width = 640, height = 640)
        
        #Prepare_ggplot2
        p.fitting <- ggplot()

        flg <- 0
        fig_color <- NULL
        N_for_p <- NULL
        SD_for_p <- NULL
        X_for_p <- NULL
        flg_for_p <- 0
        for(a in comp_file_number){
            if(flg == 0){
                fig_color <- "black"
            }else{
                fig_color <- "red"
                cat("\t", sep="", file=output_file, append=T)
            }
            infor_st <- 1 + (a - 1)*(time_points + InforColumn)
            infor_ed <- (InforColumn)*a + (a - 1)*time_points
            exp_st <- infor_ed + 1
            exp_ed <- infor_ed + time_points
            
            gene_infor <- data[infor_st:infor_ed]
            cat(gene_infor, sep="\t", file=output_file, append=T)
            cat("\t", file=output_file, append=T)
            exp <- as.numeric(data[exp_st:exp_ed])
            cat(exp, sep="\t", file=output_file, append=T)
            cat("\t", file=output_file, append=T)
            #hour <- c(0,1,2,4,8,12) ###TEST###
            #exp <- c(1,0.8350178,0.7806458,0.6386572,0.3946119,0.2603135) #
            ##exp <- c(1,0.9637603,1.131551,1.025119,1.246695,1.437431) #
            #gene_name <- "test" #
            #fig_color <- "black" #
            #CutoffRelExp <- 0.1 #
            #CutoffDataPoint <- 3 #
            time_point_exp_original <- data.frame(hour,exp)
            
            #p.fitting <- ggplot() #
            p.fitting <- p.fitting + layer(data=time_point_exp_original, 
                                           mapping=aes(x=hour, y=exp), 
                                           geom="point",
                                           size=4,
                                           shape=19,
                                           colour=fig_color)

            time_point_exp <- time_point_exp_original[time_point_exp_original$exp >= CutoffRelExp, ] #>=0.1
            data_point <- length(time_point_exp$exp)
            
            if(!is.null(time_point_exp)){
                if(data_point >= CutoffDataPoint){ #>=3
                    model <- lm(log(time_point_exp$exp) ~ time_point_exp$hour - 1)
                    model_summary <- summary(model)
                    coef <- -model_summary$coefficients[1]
                    coef_error <- model_summary$coefficients[2]
                    coef_p <- model_summary$coefficients[4]
                    r_squared <- model_summary$r.squared
                    adj_r_squared <- model_summary$adj.r.squared
                    residual_standard_err <- model_summary$sigma
                    half_life <- log(2)/coef
                    #if(coef < 0 || half_life >= 24){
                    #    half_life <- 24
                    #}
                    if(coef < 0){
                        half_life <- Inf
                    }
                    cat("Exponential_Decay_Model",coef,coef_error,coef_p,r_squared,adj_r_squared,residual_standard_err,half_life, sep="\t", file=output_file, append=T)

                    half_life_exp_lm <- exp(log(0.5))
                    
                    xmin <- min(hour[1])
                    xmax <- max(hour[length(hour)])
                    
                    predicted2 <- data.frame(hour=time_point_exp$hour)
                    predicted2_ribbon <- data.frame(hour=time_point_exp$hour)

                    pred_conf <- predict(model, predicted2, interval="prediction",level=0.95)
                    
                    pred_conf2_SE <- predict(model, predicted2, se.fit=T)
                    
                    Fit <- pred_conf2_SE$fit
                    df <- pred_conf2_SE$df
                    SE_fit <- pred_conf2_SE$se.fit
                    Residual_fit <- pred_conf2_SE$residual.scale
                    
                    Space_minus <- function(Fit,SE_fit){
                        Fit-sqrt(SE_fit^2+Residual_fit^2)*qt(0.950,df)
                    }
                    Space_plus <- function(Fit,SE_fit){
                        Fit+sqrt(SE_fit^2+Residual_fit^2)*qt(0.950,df)
                    }
                    SE_test <- function(Fit,SE_fit){
                        sqrt(SE_fit^2+Residual_fit^2)
                    }
                    test_minus <- Space_minus(Fit,SE_fit)
                    test_plus <- Space_plus(Fit,SE_fit)
                    test_SE <- SE_test(Fit,SE_fit)
                    
                    SE_table <- data.frame(hour=time_point_exp$hour,exp=SE_fit)
                    SE_model <- lm((SE_table$exp) ~ SE_table$hour - 1)
                    SE_model_coef <- (summary(SE_model))$coefficients[1]
                    SE_half_life <- SE_model_coef*half_life

                    SE_fitting_curve <- sqrt(SE_half_life^2 + Residual_fit^2)
                    SD_fitting_curve <- SE_fitting_curve * sqrt(data_point-1)
                    
                    half_life_exp_lm_minus <- exp(log(0.5)-SD_fitting_curve)
                    half_life_exp_lm_plus <- exp(log(0.5)+SD_fitting_curve)
                    half_life_plus <- -log(half_life_exp_lm_minus)/coef
                    half_life_minus <- -log(half_life_exp_lm_plus)/coef
                    SD_for_test <- half_life_plus - half_life
                    SD_for_test <- half_life - half_life_minus
                    
                    N_for_p <- append(N_for_p,data_point)
                    SD_for_p <- append(SD_for_p, SD_for_test)
                    X_for_p <- append(X_for_p, half_life)
                    
                    cat("\t", sep="\t", file=output_file, append=T)
                    cat(SD_fitting_curve,half_life_exp_lm_minus,half_life_exp_lm_plus,SD_for_test, sep="\t", file=output_file, append=T)
                    
                    #model1_pred <- function(x)
                    #{
                    #    mRNA_exp <- (x * hour)
                    #}
                    #SE_data <- data.frame(hour=hour,exp=model1_pred(SE_model_coef))
                    
                    #pred_conf <- predict(model, predicted2, interval="confidence",level=0.95)
                    predicted2$exp <- exp(as.vector(as.matrix(pred_conf[,1])))
                    predicted2_ribbon$exp_minus <- exp(as.vector(as.matrix(pred_conf[,2])))
                    predicted2_ribbon$exp_plus <- exp(as.vector(as.matrix(pred_conf[,3])))

                    p.fitting <- p.fitting + layer(data=predicted2,
                                                   mapping=(aes(x=hour, y=exp)),
                                                   geom="line",
                                                   size=1.2,
                                                   colour=fig_color)
                    p.fitting <- p.fitting + layer(data=predicted2_ribbon,
                                                   mapping=aes(x=hour,ymin=exp_minus,ymax=exp_plus),
                                                   geom="ribbon",
                                                   alpha=0.1,
                                                   fill=fig_color)
                    p.fitting <- p.fitting + ggtitle(gene_name)
                    p.fitting <- p.fitting + xlab("Time")
                    p.fitting <- p.fitting + ylab("Relative RPKM (Time0 = 1)")
                    p.fitting <- p.fitting + xlim(0,12)
                    ybreaks <- seq(0,10,0.1)[2:101]
                    p.fitting <- p.fitting + scale_y_log10(breaks=ybreaks,labels=ybreaks)
                    plot(p.fitting)
                }else{
                    cat("few_data","NA","NA","NA","NA","NA","NA","NA","NA","NA","NA","NA", sep="\t", file=output_file, append=T)
                    flg_for_p <- 1
                }
            }else{  ###TEST###
                cat("low_expresion","NA","NA","NA","NA","NA","NA","NA","NA","NA","NA","NA", sep="\t", file=output_file, append=T)
                flg_for_p <- 1
            }
            flg = 1
        }
        t_test <- "NA"
        p_value <- "NA"
        if(flg_for_p != 1){
            t_test <- tsum.test(mean.x=X_for_p[1], s.x=SD_for_p[1], n.x=N_for_p[1],
                                mean.y=X_for_p[2], s.y=SD_for_p[2], n.y=N_for_p[2])
            p_value <- t_test$p.value
        }
        cat("\t", sep="\t", file=output_file, append=T)
        cat(p_value,"\n", sep="\t", file=output_file, append=T)
        dev.off() #close_fig
        plot.new()
    }
}

#####################################################
BridgeR3ModelDraw <- function(filename="BridgeR_5B_HalfLife_calculation_3model.txt", group, hour, ComparisonFile, InforColumn = 4, OutputDir = "BridgeR_3model_fig"){
    ###Make_stored_directory###
    ComparisonFile_name = paste(ComparisonFile,collapse="_")
    output_dir_name <- paste(OutputDir,ComparisonFile_name,sep="_")
    dir.create(output_dir_name)
    
    ###Prepare_file_infor###
    time_points <- length(hour)
    group_number <- length(group)
    input_file <- fread(filename, header=T)
    comp_file_number <- NULL
    for(a in 1:length(ComparisonFile)){
        comp_file_number <- append(comp_file_number, which(group == ComparisonFile[a]))
    }
    
    #setwd(output_dir_name)
    
    ###Draw_fitting_curve###
    gene_number <- length(input_file[[1]])
    for(x in 1:gene_number){
        data <- as.vector(as.matrix(input_file[x,]))
        
        model_index1 <- (InforColumn)*comp_file_number[1] + (comp_file_number[1] - 1)*(time_points + 23) + 21
        model_index2 <- (InforColumn)*comp_file_number[2] + (comp_file_number[2] - 1)*(time_points + 23) + 21
        model_1 <- data[model_index1]
        model_2 <- data[model_index2]
        
        if(is.na(model_1)){
        }else if(is.na(model_2)){
        }else if(model_1 == "no_good_model" || model_2 == "no_good_model"){
        }else{
            #Save_fig
            gene_name <- as.character(data[2])
            file_name <- sprintf("%1$s.png",gene_name)
            file_name <- paste(output_dir_name,"/",file_name,sep="")
            png(filename=file_name,width = 640, height = 640)
            
            #Prepare_ggplot2
            p.fitting <- ggplot()
            
            flg <- 0
            fig_color <- NULL
            curve_color_number <- c("curve_1","curve_2")
            
            for(a in comp_file_number){
                if(flg == 0){
                    fig_color <- "black"
                }else{
                    fig_color <- "red"
                }
                
                infor_st <- 1 + (a - 1)*(time_points + InforColumn + 23)
                infor_ed <- (InforColumn)*a + (a - 1)*(time_points + 23)
                exp_st <- infor_ed + 1
                exp_ed <- infor_ed + time_points
                
                #gene_infor <- data[infor_st:infor_ed]
                exp <- as.numeric(data[exp_st:exp_ed])
                time_point_exp_original <- data.frame(hour,exp)
                
                p.fitting <- p.fitting + layer(data=time_point_exp_original, 
                                               mapping=aes(x=hour, y=exp), 
                                               geom="point",
                                               size=4,
                                               shape=19,
                                               colour=fig_color)
                
                #Parameter
                a_1_index <- exp_ed + 4
                a_2_index <- exp_ed + 10
                b_2_index <- exp_ed + 11
                a_3_index <- exp_ed + 16
                b_3_index <- exp_ed + 17
                c_3_index <- exp_ed + 18
                model_index <- exp_ed + 21
                model <- data[model_index]

                #model_curve
                if(flg == 0){
                    model_curve_1 <- NULL
                    a_1_1 <- as.numeric(data[a_1_index])
                    a_2_1 <- as.numeric(data[a_2_index])
                    b_2_1 <- as.numeric(data[b_2_index])
                    a_3_1 <- as.numeric(data[a_3_index])
                    b_3_1 <- as.numeric(data[b_3_index])
                    c_3_1 <- as.numeric(data[c_3_index])                    
                    if(model == "model1"){
                        model_curve_1 <- function(t){exp(-a_1_1 * t)}
                    }else if(model == "model2"){
                        model_curve_1 <- function(t){(1.0 - b_2_1) * exp(-a_2_1 * t) + b_2_1}
                    }else if(model == "model3"){
                        model_curve_1 <- function(t){(c_3_1) * exp(-a_3_1 * t) + (1.0 - c_3_1) * exp(-b_3_1 * t)}
                    }
                    p.fitting <- p.fitting + layer(geom="path",
                                                   stat="function",
                                                   fun=model_curve_1,
                                                   mapping=aes(color="model_curve_1"),
                                                   size=1.2)
                }else if(flg == 1){
                    model_curve_2 <- NULL
                    a_1_2 <- as.numeric(data[a_1_index])
                    a_2_2 <- as.numeric(data[a_2_index])
                    b_2_2 <- as.numeric(data[b_2_index])
                    a_3_2 <- as.numeric(data[a_3_index])
                    b_3_2 <- as.numeric(data[b_3_index])
                    c_3_2 <- as.numeric(data[c_3_index])
                    if(model == "model1"){
                        model_curve_2 <- function(t){exp(-a_1_2 * t)}
                    }else if(model == "model2"){
                        model_curve_2 <- function(t){(1.0 - b_2_2) * exp(-a_2_2 * t) + b_2_2}
                    }else if(model == "model3"){
                        model_curve_2 <- function(t){(c_3_2) * exp(-a_3_2 * t) + (1.0 - c_3_2) * exp(-b_3_2 * t)}
                    }
                    p.fitting <- p.fitting + layer(geom="path",
                                                   stat="function",
                                                   fun=model_curve_2,
                                                   mapping=aes(color="model_curve_2"),
                                                   size=1.2)
                }
                flg <- 1
            }
            p.fitting <- p.fitting + scale_colour_manual(name="Sample",
                                                         values=c("model_curve_1"="black","model_curve_2"="red"),
                                                         labels=ComparisonFile)
            p.fitting <- p.fitting + ggtitle(gene_name)
            p.fitting <- p.fitting + xlab("Time")
            p.fitting <- p.fitting + ylab("Relative RPKM (Time0 = 1)")
            p.fitting <- p.fitting + scale_x_continuous(limits = c(0,12))
            p.fitting <- p.fitting + scale_y_log10()
            plot(p.fitting)
            
            dev.off() #close_fig
            plot.new()
        }
    }
}
