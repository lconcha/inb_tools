function remaining_D_percent = calc_drop_percent_D(lfit_DTheory,percent_temp)


remaining_D_percent = exp((lfit_DTheory(1) .* percent_temp) + lfit_DTheory(2)) - 100;