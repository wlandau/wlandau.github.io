lambda = array(runif(288, 30, 90), dim = c(2, 6, 6))

dimnames(lambda)[[1]] = paste("Diet",  as.roman(1:2))
dimnames(lambda)[[2]] = paste("Drug",  LETTERS[1:6])
dimnames(lambda)[[3]] = paste("Rep",  1:6)

a.array = apply(lambda, 1:3, function(x){rpois(50000,x)})

dimnames(a.array)[[1]] = paste("Gene",  1:50000)

str(a.array)
a.array[1:5,1:2,1:2,1]

print(object.size(a.array), units = "Mb")

library(reshape2)

a.data.frame = melt(a.array)
colnames(a.data.frame) = c("Gene", "Diet", "Drug", "Rep", "Expression_Level")

head(a.data.frame)

print(object.size(a.data.frame), units = "Mb")

library(ggplot2)

pl = ggplot(a.data.frame, aes(x = Expression_Level)) +
     geom_histogram(aes(fill = Diet), alpha = 0.5, position = "identity") +
     facet_grid(Drug~Rep) + xlab("Expression Level") + ylab("Frequency")

ggsave("2013-05-01-post.png", width = 8, height = 8)