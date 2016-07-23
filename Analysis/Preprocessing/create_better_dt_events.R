#creates better legible table from the comon event table in a form of 
create_better_dt_events = function(dt_events){
  df_phases = create_phases_table(dt_events)
  df_lever_feeder = create_level_feeder_table(dt_events)
  #type order start end
  df = rbind(df_phases, df_lever_feeder)
  return(df)
}

create_phases_table = function(dt_events){
  df_experiment = FindStartEnd(dt_events, "Experiment", c("ExperimentStarted","ExperimentEnded"))
  df_test = FindStartEnd(dt_events, "Test", c("TestPhaseStarted","TestPhaseEnded"))
  df_reward = FindStartEnd(dt_events, "Reward", c("RewardPhaseStarted","RewardPhaseEnded"))
  df_inter_trial = FindStartEnd(dt_events, "InterTrial", c("InterTrialStarted","InterTrialEnded"))
  df = rbind(df_experiment, df_test, df_reward, df_inter_trial)
  return(df)
}

create_level_feeder_table = function(dt_events){
  df_lever = FindStartEndLever(dt_events, "Lever", c("leverPressed","leverReleased"))
  df_feeder = FindStartEnd(dt_events, "Feeder", c("feederStarts","feederStops"))
  df = rbind(df_lever, df_feeder)
  return(df)
}