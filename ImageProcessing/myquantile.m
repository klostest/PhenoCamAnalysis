function[x] = myquantile(data,qt)

data = data(isnan(data)<1);
x = quantile(data,qt);

end