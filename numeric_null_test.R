
library(R.matlab)
library(dplyr)
library(purrr)

filename = "800hTestDrive_fast.mat"

#container make

temp_list = readMat(filename)
glimpse(temp_list)

#all timestamp possibilites
fp_df = data.frame(0:1102200)
names(fp_df) = "ID_count"
fp_df = mutate(fp_df, time_id = 0 + ID_count * 0.01)

fp_df = mutate(fp_df, temp_col = as.numeric("NA"))

fp_i = 1

for(row in 1:length(temp_list[["A5.Sekunde....................................................."]][,1]))
{
  while(abs(fp_df$time_id[fp_i] - temp_list[["A5.Sekunde....................................................."]][row, 1]) > 0.005)
  {
    fp_i = fp_i + 1
  }
  fp_df$temp_col[fp_i] = temp_list[["A5.Sekunde....................................................."]][row, 2]
}