
# Version: 03-Nov-2021

#############################################----- Start PART 1 ----#############################################
library("neuralnet")
library(NeuralNetTools)
library(utils)
library(ggplot2)


# Compute severl Neural networks for the same structure (31.01.2023)

compute_NN_classification <- function(pdata = df_relevant3, target = "train",
                                              perr_fct = "ce",
                                              pact_fct = "logistic",
                                              palg = "rprop+",
                                              pthres = 0.01,
                                              pstepmax = 2e+05,
                                              fight_discrimination=FALSE,
                                              phid = 3,
                                              ptrain_itt=20,
                                              pseed = 0
)
{
  #Extract Regression formula
  lm_model_variables <- names(pdata)
  # Determine Dependet variable
  lm_formula1 <-
    as.formula(paste(
      target,
      paste(lm_model_variables[lm_model_variables != target], collapse =
              " + "),
      sep = " ~ "
    ))
  
  #Init Output

  nnchoice_scaled <- normalize(pdata)
    
    if(fight_discrimination)
    {
      classes = levels(nnchoice_scaled[,target])
      target1 = nnchoice_scaled_train[nnchoice_scaled_train[,target]==classes[1],]
      target2 = nnchoice_scaled_train[nnchoice_scaled_train[,target]==classes[2],]
      target3 = nnchoice_scaled_train[nnchoice_scaled_train[,target]==classes[3],]
      maxnrow <- max(nrow(target1),nrow(target2),nrow(target3))
      nnchoice_scaled_train <- rbind(target1,target2,target3)
      if(nrow(target1)<maxnrow/2){    nnchoice_scaled_train <- rbind(nnchoice_scaled_train,target1)}
      if(nrow(target2)<maxnrow/2){    nnchoice_scaled_train <- rbind(nnchoice_scaled_train,target2)}
      if(nrow(target3)<maxnrow/2){    nnchoice_scaled_train <- rbind(nnchoice_scaled_train,target3)}
    }
    
    old_model<-NULL
    for(mitt in 1:ptrain_itt)
    { 
      set.seed(8188 + mitt + pseed)
      faulty_model=FALSE
      # Calibration
      model<-tryCatch(neuralnet(
        formula = lm_formula1,
        data = nnchoice_scaled,
        hidden = phid,
        stepmax = pstepmax,
        threshold = pthres,
        algorithm = palg,
        err.fct = perr_fct,
        act.fct = pact_fct,
        linear.output = FALSE,
        lifesign = "full",
        lifesign.step=5e+4
      ), warning = function(cond){faulty_model = TRUE}, error = function(cond){test_nnchoice_model = TRUE})
      if(typeof(model)=="logical")
      {
        faulty_model=TRUE
      }
      if(!faulty_model)
      {
        if(is.null(old_model))
        {old_model<-model}
        else
        {
          if (old_model$result.matrix[1,1] > model$result.matrix[1,1])
          {
            old_model <- model
          }
        }
      }
    }
    return(old_model)
  }


compute_mutiple_NN_classification <- function(pdata = df_relevant3, target = "train",
                                              perr_fct = "ce",
                                              pact_fct = "logistic",
                                              palg = "rprop+",
                                              pthres = 0.01,
                                              pstepmax = 2e+05,
                                              fight_discrimination=FALSE,
                                              phid = 3,
                                              pdata_itt=4 ,
                                              ptrain_itt=5
)
{
  #Extract Regression formula
  lm_model_variables <- names(pdata)
  # Determine Dependet variable
  lm_formula1 <-
    as.formula(paste(
      target,
      paste(lm_model_variables[lm_model_variables != target], collapse =
              " + "),
      sep = " ~ "
    ))
  
  #Init Output
  nnchoice_all_results <- vector(mode = "numeric", 5)
  
  for(ditt in 1:pdata_itt)
  {
    nnchoice_scaled <- normalize(pdata)
    set.seed(8188 + ditt)
    sample <-
      sample.int(
        n = nrow(nnchoice_scaled),
        size = round(0.8 * nrow(nnchoice_scaled)),
        replace = F
      )
    nnchoice_scaled_test  <- nnchoice_scaled[-sample, ]
    nnchoice_scaled_train <- nnchoice_scaled[sample, ]
    
    
    if(fight_discrimination)
    {
      classes = levels(nnchoice_scaled[,target])
      target1 = nnchoice_scaled_train[nnchoice_scaled_train[,target]==classes[1],]
      target2 = nnchoice_scaled_train[nnchoice_scaled_train[,target]==classes[2],]
      target3 = nnchoice_scaled_train[nnchoice_scaled_train[,target]==classes[3],]
      maxnrow <- max(nrow(target1),nrow(target2),nrow(target3))
      nnchoice_scaled_train <- rbind(target1,target2,target3)
      if(nrow(target1)<maxnrow/2){    nnchoice_scaled_train <- rbind(nnchoice_scaled_train,target1)}
      if(nrow(target2)<maxnrow/2){    nnchoice_scaled_train <- rbind(nnchoice_scaled_train,target2)}
      if(nrow(target3)<maxnrow/2){    nnchoice_scaled_train <- rbind(nnchoice_scaled_train,target3)}
    }
    
    for(mitt in 1:ptrain_itt)
    { 
      set.seed(8188 + ditt + mitt)
      faulty_model=FALSE
      # Calibration
      model<-tryCatch(neuralnet(
        formula = lm_formula1,
        data = nnchoice_scaled_train,
        hidden = phid,
        stepmax = pstepmax,
        threshold = pthres,
        algorithm = palg,
        err.fct = perr_fct,
        act.fct = pact_fct,
        linear.output = FALSE,
        lifesign = "full",
        lifesign.step=5e+4
      ), warning = function(cond){faulty_model = TRUE}, error = function(cond){test_nnchoice_model = TRUE})
      if(typeof(model)=="logical")
      {
        faulty_model=TRUE
      }
      if(!faulty_model)
      {
        train_predict <- predict(model, nnchoice_scaled_train)
        train_max <- apply(train_predict, 1, which.max)
        train_class <- sort(model$model.list$response)[train_max]
        
        train_tab <- data.frame(computed=train_class, real=nnchoice_scaled_train$train)   
        error_train<- mean(train_tab[,1]!=train_tab[,2])     
        
        test_predict <- predict(model, nnchoice_scaled_test)
        test_max <- apply(test_predict, 1, which.max)
        test_class <- sort(model$model.list$response)[test_max]
        
        test_tab <- data.frame(computed=test_class, real=nnchoice_scaled_test$train)
        error_test<- mean(test_tab[,1]!=test_tab[,2])     
        
        nnchoice_all_results<-data.frame(rbind(nnchoice_all_results,c(phid,ditt,mitt,error_train,error_test)))
      }
    }
  }
  colnames(nnchoice_all_results)<-c("numHidden","dataItt","netItt","train","test")
  return(nnchoice_all_results[2:nrow(nnchoice_all_results),])
}



# Computes the activation function values for the hidden neurons 
compute_hidden_neurons_activities_classification <- function(dataset, best_neural_network)
{
  mymodel <- best_neural_network
  applied_model <- neuralnet::compute(mymodel, dataset)
  #Extract hidden neurons
  hidden_neurons <- applied_model$neurons[[2]]
  hidden_neurons <- hidden_neurons[,-1]
  colnames(hidden_neurons) <- paste0(rep("hidden_", length(hidden_neurons[1,])), 1:length(hidden_neurons[1,]))
  
  # Weight hidden neurons bei their synapsis weight for the output neuron
  weights_output <- mymodel$weights[[1]][[2]]
  weights_output <- weights_output[-1,]
  hidden_weighted <- c()
  for(j in 1:ncol(weights_output)){
    weights_result <- hidden_neurons %*% diag(weights_output[,j])
    colnames(weights_result) <- paste0(rep(paste0("output_",j,"_hidden_"),length(weights_output[,j])), 1:length(weights_output[,j]))                             
    hidden_weighted <- cbind(hidden_weighted,weights_result)
  }
  
  output_neurons <- applied_model$net.result
  colnames(output_neurons)<-sort(mymodel$model.list$response)
  df_hidden <- cbind(dataset,hidden_neurons, hidden_weighted, output_neurons)
  return(df_hidden)
}


#### Extracts the regression formula from a dataset
determine_regression_formula <- function(dataset, target = "Y")
{
  lm_formula1 <-
    as.formula(paste(
      target,
      paste(colnames(dataset)[colnames(dataset) != target], collapse =
              " + "),
      sep = " ~ "
    ))
  return(lm_formula1)
}


#### Transform Data Base to numerics, where not defined as factgors
conditionalCast <- function(x)
{
  factors <- Filter(is.factor,x)
  not_factors <- Filter(Negate(is.factor),x)
  not_factors_num <- apply(not_factors,2,as.numeric)
  result <- cbind(factors, not_factors_num)
  return(result)
}

#### Print weights of neural network
show_best_weights <- function(best_neural_network){
  mymodel <- best_neural_network
  weights <- list(input= mymodel$weights[[1]][[1]], hidden= mymodel$weights[[1]][[2]])
  return(weights)
}

#### Normalizes the Dataset
normalize <- function(df){
  factors <- Filter(is.factor,df)
  not_factors <- Filter(Negate(is.factor),df)
  
  nnchoice_maxs <- apply(not_factors, 2, max)
  nnchoice_mins <- apply(not_factors, 2, min)
  nnchoice_scaled <-
    as.data.frame(
      scale(
        not_factors,
        center = nnchoice_mins,
        scale = nnchoice_maxs - nnchoice_mins
      )
    )
  nnchoice_result <- cbind(factors,nnchoice_scaled)
  return(nnchoice_result)
}


lin <- function(x){return(x)}

###########################

compute_best_NN_Classification <- function(df, target, activation="tanh", low = 2, high = 10, repititions=10, verbose=FALSE, fight_discrimination=TRUE, onlyTest = TRUE, onlyResults=FALSE, thres=0.05, self_seed=100){
  lm_model_variables <- names(df)
  # Determine Dependet variable
  lm_formula1 <-
    as.formula(paste(
      target,
      paste(lm_model_variables[lm_model_variables != target], collapse =
              " + "),
      sep = " ~ "
    ))
  if(activation == "lin"){activation=lin}
  nnchoice_scaled <- normalize(df)
  nnchoice_range_first = low:high # Neurons in First layer
  #nnchoice_range_second = 1:1 # Neurons in Second layer
  nnchoice_range_itteration = 1:10 # Number of Samples for determing the best structure
  
  #Create Dataframe with 5 columns
  nnchoice_all_results <- vector(mode = "numeric", 3)
  
  if(onlyTest)
  {
    for (num_first in nnchoice_range_first) {
      #   for (num_second in nnchoice_range_second) {
      nnchoice_itteration_results_train <-1
      nnchoice_itteration_results_test <-1
      for (itteration in nnchoice_range_itteration)
      {
        # Split Datasets in Training and Test
        ##############################
        set.seed(8188 + itteration)
        sample <-
          sample.int(
            n = nrow(nnchoice_scaled),
            size = round(0.8 * nrow(nnchoice_scaled)),
            replace = F
          )
        nnchoice_scaled_train <- nnchoice_scaled[sample, ]
        
        if(fight_discrimination)
        {
          target1 = nnchoice_scaled_train[nnchoice_scaled_train[,target]==0,]
          target2 = nnchoice_scaled_train[nnchoice_scaled_train[,target]==1,]
          target3 = nnchoice_scaled_train[nnchoice_scaled_train[,target]==2,]
          nnchoice_scaled_train <- rbind(target1,target2,target3,target3)
        }
        
        nnchoice_scaled_test  <- nnchoice_scaled[-sample, ]
        
        
        #Train the model based on training Dataset
        ##############################
        test_model=TRUE
        while(test_model==TRUE){
          test_model=FALSE
          model = tryCatch(neuralnet(
            formula = lm_formula1,
            data = nnchoice_scaled_train,
            hidden = c(num_first),
            threshold = thres,
            act.fct = activation,
          ), warning = function(cond){test_model = TRUE}, error = function(cond){test_nnchoice_model = TRUE})
          if(typeof(model)=="logical")
          {
            if(!verbose)
            {
              
              message(paste0("Failed Itteration ", Sys.time()))
            }
            test_model=TRUE
          }
        }
        
        train_predict <- predict(model, nnchoice_scaled_train)
        print(train_predict[1:10,])
        train_max <- apply(train_predict, 1, which.max)
        train_tab <- cbind(train_max, nnchoice_scaled_train[,target])   
        print(train_tab[1:10,])
      
        error_train<- mean(train_tab[,1]!=train_tab[,2])     
        #Compute Model Results for Test Dataset
        
        test_predict <- predict(model, nnchoice_scaled_test)
        test_max <-  apply(test_predict, 1, which.max)
        test_tab <- cbind(test_max, nnchoice_scaled_test[,target])                   
        error_test<- mean(test_tab[,1]!=test_tab[,2])    
        
        #Append result for current Itteration
        nnchoice_all_results <- rbind(nnchoice_all_results,c(low, itteration, error_train, error_test))
        
        if(!verbose)
        {
          message(paste0("Itteration ",(num_first-low)*5+itteration," of ", (high-low+1)*5, ",", Sys.time()))
        }
      }
      
      # Mean over all Iterations and Save to nn_choice_all_results

      
      
      #}
    }
    
    # Give Readable Column Names
    colnames(nnchoice_all_results) = c(
      "Neurons_First_Layer",
      "Itteration",
      "Result_Training_Dataset",
      "Result_Test_Dataset"
    )
    
    nnchoice_all_results <- as.data.frame(nnchoice_all_results)
    #Drop first line, which is empty
  }
  
  test_nnchoice_model= TRUE
  set.seed(8188 + self_seed)
  nnchoice_model = NULL
  
  if(!verbose)
  {
    message(paste0("Starting Computation of Model"))
  }
  
  if(fight_discrimination)
  {
    target1 = nnchoice_scaled[nnchoice_scaled[,target]==0,]
    target2 = nnchoice_scaled[nnchoice_scaled[,target]==1,]
    target3 = nnchoice_scaled[nnchoice_scaled[,target]==2,]
    nnchoice_scaled <- rbind(target1,target2,target3,target3)
  }
  
  num_hidden <- low
  
  if(onlyResults)
  {
    
    while(test_nnchoice_model == TRUE){
      if(!verbose)
      {
        message(paste0("Itteration " , Sys.time()))
      }
      test_nnchoice_model = FALSE
      nnchoice_model = 
        tryCatch(
        neuralnet(
        formula = lm_formula1,
        data = nnchoice_scaled,
        hidden = c(high),
        threshold = thres,
        rep = repititions,
        act.fct = activation
        
        )
      , warning = function(cond){test_nnchoice_model = TRUE}, error = function(cond){test_nnchoice_model = TRUE})
      if(typeof(nnchoice_model)=="logical")
      {
        test_nnchoice_model=TRUE
      }
    }
  }
  
  result <- list(table=nnchoice_all_results, model=nnchoice_model)
  return(result)
}
######################### Plots






