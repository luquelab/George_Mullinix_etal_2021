library(rpart)

custom_tree = function(data, response, observation_vars, depth, selected){
  vars = observation_vars[depth]
  str_formula = paste(response,'~',paste(vars, collapse=" + "), sep=" ")
  fourmula = as.formula(str_formula)
  my_tree = rpart(formula=fourmula,
                  data=data[selected,],
                  control=rpart.control(minsplit=2,
                                        minbucket=1,
                                        cp=0,
                                        maxdepth=1))
  split_val = my_tree$splits[4]
  gte_ix = which(data[[vars]][selected] >= split_val)
  lt_ix = which(data[[vars]][selected] < split_val)
  gte = selected[gte_ix]
  lt = selected[lt_ix]
  gte = list(ix=gte,
             response_mean=mean(data[[response]][gte]),
             variable_mean=mean(data[[vars]][gte]))
  lt = list(ix=lt,
            response_mean=mean(data[[response]][lt]),
            variable_mean=mean(data[[vars]][lt]))
  out_tree = list(split=split_val, gte=gte, lt=lt, vars=vars)

  # recurse if need be
  if(depth<length(observation_vars)){
    gte_child = custom_tree(data, response, observation_vars, depth+1, gte$ix)
    lt_child = custom_tree(data, response, observation_vars, depth+1, lt$ix)
    out_tree[["gte_child"]] = gte_child
    out_tree[["lt_child"]] = lt_child
  }

  return(out_tree)
}

print_tree = function(input_tree, depth, response, name){
  start_str_format = sprintf("%%%ds",5*depth)
  start = sprintf(start_str_format, "")
  strout = start
  start = sprintf("%s   |--", start)
  strout = sprintf("%s- %s:\n", strout, name)
  strout = sprintf("%s%s split: %f\n", strout, start, input_tree$split)
  strout = sprintf("%s%s < %s: var_mean=%f, %s_mean=%f, count=%d\n",
                   strout,
                   start,
                   input_tree$var,
                   input_tree$lt$variable_mean,
                   response,
                   input_tree$lt$response_mean,
                   length(input_tree$lt$ix))
  strout = sprintf("%s%s >= %s: var_mean=%f, %s_mean=%f, count=%d\n",
                   strout,
                   start,
                   input_tree$var,
                   input_tree$gte$variable_mean,
                   response,
                   input_tree$gte$response_mean,
                   length(input_tree$gte$ix))

  if("gte_child" %in% names(input_tree)){
    strout = sprintf("%s%s",
                     strout,
                     print_tree(input_tree[["gte_child"]],
                                depth+1,
                                response,
                                sprintf(">= %s", input_tree$var)))
  }
  if("lt_child" %in% names(input_tree)){
    strout = sprintf("%s%s",
                     strout,
                     print_tree(input_tree[["lt_child"]],
                                depth+1,
                                response,
                                sprintf("< %s", input_tree$var)))
  }
  return(strout)
}